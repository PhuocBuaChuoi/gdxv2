extends Node

## T8.06 — SFX sinh bằng code (bleeps 8-bit), không cần file ngoài.
## Nhạc nền nhịp nhanh để sau (cần sequencer riêng) — API giữ chỗ: play_music().

const RATE := 22050

var volume_db: float = 0.0
var _sfx: Dictionary = {}


func _ready() -> void:
	_build_all()


func sfx_names() -> Array:
	return _sfx.keys()


func has_sfx(sfx_name: String) -> bool:
	return _sfx.has(sfx_name)


func play_sfx(sfx_name: String) -> bool:
	if not _sfx.has(sfx_name):
		return false
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[sfx_name]
	p.volume_db = volume_db
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()
	return true


func set_volume(db: float) -> void:
	volume_db = clampf(db, -24.0, 0.0)


func play_music() -> void:
	# TODO T8.06+: sequencer nhạc nền chiptune (hiện chỉ có SFX).
	pass


func _build_all() -> void:
	_sfx["click"] = _tone(1200.0, 1200.0, 0.05, 0.5)
	_sfx["jump"] = _tone(660.0, 990.0, 0.12, 0.5)
	_sfx["checkpoint"] = _tone_seq([523.25, 783.99], 0.1, 0.5)
	_sfx["death"] = _noise(0.3, 0.6)
	_sfx["portal"] = _tone(880.0, 220.0, 0.25, 0.5)
	_sfx["win"] = _tone_seq([523.25, 659.25, 783.99, 1046.5], 0.09, 0.5)


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
