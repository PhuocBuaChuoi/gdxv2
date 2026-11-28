extends Control

## T8.05 — Bảng tổng kết hoàn thành màn: thời gian, số chết, sao, Màn tiếp + đa ngôn ngữ.

const SELECT_SCENE := "res://ui/level_select.tscn"

var manager: Node = null
var _last_time: float = 0.0
var _last_deaths: int = 0

@onready var _title: Label = get_node_or_null("PanelBox/Title") as Label
@onready var _time: Label = $PanelBox/TimeLabel
@onready var _deaths: Label = $PanelBox/DeathsLabel
@onready var _stars: Label = $PanelBox/StarsLabel
@onready var _next_btn: Button = get_node_or_null("PanelBox/NextBtn") as Button
@onready var _retry_btn: Button = get_node_or_null("PanelBox/RetryBtn") as Button
@onready var _menu_btn: Button = get_node_or_null("PanelBox/MenuBtn") as Button
@onready var _return_editor_btn: Button = get_node_or_null("PanelBox/ReturnEditorBtn") as Button


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	visible = false
	if not Events.level_completed.is_connected(_on_level_completed):
		Events.level_completed.connect(_on_level_completed)
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	_apply_locale()


func _exit_tree() -> void:
	if Events.level_completed.is_connected(_on_level_completed):
		Events.level_completed.disconnect(_on_level_completed)
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: String) -> void:
	_apply_locale()


func _apply_locale() -> void:
	if _title != null:
		_title.text = LocalePack.tr_key("win_title")
	if _next_btn != null:
		_next_btn.text = LocalePack.tr_key("win_next")
	if _retry_btn != null:
		_retry_btn.text = LocalePack.tr_key("win_retry")
	if _menu_btn != null:
		_menu_btn.text = LocalePack.tr_key("win_menu")
	if _return_editor_btn != null:
		_return_editor_btn.text = LocalePack.tr_key("win_return_editor")
	if _time != null:
		_time.text = LocalePack.tr_key("win_time", [fmt_time(_last_time)])
	if _deaths != null:
		_deaths.text = LocalePack.tr_key("win_deaths", [_last_deaths])


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
	_last_time = time_taken
	_last_deaths = death_count
	var stars := stars_for(death_count)
	_apply_locale()
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	var playtesting := mgr != null and bool(mgr.get("is_playtest"))
	if _return_editor_btn != null:
		_return_editor_btn.visible = playtesting
	if _next_btn != null:
		_next_btn.visible = not playtesting
	if _menu_btn != null:
		_menu_btn.visible = not playtesting
	visible = true
	return stars


func _on_next_pressed() -> bool:
	AudioManager.play_sfx("click")
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	if bool(mgr.call("load_next_level")):
		return true
	var real: Node = get_node_or_null("/root/LevelManager")
	if mgr == real and get_tree().current_scene != null:
		return get_tree().change_scene_to_file(SELECT_SCENE) == OK
	return false


func _on_retry_pressed() -> bool:
	AudioManager.play_sfx("click")
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr == null:
		return false
	return bool(mgr.call("reload_current_level"))


func _on_menu_pressed() -> bool:
	AudioManager.play_sfx("click")
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr != null and mgr.has_method("exit_to_level_select"):
		mgr.call("exit_to_level_select")
	return get_tree().change_scene_to_file(SELECT_SCENE) == OK


func _on_return_editor_pressed() -> void:
	AudioManager.play_sfx("click")
	var mgr: Node = manager if manager != null else get_node_or_null("/root/LevelManager")
	if mgr != null and mgr.has_method("return_to_editor"):
		mgr.call("return_to_editor")
