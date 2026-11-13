class_name CubeState
extends PlayerFormState

const CarrierScript = preload("res://components/carrier_platform.gd")


## T4.02 — Cube State (Dạng thường của Geometry Dash).
## Physics: Tăng tốc cao, dừng gần tức thì, nhảy GD-style, xoay trên không, tự làm tròn khi chạm đất.
## Co-op: Có bệ đỡ trên đầu cho đồng đội đứng lên (T4.03).


const BASE_SPEED: float = 420.0
const ACCEL: float = 4000.0
const JUMP_VELOCITY: float = 650.0
const ROTATION_SPEED: float = 500.0
const SNAP_SPEED: float = 720.0


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	super.enter(player_ref, prev)
	# Reset rotation về 0 khi vào Cube state
	player.visual_root.rotation = lerp(player.visual_root.rotation, 0.0, 0.15)


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	# Xử lý horizontal movement với gia tốc cao
	var axis: float = player.get_move_axis()
	player.velocity.x = move_toward(player.velocity.x, axis * BASE_SPEED, ACCEL * delta)

	# Nhảy giữ phím (GD-style continuous jump) + buffer T3.05.
	if (player.is_jump_pressed() or player._jump_buffer_timer > 0.0) \
			and (player.is_on_floor() or player._coyote_timer > 0.0):
		player.velocity.y = -JUMP_VELOCITY * player.gravity_direction
		player._jump_buffer_timer = 0.0
		player._coyote_timer = 0.0

	# Xoay theo hướng ĐANG di chuyển (kể cả quán tính), không theo phím:
	# Nếu nhân vật có skin hoặc bật keep_upright_on_jump: luôn giữ đầu hướng lên trên (0.0 rad).
	if not player.is_on_floor():
		if player.keep_upright_on_jump or player.skin != "NONE":
			player.visual_root.rotation = 0.0
		else:
			var spin_dir: float = 1.0 if player.velocity.x >= 0.0 else -1.0
			player.visual_root.rotation += deg_to_rad(ROTATION_SPEED) * spin_dir * delta
	else:
		if player.keep_upright_on_jump or player.skin != "NONE":
			player.visual_root.rotation = 0.0
		else:
			snap_landing_rotation(delta)


## Tiếp đất: bắt visual về bội số 90° gần nhất (SNAP_SPEED °/s, ~0.07s cho 60°).
## Tách riêng để test được mà không cần fake is_on_floor().
func snap_landing_rotation(delta: float) -> void:
	var target: float = deg_to_rad(snappedf(rad_to_deg(player.visual_root.rotation), 90.0))
	var current: float = player.visual_root.rotation
	player.visual_root.rotation = move_toward(current, target, deg_to_rad(SNAP_SPEED) * delta)
	if is_equal_approx(player.visual_root.rotation, target):
		player.visual_root.rotation = wrapf(player.visual_root.rotation, -PI, PI)


func update_visuals(delta: float) -> void:
	# Hiệu ứng squash & stretch khi nhảy
	if player.is_jump_just_pressed() and (player.is_on_floor() or player._coyote_timer > 0.0):
		# Giữ dấu lật mặt: tween tới +1 sẽ làm cube quay mặt phải giữa chừng
		# nếu đang nhìn trái (nhấp nháy gương mỗi frame).
		var dir: float = float(player.last_facing_dir if player.last_facing_dir != 0 else 1)
		var target_scale: Vector2 = Vector2(1.3 * dir, 0.7)
		var tween: Tween = player.create_tween().set_trans(Tween.TRANS_ELASTIC)
		player.visual_root.scale = target_scale
		tween.tween_property(player.visual_root, "scale", Vector2(dir, 1.0), 0.15)
		tween.tween_callback(func(): pass) # Cleanup
	
	# Ground sparks đã handle trong player.gd


func can_break_dash_blocks() -> bool:
	return false


func is_floating() -> bool:
	return false


func get_head_platform() -> AnimatableBody2D:
	"""Trả về head platform node để đồng đội đứng lên."""
	var platform_node: Node = player.get_node_or_null("HeadPlatform") as Node
	if platform_node == null or not is_instance_valid(platform_node):
		platform_node = _create_head_platform()
	return platform_node as AnimatableBody2D


func _create_head_platform() -> AnimatableBody2D:
	"""Tạo Head Platform nếu chưa tồn tại (cho Cube-on-Cube T4.03)."""
	var platform := AnimatableBody2D.new()
	platform.name = "HeadPlatform"
	platform.sync_to_physics = false
	platform.set_script(CarrierScript)
	platform.collision_layer = 1 << 8
	platform.collision_mask = 1 << (2 if player.player_id == 1 else 1)
	
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(44, 4)
	shape.one_way_collision = true
	shape.rotation = 0.0 if player.gravity_direction == 1 else PI
	platform.add_child(shape)
	
	platform.position = Vector2(0, -25.0 * float(player.gravity_direction))
	player.add_child(platform)
	return platform
