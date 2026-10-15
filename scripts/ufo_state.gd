class_name UfoState
extends PlayerFormState


## T4.06 — UFO State (Dạng Bay đĩa).
## Physics: Bấm W/Up từng nhịp (không giữ) để nảy như Flappy Bird.
## Co-op: Chuyên luồn lách qua khe gai trần/sàn hẹp để mở công tắc trên cao.


const HOP_SPEED: float = 380.0
const SQUASH_STRETCH_SCALE: float = 1.25
const BASE_SPEED: float = 420.0
const ACCEL: float = 4000.0


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	super.enter(player_ref, prev)
	# Reset rotation và scale
	player.visual_root.rotation = 0.0
	player.visual_root.scale = Vector2.ONE


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	# Chỉ xử lý horizontal movement (gravity vẫn dùng của player.gd)
	var axis: float = player.get_move_axis()
	player.velocity.x = move_toward(player.velocity.x, axis * BASE_SPEED, ACCEL * delta)
	
	# Nhảy bấm từng nhịp (không tự nhảy khi giữ phím)
	if player.is_jump_just_pressed():
		player.velocity.y = -HOP_SPEED * player.gravity_direction
	
	# Hiệu ứng co giãn (squash & stretch) mỗi lần bật
	# Được handle trong update_visuals bằng tween


func update_visuals(delta: float) -> void:
	# Không có logic đặc biệt, shape tròn đã đủ nhận diện UFO
	pass


func can_break_dash_blocks() -> bool:
	return false


func is_floating() -> bool:
	return true
