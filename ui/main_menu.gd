extends Control

## T8.01 — Menu chính: Chơi tiếp, Chọn màn, Cài đặt (Âm lượng + Pack ngôn ngữ), Thoát.
## Manager inject được để test headless (không đổi scene thật).

const SELECT_SCENE := "res://ui/level_select.tscn"

var manager: Node = null

@onready var _settings: Control = $SettingsPanel
@onready var _volume: HSlider = $SettingsPanel/SettingsBox/VolumeRow/VolumeSlider
@onready var _volume_val: Label = $SettingsPanel/SettingsBox/VolumeRow/VolumeValue
@onready var _console_tag: Label = $MenuBox/ConsoleTag
@onready var _play_btn: Button = $MenuBox/PlayBtn
@onready var _select_btn: Button = $MenuBox/SelectBtn
@onready var _settings_btn: Button = $MenuBox/SettingsBtn
@onready var _quit_btn: Button = $MenuBox/QuitBtn
@onready var _vol_label: Label = $SettingsPanel/SettingsBox/VolumeRow/VolumeLabel
@onready var _lang_label: Label = $SettingsPanel/SettingsBox/LangRow/LangLabel
@onready var _lang_btn: Button = $SettingsPanel/SettingsBox/LangRow/LangBtn
@onready var _controls_label: Label = $ControlsStrip/ControlsLabel


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	_settings.visible = false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null and _volume != null:
		var db := float(audio.get("volume_db"))
		_volume.value = db
		_refresh_volume_label(db)
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	_apply_locale()


func _exit_tree() -> void:
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: String) -> void:
	_apply_locale()


func _apply_locale() -> void:
	if _console_tag != null:
		_console_tag.text = LocalePack.tr_key("menu_console_tag")
	if _play_btn != null:
		_play_btn.text = LocalePack.tr_key("menu_play")
	if _select_btn != null:
		_select_btn.text = LocalePack.tr_key("menu_select")
	if _settings_btn != null:
		_settings_btn.text = LocalePack.tr_key("menu_settings")
	if _quit_btn != null:
		_quit_btn.text = LocalePack.tr_key("menu_quit")
	if _vol_label != null:
		_vol_label.text = LocalePack.tr_key("settings_volume")
	if _lang_label != null:
		_lang_label.text = LocalePack.tr_key("settings_language")
	if _lang_btn != null:
		_lang_btn.text = LocalePack.tr_key("lang_name")
	if _controls_label != null:
		_controls_label.text = LocalePack.tr_key("controls_hint")


func _play_index(mgr: Node) -> int:
	var count: int = int(mgr.call("level_count"))
	if count <= 0:
		return -1
	# Save cu co the mo khoa vuot so man hien co -> kep lai de khong bam chet.
	return clampi(int(mgr.get("unlocked")) - 1, 0, count - 1)


func _on_play_pressed() -> bool:
	AudioManager.play_sfx("click")
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	var idx: int = _play_index(mgr)
	if idx < 0:
		return false
	return bool(mgr.call("load_level", idx))


func _on_select_pressed() -> bool:
	AudioManager.play_sfx("click")
	return get_tree().change_scene_to_file(SELECT_SCENE) == OK


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	_settings.visible = not _settings.visible


func _on_lang_pressed() -> void:
	AudioManager.play_sfx("click")
	LocalePack.cycle_locale()


func _on_volume_changed(value: float) -> void:
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("set_volume", value)
	_refresh_volume_label(value)


func _refresh_volume_label(db: float) -> void:
	if _volume_val == null:
		return
	var pct := clampi(int(round(((db + 24.0) / 24.0) * 100.0)), 0, 100)
	_volume_val.text = "%d%%" % pct


func _on_quit_pressed() -> void:
	get_tree().quit()
