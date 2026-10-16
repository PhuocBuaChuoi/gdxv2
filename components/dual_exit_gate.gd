class_name DualExitGate
extends Area2D

## T6.10 — Cổng Đích Đôi: khi CẢ HAI player cùng đứng trong vùng cổng
## đủ `hold_time` (mặc định 0.5s) → khoá input và phát
## `Events.level_completed(level_index, deaths, time_taken)`.

@export var hold_time: float = 0.5

var _inside: Dictionary = {}
var _timer: float = 0.0
var _done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	var arch := get_node_or_null("Arch") as Line2D
	var post_l := get_node_or_null("PostLeft") as Polygon2D
	var post_r := get_node_or_null("PostRight") as Polygon2D
	var now := Time.get_ticks_msec() / 1000.0
	if arch != null:
		if both_inside():
			var fast_pulse := 0.7 + 0.3 * sin(now * 16.0)
			arch.default_color = Color(1.0, 1.0, 0.4, fast_pulse)
		else:
			var slow_pulse := 0.5 + 0.4 * sin(now * 3.5)
			arch.default_color = Color(1.0, 1.0, 1.0, slow_pulse)
	if post_l != null:
		var has_p1: bool = _inside.has(1)
		post_l.color.a = 0.98 if has_p1 else (0.65 + 0.20 * sin(now * 3.0))
	if post_r != null:
		var has_p2: bool = _inside.has(2)
		post_r.color.a = 0.98 if has_p2 else (0.65 + 0.20 * sin(now * 3.0 + 1.0))



func reset() -> void:
	_inside.clear()
	_timer = 0.0
	_done = false


func both_inside() -> bool:
	return _inside.has(1) and _inside.has(2)


func is_done() -> bool:
	return _done


func _on_body_entered(body: Node2D) -> void:
	var pid := _player_id(body)
	if pid > 0:
		_inside[pid] = true


func _on_body_exited(body: Node2D) -> void:
	var pid := _player_id(body)
	if pid > 0:
		_inside.erase(pid)
		_timer = 0.0


func _physics_process(delta: float) -> void:
	if _done:
		return
	if both_inside():
		_timer += delta
		if _timer >= hold_time:
			_complete()
	else:
		_timer = 0.0


func _player_id(body: Node2D) -> int:
	var v: Variant = body.get("player_id")
	return int(v) if v is int and int(v) > 0 else 0


func _find_level_root() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("get_player_positions"):
			return node
		node = node.get_parent()
	return null


func _complete() -> void:
	_done = true
	var level_index := 0
	var time_taken := 0.0
	var death_count := 0
	var lvl := _find_level_root()
	if lvl != null:
		level_index = int(lvl.get("level_index"))
		time_taken = float(lvl.get("level_time"))
		death_count = int(lvl.get("deaths"))
	_lock_players(lvl)
	AudioManager.play_sfx("win")
	Events.level_completed.emit(level_index, death_count, time_taken)


func _lock_players(lvl: Node) -> void:
	if lvl == null:
		return
	var players := lvl.get_node_or_null("Players")
	if players == null:
		return
	for p in players.get_children():
		if p.has_method("set_control_locked"):
			p.call("set_control_locked", true)
