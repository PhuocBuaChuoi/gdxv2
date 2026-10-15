extends Control

## T8.03 — HUD trong màn: tên màn + Attempt, đồng hồ, dạng P1/P2.
## Tự tìm LevelRoot cha, đọc timer, nghe Events + RespawnCoordinator.
## Không sửa level_controller — mọi thứ qua get()/signal (decouple).

var _level: Node = null
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
		_title.text = "Màn %d" % (int(_level.get("level_index")) + 1)
	_refresh_attempt()
	_refresh_forms()
	Events.player_form_changed.connect(_on_form_changed)
	var coord: Node = get_parent().get_node_or_null("../RespawnCoordinator") if get_parent() != null else null
	if coord != null and coord.has_signal("attempt_changed"):
		coord.connect("attempt_changed", _on_attempt_changed)


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


func _refresh_attempt() -> void:
	_attempt.text = "Attempt %d" % _attempts


func _refresh_forms() -> void:
	_form.text = "P1: %s   P2: %s" % [str(_forms.get(1, "?")), str(_forms.get(2, "?"))]


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%02d:%05.2f" % [total / 60, t - float(total / 60 * 60)]
