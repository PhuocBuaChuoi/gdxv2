extends Node

## T8.06 — SFX sinh bằng code (bleeps 8-bit), không cần file ngoài.
## Nhạc nền nhịp nhanh để sau (cần sequencer riêng) — API giữ chỗ: play_music().

const RATE := 22050

var volume_db: float = 0.0
var _sfx: Dictionary = {}
var _music_stream: AudioStreamWAV = null
var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	_build_all()


func sfx_names() -> Array:
	return _sfx.keys()


func has_sfx(sfx_name: String) -> bool:
	return _sfx.has(sfx_name)


func play_sfx(sfx_name: String) -> bool:
	if not _sfx.has(sfx_name):
		return false
	# Headless (test/E2E) khong co audio driver that: playback chi bi AudioServer
	# giai phong sau 1 buffer mix, nen tao playback roi thoat ngay se leak.
	if DisplayServer.get_name() == "headless":
		return true
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[sfx_name]
	p.volume_db = volume_db
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
	return true


func set_volume(db: float) -> void:
	volume_db = clampf(db, -24.0, 0.0)


func _exit_tree() -> void:
	stop_music()
	# Dừng + giải phóng player đang phát trước khi thoát để AudioServer không
	# giữ playback/WAV lại (tránh "ObjectDB instances were leaked at exit").
	for child in get_children():
		if child is AudioStreamPlayer:
			var p := child as AudioStreamPlayer
			p.stop()
			p.stream = null
			p.free()
	_sfx.clear()


## T8.06 — nhạc nền chiptune tự sinh (không cần file ngoài). Track loop nên
## không dùng finished; headless trả về true ngay để tránh leak playback.
func play_music() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	if _music_stream == null:
		return false
	stop_music()
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_stream
	_music_player.volume_db = volume_db - 12.0
	add_child(_music_player)
	_music_player.play()
	return true


func stop_music() -> void:
	if _music_player == null:
		return
	_music_player.stop()
	_music_player.stream = null
	_music_player.free()
	_music_player = null


func has_music() -> bool:
	return _music_stream != null


func _build_all() -> void:
	_sfx["click"] = _tone(1200.0, 1200.0, 0.05, 0.5)
	_sfx["jump"] = _tone(660.0, 990.0, 0.12, 0.5)
	_sfx["checkpoint"] = _tone_seq([523.25, 783.99], 0.1, 0.5)
	_sfx["death"] = _noise(0.3, 0.6)
	_sfx["portal"] = _tone(880.0, 220.0, 0.25, 0.5)
	_sfx["win"] = _tone_seq([523.25, 659.25, 783.99, 1046.5], 0.09, 0.5)
	_sfx["door"] = _tone(320.0, 720.0, 0.16, 0.45)
	_music_stream = _chiptune_loop()


## 8 nốt bass + arpeggio, 140 BPM, đủ 2 giây rồi loop (T8.06).
func _chiptune_loop() -> AudioStreamWAV:
	var bpm := 140.0
	var beat := 60.0 / bpm
	var total := beat * 8.0
	var n := int(RATE * total)
	var data := PackedByteArray()
	data.resize(n)
	var bass := [55.0, 55.0, 73.42, 65.41, 55.0, 55.0, 82.41, 73.42]
	var arp := [220.0, 261.63, 329.63, 261.63, 220.0, 293.66, 329.63, 392.0]
	for i in range(n):
		var t := float(i) / RATE
		var step := int(t / beat) % 8
		var local_t := fmod(t, beat)
		var env := exp(-4.0 * local_t / beat)
		var wave := sin(TAU * bass[step] * t) * 0.28 + sin(TAU * arp[step] * t) * 0.16
		data[i] = int(127.5 + 127.0 * 0.45 * env * wave)
	var w := _wrap(data)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## Blip sine trượt tần số, envelope tắt dần.
func _tone(freq_from: float, freq_to: float, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var f := lerpf(freq_from, freq_to, t / dur)
		var env := exp(-3.0 * t / dur)
		data[i] = int(127.5 + 127.0 * vol * env * sin(TAU * f * t))
	return _wrap(data)


## Chuỗi nốt nối tiếp (checkpoint, win).
func _tone_seq(freqs: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	for f in freqs:
		var n := int(RATE * note_dur)
		var start := data.size()
		data.resize(start + n)
		for i in range(n):
			var t := float(i) / RATE
			var env := exp(-3.0 * t / note_dur)
			data[start + i] = int(127.5 + 127.0 * vol * env * sin(TAU * float(f) * t))
	return _wrap(data)


## Nổ nhiễu cho tiếng chết.
func _noise(dur: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n)
	for i in range(n):
		var t := float(i) / RATE
		var env := exp(-4.0 * t / dur)
		data[i] = int(127.5 + 127.0 * vol * env * (randf() * 2.0 - 1.0))
	return _wrap(data)


func _wrap(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
