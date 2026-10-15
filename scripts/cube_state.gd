class_name CubeState
extends PlayerFormState

const CarrierScript = preload("res://components/carrier_platform.gd")


## T4.02 — Cube State (Dạng thường của Geometry Dash).
## Physics: Tăng tốc cao, dừng gần tức thì, nhảy GD-style, xoay trên không, tự làm tròn khi chạm đất.
## Co-op: Có bệ đỡ trên đầu cho đồng đội đứng lên (T4.03).


const BASE_SPEED: float = 420.0
const ACCEL: float = 4000.0
const JUMP_VELOCITY: float = 650.0
const ROTATION_SPEED: float = 420.0
const SNAP_DEADZONE: float = 5.0


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
	
	# Nhảy giữ phím (GD-style continuous jump)
	if player.is_jump_pressed():
		if player.is_on_floor() or player._coyote_timer > 0.0:
			player.velocity.y = -JUMP_VELOCITY * player.gravity_direction
			player._jump_buffer_timer = 0.0
			player._coyote_timer = 0.0
	
	# Xoay nhân vật trên không
	if not player.is_on_floor():
		var sign_dir: int = 1 if axis >= 0 else -1 if axis < 0 else 0
		player.visual_root.rotation += ROTATION_SPEED * sign_dir * delta
	else:
		# Làm tròn góc về bội số 90 độ khi chạm đất
		var current_degrees: float = rad_to_deg(player.visual_root.rotation)
		var snapped: float = snappedf(current_degrees, 90.0)
		var diff: float = absf(current_degrees - snapped)
		
		if diff < SNAP_DEADZONE:
			player.visual_root.rotation = deg_to_rad(snapped)
		else:
			player.visual_root.rotation = lerp(
				player.visual_root.rotation, 
			deg_to_rad(snapped),
				10.0 * delta
			)


func update_visuals(delta: float) -> void:
	# Hiệu ứng squash & stretch khi nhảy
	if player.is_jump_just_pressed() and (player.is_on_floor() or player._coyote_timer > 0.0):
		var target_scale: Vector2 = Vector2(1.3, 0.7)
		var tween: Tween = player.create_tween().set_trans(Tween.TRANS_ELASTIC)
		player.visual_root.scale = target_scale
		tween.tween_property(player.visual_root, "scale", Vector2.ONE, 0.15)
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
	platform.set_script(CarrierScript)
	platform.collision_layer = 1 << player.player_id
	platform.collision_mask = 1 << (2 if player.player_id == 1 else 1)
	
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(44, 4)
	shape.one_way_collision = true
	platform.add_child(shape)
	
	platform.position = Vector2(0, -25)
	player.add_child(platform)
	return platform
