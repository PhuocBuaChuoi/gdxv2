class_name JumpOrb
extends Area2D

## T6.04 — Jump Orb lơ lửng: kích hoạt khi người chơi ĐANG trong vùng
## VÀ nhấn mới phím Nhảy (p1_jump / p2_jump theo player_id).
## YELLOW: bật cao trên không · BLUE: đảo trọng lực trên không · DASH: hồi 1 lượt Dash.

@export_enum("YELLOW", "BLUE", "DASH") var orb_type: int = 0:
	set(value):
		orb_type = value
		_update_color()

const ORB_JUMP: float = 1100.0
const ORB_COLORS := {
	0: Color(1, 0.85, 0, 0.95),
	1: Color(0.3, 0.6, 1, 0.95),
	2: Color(1, 0.3, 0.75, 0.95),
}

var _overlapping: Dictionary = {}
var _pulse_time: float = 0.0


func _ready() -> void:
	_update_color()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	_pulse_time += _delta
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 4.0)
	var glow := get_node_or_null("Glow") as Polygon2D
	var ring := get_node_or_null("Ring") as Line2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + pulse * 0.12)
		glow.color.a = 0.12 + pulse * 0.12
	if ring != null:
		ring.rotation = _pulse_time * 0.7
		ring.modulate.a = 0.45 + pulse * 0.35
	for body in _overlapping.values():
		if is_instance_valid(body) and _jump_just_pressed(body):
			trigger(body)


func trigger(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false
	match orb_type:
		0:
			if not body is CharacterBody2D:
				return false
			var gd := 1
			var gd_v: Variant = body.get("gravity_direction")
			if gd_v is int:
				gd = int(gd_v)
			(body as CharacterBody2D).velocity.y = -ORB_JUMP * gd
		1:
			if not body.has_method("set_gravity_direction"):
				return false
			var cur := 1
			var cur_v: Variant = body.get("gravity_direction")
			if cur_v is int:
				cur = int(cur_v)
			body.call("set_gravity_direction", -cur)
		2:
			var st: Variant = body.get("current_state")
			if st == null or not (st is Object) or not (st as Object).has_method("recharge_dash"):
				return false
			(st as Object).call("recharge_dash")
		_:
			return false
	AudioManager.play_sfx("jump")
	return true


func _jump_just_pressed(body: Node2D) -> bool:
	var pid_v: Variant = body.get("player_id")
	if not (pid_v is int) or int(pid_v) <= 0:
		return false
	return Input.is_action_just_pressed("p1_jump" if int(pid_v) == 1 else "p2_jump")


func _on_body_entered(body: Node2D) -> void:
	_overlapping[body.get_instance_id()] = body


func _on_body_exited(body: Node2D) -> void:
	_overlapping.erase(body.get_instance_id())


func _update_color() -> void:
	var orb := get_node_or_null("Orb") as Polygon2D
	if orb != null:
		orb.color = ORB_COLORS.get(orb_type, Color.WHITE)
