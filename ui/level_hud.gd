extends Control

## T8.03 — HUD trong màn: tên màn + Attempt, đồng hồ, dạng P1/P2.

var _level: Node = null
var _level_index: int = 0
var _attempts: int = 1
var _forms := {1: &"CUBE", 2: &"CUBE"}

@onready var _title: Label = $TopLeft/LevelLabel
@onready var _attempt: Label = $TopLeft/AttemptLabel
@onready var _time: Label = $TopRight/TimeLabel
@onready var _form: Label = $TopRight/FormsLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level = _find_level_root()
	if _level != null:
		var level_index = _level.get("level_index")
		if level_index != null:
			_level_index = int(level_index)
		var p1: Node = _level.get_node_or_null("Players/PlayerP1")
		var p2: Node = _level.get_node_or_null("Players/PlayerP2")
		if p1 != null:
			_forms[1] = p1.get("form")
		if p2 != null:
			_forms[2] = p2.get("form")
	_refresh_title()
	_refresh_forms()
	if not Events.player_form_changed.is_connected(_on_form_changed):
		Events.player_form_changed.connect(_on_form_changed)
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	var coord: Node = _level.get_node_or_null("RespawnCoordinator") if _level != null else null
	if coord == null:
		var ancestor: Node = get_parent()
		while ancestor != null and coord == null:
			coord = ancestor.get_node_or_null("RespawnCoordinator")
			ancestor = ancestor.get_parent()
	if coord != null and coord.has_signal("attempt_changed"):
		_attempts = int(coord.get("attempt_count"))
		coord.connect("attempt_changed", _on_attempt_changed)
	_refresh_attempt()


func _exit_tree() -> void:
	if Events.player_form_changed.is_connected(_on_form_changed):
		Events.player_form_changed.disconnect(_on_form_changed)
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: String) -> void:
	_refresh_title()
	_refresh_attempt()


func _find_level_root() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.name == "LevelRoot" or n.has_method("get_player_positions"):
			return n
		n = n.get_parent()
	return get_tree().current_scene


func _process(_delta: float) -> void:
	if _level != null:
		_time.text = _fmt_time(float(_level.get("level_time")))


func _on_attempt_changed(n: int) -> void:
	_attempts = n
	_refresh_attempt()


func _on_form_changed(player_id: int, new_form: StringName) -> void:
	_forms[player_id] = new_form
	_refresh_forms()


func _refresh_title() -> void:
	if _level != null and bool(_level.get_meta("is_custom_level", false)):
		_title.text = LocalePack.tr_key("hud_level_custom", [str(_level.get_meta("custom_level_name", "Custom"))])
		return
	_title.text = LocalePack.tr_key("hud_level", [_level_index + 1])


func _refresh_attempt() -> void:
	_attempt.text = LocalePack.tr_key("hud_attempt", [_attempts])


func _refresh_forms() -> void:
	_form.text = "P1: %s   P2: %s" % [str(_forms.get(1, "?")), str(_forms.get(2, "?"))]


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%02d:%05.2f" % [total / 60, t - float(total / 60 * 60)]
