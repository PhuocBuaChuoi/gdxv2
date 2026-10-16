class_name BalancedFloatPair
extends Node2D

## Bonus — cân bằng hai hộp bằng hai lò xo hồi phục và giảm chấn.
@export var target_height: float = 0.0
@export var horizontal_separation: float = 96.0
@export var spring_strength: float = 18.0
@export var damping: float = 7.0
var box_a: RigidBody2D
var box_b: RigidBody2D
var _configured: bool = false

func _ready() -> void:
	var a := get_node_or_null("BoxA") as RigidBody2D
	var b := get_node_or_null("BoxB") as RigidBody2D
	if a != null and b != null:
		configure(a, b)

func configure(a: RigidBody2D, b: RigidBody2D) -> void:
	box_a = a
	box_b = b
	if is_zero_approx(target_height):
		target_height = (a.position.y + b.position.y) * 0.5
	a.gravity_scale = 0.0
	b.gravity_scale = 0.0
	_configured = true

func _physics_process(_delta: float) -> void:
	if not _configured or not is_instance_valid(box_a) or not is_instance_valid(box_b):
		return
	var midpoint := (box_a.position + box_b.position) * 0.5
	var target_a := Vector2(midpoint.x - horizontal_separation * 0.5, target_height)
	var target_b := Vector2(midpoint.x + horizontal_separation * 0.5, target_height)
	_apply_balance(box_a, target_a)
	_apply_balance(box_b, target_b)

func _apply_balance(box: RigidBody2D, target: Vector2) -> void:
	var error := target - box.position
	var force := error * spring_strength - box.linear_velocity * damping
	box.apply_central_force(force * box.mass)
