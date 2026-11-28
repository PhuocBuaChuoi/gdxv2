class_name PlayerFormState
extends RefCounted

## T4.01 — Base class cho FSM của Player Form (Cube/Ship/UFO/Dash).
## Các state concrete override các hàm ảo: enter(), exit(), physics_update(), update_visuals().
## Mỗi state quản lý logic vật lý, visual và signals riêng.


var player: GdxPlayer
var prev_state: PlayerFormState = null


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	"""Khởi tạo khi chuyển sang state mới."""
	player = player_ref
	prev_state = prev


func exit() -> void:
	"""Làm sạch trước khi rời khỏi state."""
	pass


func physics_update(delta: float) -> void:
	"""Logic vật lý xử lý trong _physics_process."""
	pass


func update_visuals(delta: float) -> void:
	"""Animation hoặc tween visuals mỗi frame."""
	pass


func can_break_dash_blocks() -> bool:
	"""True nếu state hiện tại có thể phá khối Dash (chỉ Dash state mới True)."""
	return false


func is_floating() -> bool:
	"""True nếu đang bay/trên không (Ship/UFO)."""
	return false


func get_tether_beam() -> Area2D:
	"""Trả về tether beam cho Ship co-op (null nếu không phải Ship)."""
	return null
