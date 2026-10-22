class_name CarrierPlatform
extends AnimatableBody2D

## T4.03 — one-way carrier platform that transfers horizontal motion to riders.
var carrier_velocity: Vector2 = Vector2.ZERO
var _previous_global_position: Vector2

func _ready() -> void:
	_previous_global_position = global_position

func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	carrier_velocity = (global_position - _previous_global_position) / delta
	_previous_global_position = global_position
	var detector := get_node_or_null("RiderDetector") as Area2D
	if detector == null:
		return
	for body in detector.get_overlapping_bodies():
		if body is CharacterBody2D and body != get_parent():
			var gd := 1
			var gd_v: Variant = body.get("gravity_direction")
			if gd_v is int and int(gd_v) != 0:
				gd = int(gd_v)
			# Rider phai o phia "dau" cua platform theo trong luc cua ho.
			if (body.global_position.y - global_position.y) * float(gd) >= 0.0:
				continue
			(body as CharacterBody2D).velocity.x += carrier_velocity.x
			var dash := (body as CharacterBody2D).get("current_state") as DashState
			if dash != null and dash.has_method("notify_rider_contact"):
				dash.notify_rider_contact()

func transfer_velocity(rider: CharacterBody2D) -> void:
	if rider != null and rider != get_parent():
		rider.velocity += carrier_velocity
