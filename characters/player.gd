class_name GdxPlayer
extends CharacterBody2D


## T3.01-T3.06 + T4.01-T4.08 — Player hoàn chỉnh với FSM cho 4 dạng biến hình.
## Quản lý trạng thái: Cube / Ship / UFO / Dash với transition mượt.


const Shapes = preload("res://scripts/procedural_shapes.gd")
const Palette = preload("res://resources/color_palette.gd")
const BASE_GRAVITY: float = 1800.0
const MOVE_SPEED: float = 420.0
const MOVE_ACCEL: float = 4000.0
const JUMP_VELOCITY: float = 650.0
const COYOTE_TIME: float = 0.08
const JUMP_BUFFER_TIME: float = 0.10


@export_range(1, 2) var player_id: int = 1
@export var gravity_direction: int = 1
var form: StringName = &"CUBE"

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


func _ready() -> void:
	player_id = clampi(player_id, 1, 2)
	_setup_collision_layers()
	_setup_state_machine()
	
	up_direction = Vector2.UP if gravity_direction == 1 else Vector2.DOWN
	
	switch_form(&"CUBE")


func _setup_collision_layers() -> void:
	"""T3.04 - Cấu hình Collision Layer/Mask theo player_id."""
	collision_layer = 1 << player_id # Layer 2 hoặc 3
	
	# HazardDetector bắt Layer 4 (Neutral) + Hazard của player kia
	var hazard_mask: int = (1 << 3) | (1 << 5 if player_id == 1 else 1 << 4)
	
	hazard_detector.collision_layer = 0
	hazard_detector.collision_mask = hazard_mask
	
	collision_mask = 1 << 0


func _setup_state_machine() -> void:
	"""Khởi tạo State Machine và attach vào node (T4.01)."""
	_state_machine = StateMachine.new()
	current_state = _state_machine.get_cube_state(self, null)


func get_move_axis() -> float:
	return Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)


func is_jump_pressed() -> bool:
	return Input.is_action_pressed("p%d_jump" % player_id)


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("p%d_jump" % player_id)


func is_action_pressed() -> bool:
	return Input.is_action_pressed("p%d_action" % player_id)


func switch_form(new_form_name: StringName) -> void:
	"""T4.08 - Chuyển đổi form với hiệu ứng và state update."""
	form = new_form_name.to_upper()
	
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
	
	# Enter new state
	if current_state != null:
		current_state.enter(self, null)
	
	# Update visuals with effect
	_update_visual()
	show_transformation_effect()
	
	# Signal form change
	Events.player_form_changed.emit(player_id, form)


func set_gravity_direction(direction: int) -> void:
	gravity_direction = 1 if direction >= 0 else -1
	up_direction = Vector2.UP if gravity_direction == 1 else Vector2.DOWN


func _physics_process(delta: float) -> void:
	# Coyote Time & Jump Buffer (T3.05)
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	
	if is_jump_just_pressed():
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	
	# Handle jump input based on form
	_handle_input_logic()
	
	# Update state physics
	if current_state != null:
		current_state.physics_update(delta)
	
	# Horizontal movement (base)
	var axis := get_move_axis()
	last_facing_dir = 1 if axis >= 0 else -1 if axis < 0 else last_facing_dir
	
	gravity_update(delta)
	move_and_slide()


func _handle_input_logic() -> void:
	"""Xử lý đầu vào riêng cho từng dạng (T4.02-T4.07)."""
	var jump_pressed: bool = is_jump_pressed()
	var jump_just_pressed: bool = is_jump_just_pressed()
	
	match form:
		"CUBE":
			# T4.02: Nhảy giữ phím (GD-style)
			if jump_pressed and (_jump_buffer_timer > 0.0 or _coyote_timer > 0.0):
				velocity.y = -JUMP_VELOCITY * gravity_direction
				_jump_buffer_timer = 0.0
				_coyote_timer = 0.0
		
		"SHIP":
			# T4.04: Bay lên khi giữ phím (handled in ship_state.physics_update)
			pass
			
		"UFO":
			# T4.06: Bấm từng nhịp (handled in ufo_state.physics_update)
			pass
			
		"DASH":
			# T4.07: Kích hoạt dash khi nhấn nhảy trên không
			if jump_just_pressed and not is_on_floor() and _can_activate_dash():
				var dash_state = _get_dash_state()
				if dash_state != null:
					dash_state.activate_dash(last_facing_dir)
		
		_:
			# Default fallback
			if jump_pressed and (_jump_buffer_timer > 0.0 or _coyote_timer > 0.0):
				velocity.y = -JUMP_VELOCITY * gravity_direction


func _can_activate_dash() -> bool:
	"""Kiểm tra có thể kích hoạt Dash hay không."""
	var dash_state = _get_dash_state()
	return dash_state != null and dash_state.dash_ready


func _get_dash_state() -> DashState:
	"""Get Dash state nếu đang ở dạng DASH."""
	if form == "DASH" and current_state != null:
		return current_state as DashState
	return null


func gravity_update(delta: float) -> void:
	"""Base gravity physics (không override trong ship/ufo/dash)."""
	if not is_on_floor():
		velocity.y += BASE_GRAVITY * gravity_direction * delta


func _update_visual() -> void:
	"""Cập nhật màu sắc theo player_id và form."""
	var fill_poly: Polygon2D = visual_root.get_node_or_null("FillPolygon") as Polygon2D
	var outline_line: Line2D = visual_root.get_node_or_null("OutlineLine") as Line2D
	
	var color: Color = _get_color_for_form()
	
	if fill_poly != null:
		fill_poly.color = Color(color, 0.70)
	if outline_line != null:
		outline_line.default_color = color


func _get_color_for_form() -> Color:
	var base_color: Color = Palette.COLOR_P1_CYAN if player_id == 1 else Palette.COLOR_P2_ORANGE
	
	match form:
		"CUBE":
			return base_color
		"SHIP":
			return Color(base_color.r, 1.0, base_color.b) # Teal variant
		"UFO":
			return Color(1.0, 0.6, 0.0) # Orange UFO
		"DASH":
			return Color(1.0, 0.0, 1.0) # Magenta Dash
		_:
			return base_color


func show_transformation_effect() -> void:
	"""T4.08 - Hiệu ứng chớp sáng khi đổi dạng."""
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(visual_root, "scale", Vector2(1.3, 1.3), 0.10)
	tween.tween_callback(func(): visual_root.scale = Vector2.ONE)
