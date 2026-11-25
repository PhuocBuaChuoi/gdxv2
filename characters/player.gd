class_name GdxPlayer
extends CharacterBody2D

signal death_requested(player_id: int, death_pos: Vector2)

## T3.01-T3.06 + T4.01-T4.08 — Player hoàn chỉnh với FSM cho 4 dạng biến hình.
## Quản lý trạng thái: Cube / Ship / UFO / Dash với transition mượt.


const Shapes = preload("res://scripts/procedural_shapes.gd")
const Palette = preload("res://resources/color_palette.gd")
const Skins = preload("res://resources/character_skins.gd")
const BASE_GRAVITY: float = 1800.0
const MOVE_SPEED: float = 420.0
const MOVE_ACCEL: float = 4000.0
const JUMP_VELOCITY: float = 650.0
const PUSH_FORCE: float = 700.0 # T6.09 - luc day khoi Pushable_Blocks khi ap sat
const COYOTE_TIME: float = 0.08
const JUMP_BUFFER_TIME: float = 0.10
const FORM_NAMES: Array[StringName] = [&"CUBE", &"SHIP", &"UFO", &"DASH"]


@export_range(1, 2) var player_id: int = 1
@export var gravity_direction: int = 1
@export_enum("NONE", "BIRD", "BUNNY", "FROG") var skin: String = "NONE"
@export var ceiling_y: float = -48.0
@export var floor_kill_y: float = 720.0
@export var enforce_vertical_bounds: bool = true
var form: StringName = &"CUBE"
var control_locked: bool = false
## T4.07 — lượt Dash được lưu ở player, không ở state: đổi form qua portal rồi
## đổi lại không được "free recharge" khi enter() tạo DashState mới.
var dash_charge_available: bool = true
var _last_push_targets: Array = [] # T6.09 - khoi dang day (de ngat luc khi roi)
var _forced_push_target: RigidBody2D = null # T6.09 - target duoc gan luc truc tiep boi _push_box
var _death_reported: bool = false


# State Machine
var current_state: PlayerFormState = null
var _state_machine: StateMachine = null

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var last_facing_dir: int = 1

@onready var visual_root: Node2D = $VisualRoot
@onready var ground_sparks: GPUParticles2D = $GroundSparks
@onready var motion_trail: Line2D = $MotionTrail
@onready var hazard_detector: Area2D = $HazardDetector
@onready var visual_controller: Node2D = $VisualRoot
@onready var head_platform: AnimatableBody2D = $HeadPlatform
var _skin_visual: Node2D
var _skin_body: AnimatedSprite2D
var _skin_animation: String = ""


func _ready() -> void:
	player_id = clampi(player_id, 1, 2)
	_setup_collision_layers()
	if not hazard_detector.area_entered.is_connected(_on_hazard_area_entered):
		hazard_detector.area_entered.connect(_on_hazard_area_entered)
	if not hazard_detector.body_entered.is_connected(_on_hazard_body_entered):
		hazard_detector.body_entered.connect(_on_hazard_body_entered)
	_setup_state_machine()
	
	up_direction = Vector2.UP if gravity_direction == 1 else Vector2.DOWN
	_update_head_platform()
	
	switch_form(&"CUBE")
	_setup_skin_visual()
	_setup_vfx()


## T2.05/T2.06 — MotionTrail nằm ở gốc level (top_level) nên to_local() mới ra
## đúng quỹ đạo; GroundSparks chỉ bật khi Cube đang trượt trên mặt đất.
func _setup_vfx() -> void:
	if motion_trail != null:
		motion_trail.top_level = true
		motion_trail.global_position = Vector2.ZERO
		motion_trail.setup(self, _get_color_for_form())
		motion_trail.set_width_for_form(form)
	if ground_sparks != null:
		ground_sparks.set_active(false)


