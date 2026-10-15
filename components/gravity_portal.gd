class_name GravityPortal
extends Area2D

## T6.02 / bonus — cổng đảo trọng lực cho Player và vật thể vật lý.
@export_enum("Normal", "Inverted") var target_direction: int = -1
@export var one_shot: bool = false
var _used_bodies: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if one_shot and _used_bodies.has(body.get_instance_id()):
		return
	apply_to(body)
	_used_bodies[body.get_instance_id()] = true

func apply_to(body: Node2D) -> void:
	if body.has_method("set_gravity_direction"):
		body.call("set_gravity_direction", target_direction)
	elif body is RigidBody2D:
		(body as RigidBody2D).gravity_scale = -1.0 if target_direction < 0 else 1.0
	else:
		return
	Events.portal_activated.emit(target_direction)
	AudioManager.play_sfx("portal")

func reset_body(body: Node2D) -> void:
	_used_bodies.erase(body.get_instance_id())
