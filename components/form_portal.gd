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
	"CUBE": Color(0.25, 0.9, 1, 0.9),
	"SHIP": Color(0.3, 0.8, 1, 0.9),
	"UFO": Color(0.95, 0.3, 0.85, 0.9),
	"DASH": Color(1, 0.35, 0.2, 0.9),
}

const PORTAL_TEXTURES := {
	"CUBE": preload("res://assets/sprites/portal_cube.png"),
	"SHIP": preload("res://assets/sprites/portal_ship.png"),
	"UFO": preload("res://assets/sprites/portal_ufo.png"),
	"DASH": preload("res://assets/sprites/portal_dash.png"),
}


func _ready() -> void:
	_update_color()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse += delta
	# Hoi tho Inner (T8) + scale Glow (neu co node Glow).
	var inner := get_node_or_null("Inner") as Polygon2D
	if inner != null:
		inner.modulate.a = 0.6 + 0.4 * (0.5 + 0.5 * sin(_pulse * 3.0))
	var pulse := 0.5 + 0.5 * sin(_pulse * 2.5)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + pulse * 0.08)
		glow.modulate.a = 0.18 + pulse * 0.16
	var spr := get_node_or_null("PortalSprite") as Sprite2D
	if spr != null:
		spr.scale = Vector2(1.0 + pulse * 0.04, 1.0 - pulse * 0.02)


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("switch_form"):
		return
	if not _player_allowed(body):
		return
	# Đã đúng dạng / đang bị khoá điều khiển (chết, hồi sinh): không switch lại,
	# tránh reset state + spam hiệu ứng + âm thanh mỗi lần chạm vùng cổng.
	var locked: Variant = body.get("control_locked")
	if locked is bool and locked:
		return
	var current_form: Variant = body.get("form")
	if current_form != null and str(current_form) == target_form:
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
	var c: Color = FORM_COLORS.get(target_form, Color(0.25, 0.9, 1))
	var frame := get_node_or_null("Frame") as Polygon2D
	if frame != null:
		frame.color = c
	var inner := get_node_or_null("Inner") as Polygon2D
	if inner != null:
		inner.color = Color(c.r * 0.3, c.g * 0.3, c.b * 0.3, 0.85)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		glow.color = Color(c.r, c.g, c.b, 0.12)
	var back_glow := get_node_or_null("BackGlow") as Polygon2D
	if back_glow != null:
		back_glow.color = Color(c.r, c.g, c.b, 0.1)
	var border := get_node_or_null("NeonBorder") as Line2D
	if border != null:
		border.default_color = Color(c.r, c.g, c.b, 0.8)
	var spr := get_node_or_null("PortalSprite") as Sprite2D
	if spr != null:
		spr.texture = PORTAL_TEXTURES.get(target_form, PORTAL_TEXTURES["CUBE"])
