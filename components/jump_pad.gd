class_name JumpPad
extends Area2D

## T6.03 — Jump Pad đặt trên mặt đất: chạm vào là tự phóng lên.
## Vàng = bật trung bình · Hồng = bật thấp · Đỏ = bật cực cao.

@export_enum("YELLOW", "PINK", "RED") var pad_type: int = 0:
	set(value):
		pad_type = value
		_update_color()

const BOOSTS := {0: 950.0, 1: 450.0, 2: 1400.0}
const PAD_COLORS := {
	0: Color(1, 0.85, 0, 0.95),
	1: Color(1, 0.3, 0.85, 0.95),
	2: Color(1, 0.23, 0.23, 0.95),
}
var _pulse_time: float = 0.0


func _ready() -> void:
	_update_color()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 4.0)
	var glow := get_node_or_null("Glow") as Polygon2D
	var edge := get_node_or_null("NeonEdge") as Line2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + pulse * 0.08)
		glow.color.a = 0.10 + pulse * 0.12
	if edge != null:
		edge.modulate.a = 0.60 + pulse * 0.35


func boost_value() -> float:
	return float(BOOSTS.get(pad_type, 950.0))


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	var gd := 1
	var gd_v: Variant = body.get("gravity_direction")
	if gd_v is int:
		gd = int(gd_v)
	(body as CharacterBody2D).velocity.y = -boost_value() * gd
	AudioManager.play_sfx("jump")


func _update_color() -> void:
	var pad := get_node_or_null("Pad") as Polygon2D
	if pad != null:
		pad.color = PAD_COLORS.get(pad_type, Color.WHITE)
