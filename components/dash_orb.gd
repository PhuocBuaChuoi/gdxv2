class_name DashOrb
extends Area2D

## T4.07 — contact with this orb immediately restores a Dash charge.
var _pulse: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Neon GD-style: nhan pulse + vong halo xoay (visual-only, khong scale Area).
	_pulse += delta
	var s := 1.0 + 0.09 * sin(_pulse * 4.2)
	var glow := get_node_or_null("Glow") as Polygon2D
	if glow != null:
		glow.scale = Vector2(s, s)
	var ring := get_node_or_null("GlowRing") as Line2D
	if ring != null:
		ring.scale = Vector2(s, s)
		ring.rotation += delta * 0.9
		ring.modulate.a = 0.30 + 0.25 * (0.5 + 0.5 * sin(_pulse * 4.2))

func _on_body_entered(body: Node2D) -> void:
	if body is GdxPlayer:
		recharge(body as GdxPlayer)

func recharge(player: GdxPlayer) -> bool:
	if player == null or player.form != &"DASH":
		return false
	var dash := player.current_state as DashState
	if dash == null:
		return false
	dash.recharge_dash()
	Events.orb_activated.emit()
	AudioManager.play_sfx("click")
	return true
