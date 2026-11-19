class_name GravityPortal
extends Area2D

## T6.02 / bonus — cổng đảo trọng lực cho Player và vật thể vật lý.
## toggle_mode: TOGGLE (đảo chiều hiện tại thay vì ép Normal/Inverted).
@export_enum("Normal", "Inverted") var target_direction: int = -1
@export var one_shot: bool = false
@export var toggle_mode: bool = false
@export var retrigger_delay: float = 0.4
var _used_bodies: Dictionary = {}
var _last_used: Dictionary = {}
var _pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 3.0)
	var ring := get_node_or_null("GlowRing") as Line2D
	var core := get_node_or_null("Core") as Polygon2D
	var spr := get_node_or_null("PortalSprite") as Sprite2D
	if spr != null:
		spr.scale = Vector2.ONE * (1.0 + pulse * 0.06)
	if ring != null:
		ring.scale = Vector2.ONE * (1.0 + pulse * 0.10)
		ring.rotation = sin(_pulse_time * 0.6) * 0.12
		ring.modulate.a = 0.30 + pulse * 0.35
	if core != null:
		core.rotation = _pulse_time * 1.2
		core.scale = Vector2.ONE * (0.85 + pulse * 0.30)
		core.modulate.a = 0.35 + pulse * 0.35

func _on_body_entered(body: Node2D) -> void:
	if one_shot and _used_bodies.has(body.get_instance_id()):
		return
	# Khóa đổi chiều lặp khi đứng rung trong vùng (bonus T6).
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = float(_last_used.get(body.get_instance_id(), -10.0))
	if now - last < retrigger_delay:
		return
	_last_used[body.get_instance_id()] = now
	apply_to(body)
	_used_bodies[body.get_instance_id()] = true

func apply_to(body: Node2D) -> void:
	var direction := target_direction
	if toggle_mode:
		var cur := _current_gravity_dir(body)
		if cur == 0:
			return
		direction = -cur
	if body.has_method("set_gravity_direction"):
		body.call("set_gravity_direction", direction)
	elif body is RigidBody2D:
		(body as RigidBody2D).gravity_scale = -1.0 if direction < 0 else 1.0
	else:
		return
	Events.portal_activated.emit(direction)
	AudioManager.play_sfx("portal")
	_flash()


func _current_gravity_dir(body: Node2D) -> int:
	var v: Variant = body.get("gravity_direction")
	if v is int and int(v) != 0:
		return signi(int(v))
	if body is RigidBody2D:
		return signi(int(signf((body as RigidBody2D).gravity_scale)))
	return 1


func _flash() -> void:
	var ring := get_node_or_null("GlowRing") as Line2D
	if ring == null:
		return
	var tween := create_tween()
	tween.tween_property(ring, "modulate:a", 0.95, 0.05)
	tween.tween_property(ring, "modulate:a", 0.28, 0.22)

func reset_body(body: Node2D) -> void:
	_used_bodies.erase(body.get_instance_id())
