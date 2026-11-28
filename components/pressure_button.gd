class_name PressureButton
extends Area2D

## T6.06 — Nút Bấm Trọng Lượng kiểu Lửa & Nước.
## HOLD: có người/khối đè thì bật, ra là tắt.
## TOGGLE: chạm 1 lần là giữ vĩnh viễn.
## SIMULTANEOUS: 2 nút cặp đè lệch dưới `pair_window` giây → cả hai mở khoá vĩnh viễn.
## Lọc người kích hoạt: ANY / P1_ONLY / P2_ONLY / HEAVY_BLOCK_ONLY.

@export_enum("HOLD", "TOGGLE", "SIMULTANEOUS") var mode: int = 0
@export_enum("ANY", "P1_ONLY", "P2_ONLY", "HEAVY_BLOCK_ONLY") var activator: int = 0
@export var paired_button: NodePath
@export var pair_window: float = 0.5
@export var min_heavy_mass: float = 1.0

const TEX_NORMAL = preload("res://assets/sprites/pressure_button.png")
const TEX_PRESSED = preload("res://assets/sprites/pressure_button_pressed.png")

signal triggered(is_on: bool)

var is_on: bool = false

var _bodies: Dictionary = {}
var _press_time: float = -10.0
var _latched: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func is_latched() -> bool:
	return _latched


func recent_press_within(now: float, window: float) -> bool:
	return (now - _press_time) <= window


func _on_body_entered(body: Node2D) -> void:
	if not _accepts(body):
		return
	_bodies[body.get_instance_id()] = body
	var now := Time.get_ticks_msec() / 1000.0
	_press_time = now
	match mode:
		0:
			_set_on(true)
		1:
			_set_on(true)
		2:
			_try_simultaneous(now)


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body.get_instance_id())
	if _latched:
		return
	if mode == 0:
		_set_on(_bodies.size() > 0)
	elif mode == 2 and _bodies.is_empty():
		_set_on(false)


func _try_simultaneous(now: float) -> void:
	var pair := get_node_or_null(paired_button)
	if pair == null:
		return
	if pair.call("recent_press_within", now, pair_window):
		_latched = true
		pair.set("_latched", true)
		_set_on(true)
		pair.call("_set_on", true)


func _accepts(body: Node2D) -> bool:
	var pid_v: Variant = body.get("player_id")
	var is_player := pid_v is int and int(pid_v) > 0
	var is_heavy := body is RigidBody2D and (body as RigidBody2D).mass >= min_heavy_mass
	match activator:
		1:
			return is_player and int(pid_v) == 1
		2:
			return is_player and int(pid_v) == 2
		3:
			return is_heavy
	return true


func _set_on(value: bool) -> void:
	if is_on == value:
		return
	is_on = value
	triggered.emit(is_on)
	_update_visual()


func _update_visual() -> void:
	var visual := get_node_or_null("Visual") as Node2D
	if visual != null:
		visual.scale = Vector2(1.0, 0.72 if is_on else 1.0)
	var plate := get_node_or_null("Visual/Plate") as Polygon2D
	if plate != null:
		plate.color = Color(0.3, 1.0, 0.55, 0.95) if is_on else Color(0.45, 0.5, 0.6, 0.95)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		glow.color.a = 0.35 if is_on else 0.0
	var spr := get_node_or_null("Visual/ButtonSprite") as Sprite2D
	if spr != null:
		spr.texture = TEX_PRESSED if is_on else TEX_NORMAL
