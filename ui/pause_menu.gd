extends Control

## T8.04 — Menu tạm dừng: Tiếp tục / Checkpoint (R) / Chơi lại / Chọn màn.
## process_mode = ALWAYS (spec ghi WHEN_PAUSED nhưng mode đó không nhận input
## lúc chưa pause nên không thể BẬT pause — ALWAYS + tự ẩn/hiện mới đúng).

const SELECT_SCENE := "res://ui/level_select.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if get_tree().paused:
		resume()
	else:
		get_tree().paused = true
		visible = true


func resume() -> void:
	get_tree().paused = false
	visible = false


func _on_resume_pressed() -> void:
	resume()


func _on_checkpoint_pressed() -> void:
	var coord := _coordinator()
	get_tree().paused = false
	visible = false
	if coord == null or not bool(coord.call("request_respawn", 1)):
		_manager_reload()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	_manager_reload()


func _on_select_pressed() -> bool:
	get_tree().paused = false
	visible = false
	return get_tree().change_scene_to_file(SELECT_SCENE) == OK


func _coordinator() -> Node:
	var ancestor: Node = get_parent()
	while ancestor != null:
		var nested := ancestor.get_node_or_null("RespawnCoordinator")
		if nested != null:
			return nested
		ancestor = ancestor.get_parent()
	var sc: Node = get_tree().current_scene
	if sc == null:
		return null
	var direct := sc.get_node_or_null("RespawnCoordinator")
	if direct != null:
		return direct
	return sc.find_child("RespawnCoordinator", true, false)


func _manager_reload() -> void:
	var mgr: Node = get_node_or_null("/root/LevelManager")
	if mgr != null:
		mgr.call("reload_current_level")
