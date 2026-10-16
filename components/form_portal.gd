@tool
class_name FormPortal
extends Area2D

## T6.01 — Cổng Chuyển Dạng: đổi dạng người chơi khi đi qua,
## lọc theo allowed_player (BOTH / P1_ONLY / P2_ONLY — cực hay cho giải đố).

@export_enum("CUBE", "SHIP", "UFO", "DASH") var target_form: String = "CUBE":
	set(value):
		target_form = value
		_update_color()

@export_enum("BOTH", "P1_ONLY", "P2_ONLY") var allowed_player: String = "BOTH":
	set(value):
		allowed_player = value
		_update_color()

var _pulse: float = 0.0

const FORM_COLORS := {
	"CUBE": Color(1, 1, 1, 0.9),
	"SHIP": Color(0.3, 0.8, 1, 0.9),
	"UFO": Color(1, 0.4, 0.9, 0.9),
	"DASH": Color(1, 0.35, 0.2, 0.9),
}
var _pulse_time: float = 0.0


func _ready() -> void:
	_update_color()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse += delta
	_pulse_time += delta
	# Hoi tho Inner (T8) + scale Glow (neu co node Glow).
	var inner := get_node_or_null("Inner") as Polygon2D
	if inner != null:
		inner.modulate.a = 0.6 + 0.4 * (0.5 + 0.5 * sin(_pulse * 3.0))
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 2.5)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + pulse * 0.08)
		glow.modulate.a = 0.18 + pulse * 0.16


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("switch_form"):
		return
	if not _player_allowed(body):
		return
	body.call("switch_form", StringName(target_form))
	AudioManager.play_sfx("portal")
	_flash()


func _flash() -> void:
	var frame := get_node_or_null("Frame") as Polygon2D
	if frame == null:
		return
	var tween := create_tween()
	tween.tween_property(frame, "modulate:a", 1.0, 0.05)
	tween.tween_property(frame, "modulate:a", 0.72, 0.20)


func _player_allowed(body: Node2D) -> bool:
	var pid_v: Variant = body.get("player_id")
	var pid := int(pid_v) if pid_v is int else 0
	match allowed_player:
		"P1_ONLY":
			return pid == 1
		"P2_ONLY":
			return pid == 2
	return true


func _update_color() -> void:
	var c: Color = FORM_COLORS.get(target_form, Color.WHITE)
	var frame := get_node_or_null("Frame") as Polygon2D
	if frame != null:
		frame.color = c
	var inner := get_node_or_null("Inner") as Polygon2D
	if inner != null:
		inner.color = Color(c.r, c.g, c.b, c.a * 0.35)
