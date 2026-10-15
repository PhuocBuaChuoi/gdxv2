extends Control

## T8.05 — Bảng tổng kết hoàn thành màn: thời gian, số chết, sao, Màn tiếp.
## 3 sao khi chết < 3 lần (0–2 → 3★, 3–5 → 2★, còn lại 1★).

const SELECT_SCENE := "res://ui/level_select.tscn"

var manager: Node = null

@onready var _time: Label = $PanelBox/TimeLabel
@onready var _deaths: Label = $PanelBox/DeathsLabel
@onready var _stars: Label = $PanelBox/StarsLabel


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	visible = false
	if not Events.level_completed.is_connected(_on_level_completed):
		Events.level_completed.connect(_on_level_completed)


func _exit_tree() -> void:
	if Events.level_completed.is_connected(_on_level_completed):
		Events.level_completed.disconnect(_on_level_completed)


func _on_level_completed(level_index: int, deaths: int, time_taken: float) -> void:
	var level := _find_level_root()
	if level != null and int(level.get("level_index")) != level_index:
		return
	show_result(time_taken, deaths)


func _find_level_root() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.name == "LevelRoot" or node.has_method("get_player_positions"):
			return node
		node = node.get_parent()
	return null


static func stars_for(death_count: int) -> int:
	if death_count < 3:
		return 3
	if death_count < 6:
		return 2
	return 1


static func fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%02d:%05.2f" % [total / 60, t - float(total / 60 * 60)]


func show_result(time_taken: float, death_count: int) -> int:
	var stars := stars_for(death_count)
	_time.text = "Thời gian: " + fmt_time(time_taken)
	_deaths.text = "Số lần chết: %d" % death_count
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	visible = true
	return stars


func _on_next_pressed() -> bool:
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	return bool(mgr.call("load_next_level"))


func _on_retry_pressed() -> bool:
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	return bool(mgr.call("reload_current_level"))


func _on_menu_pressed() -> bool:
	return get_tree().change_scene_to_file(SELECT_SCENE) == OK