func _setup_collision_layers() -> void:
	"""T3.04 - Cấu hình Collision Layer/Mask theo player_id."""
	collision_layer = 1 << player_id # Layer 2 hoặc 3
	
	# HazardDetector bắt Layer 4 (Neutral) + Hazard của player kia
	var hazard_mask: int = (1 << 3) | (1 << 5 if player_id == 1 else 1 << 4)
	
	hazard_detector.collision_layer = 0
	hazard_detector.collision_mask = hazard_mask
	
	# World_Terrain + Pushable_Blocks (T6.09) + HeadPlatforms (T4.03).
	# HeadPlatform ở layer riêng (9) để người kia ĐỨNG lên được mà 2 thân
	# player vẫn đi xuyên qua nhau (không đẩy/khoá nhau khi co-op).
	collision_mask = (1 << 0) | (1 << 7) | (1 << 8)
	head_platform.collision_layer = 1 << 8
	head_platform.collision_mask = 1 << (2 if player_id == 1 else 1)


func _setup_state_machine() -> void:
	"""Khởi tạo State Machine (T4.01). State đầu tiên do switch_form() tạo,
	nếu tạo thêm ở đây thì _ready() init FSM 2 lần (enter/exit thừa ngay frame đầu)."""
	_state_machine = StateMachine.new()


func get_move_axis() -> float:
	return Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)


func is_jump_pressed() -> bool:
	return Input.is_action_pressed("p%d_jump" % player_id)


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_jump" % player_id)


func is_action_pressed() -> bool:
	return Input.is_action_pressed("p%d_action" % player_id)


func is_action_just_pressed() -> bool:
	"""T4.07 - Dash chỉ kích hoạt khi BẤM action, không kích lại khi giữ phím."""
	return Input.is_action_just_pressed("p%d_action" % player_id)


func switch_form(new_form_name: StringName) -> void:
	"""T4.08 - Chuyển đổi form với hiệu ứng và state update."""
	# Chuẩn hoá + whitelist: tên dạng lạ (sai chính tả trong level/portal) trước đây
	# khiến state cũ bị exit() nhưng current_state vẫn trỏ vào nó -> FSM chết im lặng.
	var requested := StringName(str(new_form_name).to_upper())
	if not FORM_NAMES.has(requested):
		push_warning("switch_form: form '%s' khong hop le, fallback CUBE" % str(new_form_name))
		requested = &"CUBE"
	form = requested
	if _state_machine == null:
		_state_machine = StateMachine.new()
	
	# Exit old state
	if current_state != null:
		current_state.exit()
	
	# Create new state based on form
	match form:
		"CUBE":
			current_state = _state_machine.get_cube_state(self, current_state)
		"SHIP":
			current_state = _state_machine.get_ship_state(self, current_state)
		"UFO":
			current_state = _state_machine.get_ufo_state(self, current_state)
		"DASH":
			current_state = _state_machine.get_dash_state(self, current_state)
	
	# Update visuals with effect
	_update_form_visibility()
	if visual_controller.has_method("switch_form"):
		visual_controller.call("switch_form", form)
	_sync_skin_rotation()
	_update_visual()
	show_transformation_effect()
	
	# Signal form change
	Events.player_form_changed.emit(player_id, form)


func set_gravity_direction(direction: int) -> void:
	gravity_direction = 1 if direction >= 0 else -1
	up_direction = Vector2.UP if gravity_direction == 1 else Vector2.DOWN
	_update_head_platform()
	_update_skin_animation()


## T4.03 - HeadPlatform luôn nằm phía "đầu" theo trọng lực hiện tại và một chiều
## đúng hướng để người kia đứng lên (lật 180° shape khi đảo trọng lực).
func _update_head_platform() -> void:
	if head_platform == null:
		return
	head_platform.position = Vector2(0.0, -25.0 * float(gravity_direction))
	var shape := head_platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.rotation = 0.0 if gravity_direction == 1 else PI
	var rider := head_platform.get_node_or_null("RiderDetector/CollisionShape2D") as CollisionShape2D
	if rider != null:
		rider.position = Vector2(0.0, -5.0 * float(gravity_direction))
		rider.rotation = 0.0 if gravity_direction == 1 else PI

func set_control_locked(locked: bool) -> void:
	control_locked = locked
	# T6.09: đang đẩy khối mà bị khoá (chết/thắng) thì ngắt lực đẩy ngay, nếu không
	# khối vẫn bị `constant_force` đẩy mãi trong lúc player đã bị vô hiệu hoá.
	if locked:
		_release_pushed_blocks()


