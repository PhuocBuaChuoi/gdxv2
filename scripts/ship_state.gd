class_name ShipState
extends PlayerFormState


## T4.04 — Ship State (Dạng Tàu).
## Physics: Giữ W/Up để bay lên, thả rơi nhẹ, tự động xoay mũi tàu theo vận tốc dọc.
## Co-op: Bệ đỡ lưng ngang ổn định cho đồng đội đứng + Tether beam kéo (T4.05).


const THRUST_ACCEL: float = 1200.0
const MAX_RISE_SPEED: float = 350.0
const GRAVITY_FACTOR: float = 0.55
const MAX_FALL_SPEED: float = 280.0
const TILT_MAX: float = PI / 4.0
const TILT_SENSITIVITY: float = 0.0012


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	super.enter(player_ref, prev)
	# Reset rotation về 0 khi vào Ship state
	player.visual_root.rotation = 0.0


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	var thrust_enabled: bool = player.is_jump_pressed()
	
	if thrust_enabled:
		# Bay lên khi giữ phím Jump
		if player.gravity_direction == -1: # Khi đi trần
			player.velocity.y += THRUST_ACCEL * delta
		else: # Bình thường
			player.velocity.y -= THRUST_ACCEL * delta
		
		# Clamp max rise speed
		player.velocity.y = clampf(player.velocity.y, -MAX_RISE_SPEED, MAX_RISE_SPEED)
	else:
		# Rơi theo trọng lực nhẹ (55% gravity cơ bản)
		var ship_gravity: float = player.BASE_GRAVITY * GRAVITY_FACTOR
		if player.gravity_direction == -1:
			player.velocity.y += ship_gravity * delta
		else:
			player.velocity.y -= ship_gravity * delta
	
	# Clamp max fall speed
	player.velocity.y = clampf(player.velocity.y, -MAX_FALL_SPEED, MAX_FALL_SPEED)
	
	# Tự động xoay mũi tàu theo velocity.y
	var target_tilt: float = -player.velocity.y * TILT_SENSITIVITY
	target_tilt = clampf(target_tilt, -TILT_MAX, TILT_MAX)
	
	# Giữ chiều hướng mặt trước dựa trên axis cuối cùng
	if absf(player.velocity.x) > 1.0:
		var sign_dir: int = 1 if player.velocity.x >= 0 else -1
		target_tilt *= sign_dir
	
	player.visual_root.rotation = lerp(player.visual_root.rotation, target_tilt, 10.0 * delta)


func update_visuals(delta: float) -> void:
	# Hiệu ứng engine glow khi thrust
	var glow_intensity: float = 0.6 + 0.4 * minf(absf(player.velocity.y) / MAX_RISE_SPEED, 1.0)
	var fill_poly: Polygon2D = player.visual_root.get_node_or_null("FillPolygon") as Polygon2D
	if fill_poly != null:
		fill_poly.color.a = 0.70 + 0.20 * glow_intensity


func can_break_dash_blocks() -> bool:
	return false


func is_floating() -> bool:
	return true


func get_tether_beam() -> Area2D:
	"""Trả về Tether Beam cho Ship co-op (T4.05)."""
	var tether_node: Node = player.get_node_or_null("TetherBeam") as Node
	if tether_node == null:
		tether_node = _create_tether_beam()
	return tether_node as Area2D


func _create_tether_beam() -> Area2D:
	"""Tạo Tether Beam dưới bụng tàu cho phép kéo đồng đội/khối (T4.05)."""
	var tether := Area2D.new()
	tether.name = "TetherBeam"
	tether.collision_layer = 0 # Chỉ detect objects cần kéo
	
	# Shape hình chữ nhật ngang dưới bụng tàu
	var shape := CollisionShape2D.new()
	shape.name = "TetherShape"
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(140, 8)
	tether.add_child(shape)
	
	# Line2D vẽ tia kéo từ tính
	var line := Line2D.new()
	line.name = "TetherLine"
	line.width = 2.0
	line.default_color = Color(0.3, 0.7, 1.0, 0.5)
	tether.add_child(line)
	
	# Kết nối với VisualRoot để position đúng
	player.visual_root.add_child(tether)
	
	return tether
