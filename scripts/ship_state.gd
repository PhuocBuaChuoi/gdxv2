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
## T4.05: tốc độ nâng mục tiêu của tether (px/s). KHÔNG nhân delta — bản cũ dùng
## `900.0 * delta` làm offset nên ở 60fps chỉ còn ~15 px/s, không nhấc nổi đồng đội.
const TETHER_LIFT_SPEED: float = 260.0
const TETHER_PULL_RATE: float = 1200.0
const TETHER_RIGID_FORCE: float = 2400.0


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	super.enter(player_ref, prev)
	# Reset rotation về 0 khi vào Ship state
	player.visual_root.rotation = 0.0


func exit() -> void:
	# Tether là sensor gameplay của riêng dạng tàu: rời dạng phải tắt + ẩn tia,
	# nếu không tia kéo còn nguyên trên màn hình và sensor vẫn quét khi là Cube/UFO.
	var tether := player.get_node_or_null("TetherBeam") as Area2D
	if tether == null:
		return
	tether.monitoring = false
	var line := tether.get_node_or_null("TetherLine") as Line2D
	if line != null:
		line.visible = false


func physics_update(delta: float) -> void:
	var axis := player.get_move_axis()
	player.velocity.x = move_toward(player.velocity.x, axis * 420.0, 4000.0 * delta)
	var gd: float = float(player.gravity_direction)

	if player.is_jump_pressed():
		# Bay theo hướng "lên" của trọng lực hiện tại (đảo trọng lực vẫn đúng chiều).
		player.velocity.y -= THRUST_ACCEL * gd * delta
	else:
		# Rơi theo trọng lực nhẹ (55% gravity cơ bản)
		player.velocity.y += player.BASE_GRAVITY * GRAVITY_FACTOR * gd * delta

	# Giới hạn theo TRỤC TRỌNG LỰC (dương = rơi, âm = bay lên). Clamp đối xứng cũ
	# làm MAX_RISE_SPEED thành dead code và sai hẳn khi trọng lực bị đảo.
	var along_gravity: float = clampf(player.velocity.y * gd, -MAX_RISE_SPEED, MAX_FALL_SPEED)
	player.velocity.y = along_gravity * gd

	# Tự động xoay mũi tàu theo velocity.y
	var target_tilt: float = player.velocity.y * TILT_SENSITIVITY * signf(player.last_facing_dir)
	target_tilt = clampf(target_tilt, -TILT_MAX, TILT_MAX)

	player.visual_root.rotation = lerp(player.visual_root.rotation, target_tilt, 10.0 * delta)
	var platform := player.get_node_or_null("HeadPlatform") as AnimatableBody2D
	if platform != null:
		platform.global_rotation = 0.0
	_update_tether(delta)


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
	var tether_node: Node = player.get_node_or_null("TetherBeam")
	if tether_node == null:
		tether_node = _create_tether_beam()
	return tether_node as Area2D


func _create_tether_beam() -> Area2D:
	"""Tạo Tether Beam dưới bụng tàu cho phép kéo đồng đội/khối (T4.05)."""
	var tether := Area2D.new()
	tether.name = "TetherBeam"
	tether.collision_layer = 0 # Chỉ detect objects cần kéo
	tether.collision_mask = (1 << (2 if player.player_id == 1 else 1)) | (1 << 7)
	tether.monitoring = true
	
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
	line.visible = false
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 140)])
	tether.add_child(line)
	
	# Gắn vào Player, KHÔNG gắn vào VisualRoot: VisualRoot nghiêng theo mũi tàu và bị
	# tween biến hình scale 1.3, gắn vào đó thì sensor xoay/co giãn lệch khỏi bụng tàu.
	player.add_child(tether)
	tether.position = Vector2(0, 28)
	
	return tether

func _update_tether(delta: float) -> void:
	var tether := get_tether_beam()
	var active := player.is_action_pressed()
	var gd: float = float(player.gravity_direction)
	if not tether.monitoring:
		tether.monitoring = true
	# Player không xoay nên sensor luôn nằm ngang (không theo độ nghiêng của tàu).
	tether.rotation = 0.0
	tether.position = Vector2(0.0, 28.0 * gd)
	var line := tether.get_node_or_null("TetherLine") as Line2D
	if line != null:
		line.visible = active
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, 140.0 * gd)])
	if not active:
		return
	for body in tether.get_overlapping_bodies():
		apply_tether_force(body as Node2D, delta)

func apply_tether_force(body: Node2D, delta: float) -> void:
	if body == null or body == player:
		return
	var gd: float = float(player.gravity_direction)
	# "Nâng" = kéo theo hướng tàu bay được, tức ngược chiều trọng lực hiện tại.
	var target_vy: float = player.velocity.y - TETHER_LIFT_SPEED * gd
	if body is CharacterBody2D:
		var character := body as CharacterBody2D
		character.velocity.y = move_toward(character.velocity.y, target_vy, TETHER_PULL_RATE * delta)
	elif body is RigidBody2D:
		var rigid := body as RigidBody2D
		rigid.apply_central_force(Vector2(0.0, -TETHER_RIGID_FORCE * gd * rigid.mass)) # T6.09: du suc nang khoi (thang trong luc 1800)