func _release_pushed_blocks() -> void:
	for body in _last_push_targets:
		if is_instance_valid(body):
			_push_box(body, 0.0)
	_last_push_targets = []
	if _forced_push_target != null and is_instance_valid(_forced_push_target):
		_push_box(_forced_push_target, 0.0)
	_forced_push_target = null


func _physics_process(delta: float) -> void:
	if control_locked:
		velocity = Vector2.ZERO
		ground_sparks.set_active(false)
		return
	# Coyote Time & Jump Buffer (T3.05)
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	
	if is_jump_just_pressed():
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	
	# Handle jump input based on form (cho Cube/UFO/Dash)
	_handle_input_logic()
	
	# Horizontal movement (base)
	var axis := get_move_axis()
	if axis > 0.01:
		last_facing_dir = 1
	elif axis < -0.01:
		last_facing_dir = -1
	
	# Update state physics (Ship/UFO/Dash handle their own vertical movement)
	if current_state != null:
		current_state.physics_update(delta)
		current_state.update_visuals(delta)
		if form == &"DASH" and is_on_floor():
			var dash_state := current_state as DashState
			if dash_state != null and not dash_state.is_dashing:
				dash_state.recharge_dash()
	
	_apply_base_gravity(delta)
	
	move_and_slide()
	if head_platform != null:
		head_platform.position = Vector2(0.0, -25.0 * float(gravity_direction))
	_push_blocks()
	_enforce_vertical_bounds()
	if motion_trail != null:
		motion_trail.set_width_for_form(form)
	if ground_sparks != null:
		ground_sparks.set_active(form == &"CUBE" and is_on_floor() and absf(velocity.x) > 20.0)
	_update_skin_animation()


func set_bounds(top_y: float, bottom_y: float) -> void:
	ceiling_y = top_y
	floor_kill_y = bottom_y
	enforce_vertical_bounds = true


func _enforce_vertical_bounds() -> void:
	if not enforce_vertical_bounds or control_locked:
		return
	if gravity_direction == 1:
		if global_position.y < ceiling_y:
			global_position.y = ceiling_y
			if velocity.y < 0.0:
				velocity.y = 0.0
		elif global_position.y > floor_kill_y:
			_report_hazard_death(self)
	else:
		if global_position.y > floor_kill_y:
			global_position.y = floor_kill_y
			if velocity.y > 0.0:
				velocity.y = 0.0
		elif global_position.y < ceiling_y:
			_report_hazard_death(self)



func _push_blocks() -> void:
	"""T6.09 - Cube day khoi Pushable_Blocks (layer 8) khi ap sat vao."""
	var dir := signf(velocity.x)
	var targets: Array = []
	if dir != 0.0:
		for i in range(get_slide_collision_count()):
			var body := get_slide_collision(i).get_collider()
			if body is RigidBody2D and (body.collision_layer & (1 << 7)) != 0:
				targets.append(body)
	for body in _last_push_targets:
		if is_instance_valid(body) and not targets.has(body):
			_push_box(body, 0.0)
	for body in targets:
		_push_box(body, dir)
	_last_push_targets = targets


func _push_box(body: RigidBody2D, dir: float) -> void:
	"""T6.09 - gan luc day lien tuc khi ap sat (0 = ngat)."""
	body.constant_force = Vector2(dir * PUSH_FORCE, 0.0)
	if dir != 0.0:
		_forced_push_target = body
	elif _forced_push_target == body:
		_forced_push_target = null


func _apply_base_gravity(delta: float) -> void:
	# Ship and UFO own their vertical gravity; active Dash locks it.
	var dash_active := form == &"DASH" and current_state is DashState and (current_state as DashState).is_dashing
	if not is_on_floor() and form != &"SHIP" and form != &"UFO" and not dash_active:
		velocity.y += BASE_GRAVITY * gravity_direction * delta


func _on_hazard_area_entered(area: Area2D) -> void:
	_report_hazard_death(area)


func _on_hazard_body_entered(body: Node2D) -> void:
	_report_hazard_death(body)


func _report_hazard_death(_hazard: Node2D) -> void:
	if control_locked or _death_reported:
		return
	_death_reported = true
	death_requested.emit(player_id, global_position)


