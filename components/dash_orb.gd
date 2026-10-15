class_name DashOrb
extends Area2D

## T4.07 — contact with this orb immediately restores a Dash charge.
func _ready() -> void:
	body_entered.connect(_on_body_entered)

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
