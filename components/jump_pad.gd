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
const PAD_TEXTURES := {
	0: preload("res://assets/sprites/jump_pad_yellow.png"),
	1: preload("res://assets/sprites/jump_pad_pink.png"),
	2: preload("res://assets/sprites/jump_pad_red.png"),
}
const PAD_HALF_HEIGHT: float = 12.0
const PLAYER_HALF_HEIGHT: float = 22.0
const CONTACT_MARGIN: float = 4.0
var _pulse_time: float = 0.0
## Hieu ung "nun" khi bung: 1.0 -> 0.0 trong ~0.17s, giam deu moi frame.
var _squash: float = 0.0


func _ready() -> void:
	_update_color()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 4.0)
	var glow := get_node_or_null("Glow") as Polygon2D
	var edge := get_node_or_null("NeonEdge") as Line2D
	var spr := get_node_or_null("Sprite") as Sprite2D
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + pulse * 0.08)
		glow.color.a = 0.10 + pulse * 0.12
	if edge != null:
		edge.modulate.a = 0.40 + pulse * 0.25
	if spr != null:
		# Truoc day dung Tween cho hieu ung nun, nhung _process ghi de scale
		# moi frame nen hieu ung khong bao gio nhin thay. Gio giam _squash
		# ngay trong _process de chi mot nguon dieu khien scale.
		_squash = maxf(_squash - delta * 6.0, 0.0)
		spr.scale = Vector2(0.55 + _squash * 0.13, 0.55 + pulse * 0.03 - _squash * 0.17)


func boost_value() -> float:
	return float(BOOSTS.get(pad_type, 950.0))


func _on_body_entered(body: Node2D) -> void:
	if not body is GdxPlayer:
		return
	var player := body as GdxPlayer
	if not _is_landing_contact(player):
		return
	var gd := player.gravity_direction
	player.velocity.y = -boost_value() * gd
	_squash = 1.0
	AudioManager.play_sfx("jump")


func _is_landing_contact(player: GdxPlayer) -> bool:
	if player == null:
		return false
	var signed_offset := (player.global_position.y - global_position.y) * player.gravity_direction
	var closest_contact := -(PAD_HALF_HEIGHT + PLAYER_HALF_HEIGHT - CONTACT_MARGIN)
	var farthest_contact := -CONTACT_MARGIN
	if signed_offset < closest_contact or signed_offset > farthest_contact:
		return false
	return player.velocity.y * player.gravity_direction >= -10.0


func _update_color() -> void:
	var pad := get_node_or_null("Pad") as Polygon2D
	if pad != null:
		pad.color = PAD_COLORS.get(pad_type, Color.WHITE)
	var spr := get_node_or_null("Sprite") as Sprite2D
	if spr != null and PAD_TEXTURES.has(pad_type):
		spr.texture = PAD_TEXTURES[pad_type]