func reset_death_state() -> void:
	_death_reported = false


func _handle_input_logic() -> void:
	"""Xử lý đầu vào riêng cho từng dạng (T4.02-T4.07)."""
	var jump_pressed: bool = is_jump_pressed()
	var jump_just_pressed: bool = is_jump_just_pressed()
	
	match form:
		"CUBE":
			# T4.02: CubeState.physics_update xử lý nhảy (một nguồn duy nhất).
			pass
		
		"SHIP":
			# T4.04: Bay lên khi giữ phím (handled in ship_state.physics_update)
			pass
			
		"UFO":
			# T4.06: Bấm từng nhịp (handled in ufo_state.physics_update)
			pass
			
		"DASH":
			# T4.07: Kích hoạt bằng jump hoặc action.
			# Khi ở trên sàn: Jump để nhảy bình thường, Action để Dash.
			# Khi ở trên không: Jump hoặc Action đều kích hoạt Dash (air dash).
			if is_on_floor() or _coyote_timer > 0.0:
				if jump_pressed:
					velocity.y = -JUMP_VELOCITY * gravity_direction
					_jump_buffer_timer = 0.0
					_coyote_timer = 0.0
				elif is_action_just_pressed() and _can_activate_dash():
					var dash_state = _get_dash_state()
					if dash_state != null:
						dash_state.activate_dash(last_facing_dir)
			else:
				if jump_just_pressed and _can_activate_dash():
					var dash_state = _get_dash_state()
					if dash_state != null:
						dash_state.activate_dash(last_facing_dir)
		
		_:
			# Default fallback (giong CUBE: phai cham dat/coyote)
			if jump_pressed and (is_on_floor() or _coyote_timer > 0.0):
				velocity.y = -JUMP_VELOCITY * gravity_direction
				_jump_buffer_timer = 0.0
				_coyote_timer = 0.0


func _can_activate_dash() -> bool:
	"""Kiểm tra có thể kích hoạt Dash hay không."""
	var dash_state = _get_dash_state()
	return dash_state != null and dash_state.dash_ready


func _get_dash_state() -> DashState:
	"""Get Dash state nếu đang ở dạng DASH."""
	if form == "DASH" and current_state != null:
		return current_state as DashState
	return null


func _update_visual() -> void:
	"""Cập nhật màu sắc theo player_id và form."""
	var fill_poly: Polygon2D = visual_root.get_node_or_null("FillPolygon") as Polygon2D
	var outline_line: Line2D = visual_root.get_node_or_null("OutlineLine") as Line2D
	
	var color: Color = _get_color_for_form()
	
	var has_skin_active: bool = _skin_visual != null and _skin_visual.visible
	if fill_poly != null:
		# Khi skin (Bird/Frog/Bunny) dang hien thi, an khoi bao vuong/hitbox de sprite dep, ro rang
		fill_poly.visible = not has_skin_active
		fill_poly.color = Color(color, 0.70)
	if outline_line != null:
		# An vien hop bao quanh nhan vat khi co skin
		outline_line.visible = not has_skin_active
		outline_line.default_color = color
		outline_line.width = 3.0


func _setup_skin_visual() -> void:
	if _skin_visual != null and is_instance_valid(_skin_visual):
		_skin_visual.queue_free()
		_skin_visual = null
	var old := visual_root.get_node_or_null("SkinVisual")
	if old != null:
		old.free()
	var skin_name := skin.to_lower()
	if skin_name == "none" or not Skins.all_skins().has(skin_name):
		skin = "NONE"
		return
	_skin_visual = Skins.make_skin_visual(skin_name, "idle", 8.0, 48.0)
	_skin_visual.name = "SkinVisual"
	_skin_visual.z_index = 2
	visual_root.add_child(_skin_visual)
	_skin_body = _skin_visual.get_node_or_null("Body") as AnimatedSprite2D
	if _skin_body == null:
		_skin_visual.queue_free()
		_skin_visual = null
		return
	_skin_body.z_index = 2
	_update_visual()
	_set_skin_animation("idle")


