extends Control

## T8.01 — Menu chính: Chơi tiếp (màn mở khóa cao nhất), Chọn màn, Cài đặt,
## Thoát. Manager inject được để test headless (không đổi scene thật).

const SELECT_SCENE := "res://ui/level_select.tscn"

var manager: Node = null

@onready var _settings: Control = $SettingsPanel
@onready var _volume: HSlider = $SettingsPanel/VolumeRow/VolumeSlider


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	_settings.visible = false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null and _volume != null:
		_volume.value = float(audio.get("volume_db"))


func _on_play_pressed() -> bool:
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	var idx: int = maxi(int(mgr.get("unlocked")) - 1, 0)
	return bool(mgr.call("load_level", idx))


func _on_select_pressed() -> bool:
	return get_tree().change_scene_to_file(SELECT_SCENE) == OK


func _on_settings_pressed() -> void:
	_settings.visible = not _settings.visible


func _on_volume_changed(value: float) -> void:
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("set_volume", value)


func _on_quit_pressed() -> void:
	get_tree().quit()
