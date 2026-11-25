extends Control

## T8.04 — Menu tạm dừng: Tiếp tục / Checkpoint (R) / Chơi lại / Chọn màn + đa ngôn ngữ.

const SELECT_SCENE := "res://ui/level_select.tscn"

@onready var _title: Label = get_node_or_null("MenuBox/Title") as Label
@onready var _resume_btn: Button = get_node_or_null("MenuBox/ResumeBtn") as Button
@onready var _ckpt_btn: Button = get_node_or_null("MenuBox/CheckpointBtn") as Button
@onready var _restart_btn: Button = get_node_or_null("MenuBox/RestartBtn") as Button
@onready var _select_btn: Button = get_node_or_null("MenuBox/SelectBtn") as Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	_apply_locale()


func _exit_tree() -> void:
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: String) -> void:
	_apply_locale()


func _apply_locale() -> void:
	if _title != null:
		_title.text = LocalePack.tr_key("pause_title")
	if _resume_btn != null:
		_resume_btn.text = LocalePack.tr_key("pause_resume")
	if _ckpt_btn != null:
		_ckpt_btn.text = LocalePack.tr_key("pause_checkpoint")
	if _restart_btn != null:
		_restart_btn.text = LocalePack.tr_key("pause_restart")
	if _select_btn != null:
		_select_btn.text = LocalePack.tr_key("pause_select")


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
	AudioManager.play_sfx("click")
	resume()


func _on_checkpoint_pressed() -> void:
	AudioManager.play_sfx("click")
	var coord := _coordinator()
	get_tree().paused = false
	visible = false
	if coord == null or not bool(coord.call("request_respawn", 1)):
		_manager_reload()


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	visible = false
	_manager_reload()


func _on_select_pressed() -> bool:
	AudioManager.play_sfx("click")
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