func _skin_state_for_animation() -> String:
	var skin_name := skin.to_lower()
	if gravity_direction < 0 and Skins.has_state(skin_name, "flip"):
		return "flip"
	if not is_on_floor() and Skins.has_state(skin_name, "jump"):
		return "jump"
	if absf(velocity.x) > 35.0:
		if skin_name == Skins.BIRD:
			return "run_left" if velocity.x < 0.0 else "run_right"
		if Skins.has_state(skin_name, "run"):
			return "run"
	return "idle"


func _set_skin_animation(state: String) -> void:
	if _skin_body == null or state == _skin_animation:
		return
	var frames_list: Array = Skins.state_frames(skin.to_lower(), state)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 8.0)
	for texture in frames_list:
		frames.add_frame("default", texture, 1.0)
	_skin_body.sprite_frames = frames
	_skin_animation = state
	if frames.get_frame_count("default") > 0:
		_skin_body.play("default")
	else:
		_skin_body.stop()


func _update_skin_animation() -> void:
	# Neon polygon lat theo huong di chuyen truoc (mui Dash/mui tau chi dung
	# huong) — doc lap skin. Giu tri tuyet doi cua tween bien hinh, chi ep dau.
	visual_root.scale.x = float(last_facing_dir) * absf(visual_root.scale.x)
	if _skin_body == null:
		return
	_set_skin_animation(_skin_state_for_animation())
	if _skin_animation == "run" and skin.to_lower() != Skins.BIRD:
		_skin_body.flip_h = velocity.x < -35.0
	else:
		_skin_body.flip_h = false
	# Skin khong co frame "flip" (bunny) van phai lat ngua khi dao trong luc.
	_skin_body.flip_v = gravity_direction < 0 and not Skins.has_state(skin.to_lower(), "flip")
	# Cube rotation communicates gameplay in the neon outline; keep the
	# authored character upright so it stays readable during jumps.
	_sync_skin_rotation()


func _sync_skin_rotation() -> void:
	if _skin_visual == null or not is_instance_valid(_skin_visual):
		return
	_skin_visual.visible = (form == &"CUBE")
	if not _skin_visual.visible:
		return
	# Giu dau nhan vat (skin chim/ech/tho) luon luon huong len tren trong khong gian the gioi,
	# trong khi visual_root (khoi Cube) van xoay tron 360 do kieu Geometry Dash ban dau.
	var facing: float = float(last_facing_dir if last_facing_dir != 0 else 1)
	var target_angle: float = 0.0 if gravity_direction > 0 else PI
	var target_scale := Vector2(facing if gravity_direction > 0 else -facing, 1.0)
	_skin_visual.global_transform = Transform2D(target_angle, target_scale, 0.0, visual_root.global_position)
	_update_visual()

func _update_form_visibility() -> void:
	var forms := visual_root.get_node_or_null("FormVisuals")
	if forms != null:
		for child in forms.get_children():
			child.visible = str(child.name).to_upper().begins_with(str(form))
	var dash_indicator: CanvasItem = visual_root.get_node_or_null("DashIndicator") as CanvasItem
	if dash_indicator != null:
		dash_indicator.visible = (form == &"DASH")


func _get_color_for_form() -> Color:
	var base_color: Color = Palette.COLOR_P1_CYAN if player_id == 1 else Palette.COLOR_P2_ORANGE
	
	# Ship/UFO/Dash lấy hue từ palette; Cube giữ màu theo player_id.
	match form:
		"SHIP":
			return Palette.COLOR_FORM_SHIP
		"UFO":
			return Palette.COLOR_FORM_UFO
		"DASH":
			return Palette.COLOR_FORM_DASH
		_:
			return base_color


func show_transformation_effect() -> void:
	"""T4.08 - Hiệu ứng chớp sáng khi đổi dạng (ủy quyền cho VisualRoot)."""
	if visual_controller != null and visual_controller.has_method("show_transformation_effect"):
		visual_controller.call("show_transformation_effect")
		return
	var dir: float = float(last_facing_dir if last_facing_dir != 0 else 1)
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(visual_root, "scale", Vector2(1.3 * dir, 1.3), 0.075)
	tween.tween_property(visual_root, "scale", Vector2(dir, 1.0), 0.075)
