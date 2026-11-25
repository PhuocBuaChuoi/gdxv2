class_name DashState
extends PlayerFormState


## T4.07 — Dash State (Dạng Tốc độ).
## Physics: Khi nhấn nhảy trên không/mặt đất = lao vọt theo hướng di chuyển, khóa trọng lực trong 0.22s.
## Co-op: Duy nhất dạng Dash khi đang lướt mới có thể phá Tường Nứt và đẩy Khối Nặng.


const DASH_SPEED: float = 950.0
const DASH_DURATION: float = 0.22
const DASH_READY_INDICATOR_SIZE: float = 8.0
const BASE_SPEED: float = 420.0
const ACCEL: float = 4000.0


var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_ready: bool = true
var last_facing_dir: int = 1


func enter(player_ref: GdxPlayer, prev: PlayerFormState) -> void:
	super.enter(player_ref, prev)
	is_dashing = false
	dash_timer = 0.0
	# Lấy lại lượt đã tiêu thụ từ player (xóa form rồi vào lại không được hồi miễn phí).
	dash_ready = player.dash_charge_available
	last_facing_dir = player.last_facing_dir if player.last_facing_dir != 0 else 1
	if player.visual_root != null:
		player.visual_root.rotation = 0.0
	_update_dash_indicator()


func exit() -> void:
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0
	# Rời dạng Dash giữa lúc lướt: hạ tốc độ về ngưỡng đi bộ, nếu không dạng mới
	# (Cube/Ship/UFO) bị bắn đi 950 px/s thêm nhiều frame cho tới khi giảm tốc.
	if player != null:
		player.velocity.x = clampf(player.velocity.x, -BASE_SPEED, BASE_SPEED)


func physics_update(delta: float) -> void:
	var axis: float = player.get_move_axis()
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			_reset_dash()
			return
		
		# Khóa hướng trong suốt thời gian lướt.
		if last_facing_dir != 0:
			player.velocity.y = 0.0
			player.velocity.x = DASH_SPEED * float(last_facing_dir)
	else:
		# Bình thường di chuyển mượt mà (bất kể dash_ready là true hay false)
		player.velocity.x = move_toward(player.velocity.x, axis * BASE_SPEED, ACCEL * delta)


# Hàm xử lý khi kích hoạt Dash (gọi từ player.gd khi nhấn phím jump hoặc action)
func activate_dash(facing_direction: int) -> void:
	if not is_dashing and dash_ready:
		is_dashing = true
		dash_ready = false
		player.dash_charge_available = false
		dash_timer = DASH_DURATION
		last_facing_dir = facing_direction if facing_direction != 0 else player.last_facing_dir
		if last_facing_dir == 0:
			last_facing_dir = 1
		player.velocity.x = DASH_SPEED * float(last_facing_dir)
		player.velocity.y = 0.0 # Khóa trọng lực
		_update_dash_indicator()
		AudioManager.play_sfx("jump")


func _reset_dash() -> void:
	"""Reset trạng thái Dash về bình thường."""
	is_dashing = false
	dash_timer = 0.0
	dash_ready = false
	_update_dash_indicator()



func update_visuals(delta: float) -> void:
	# Hiệu ứng ánh sáng/trail động cho Dash
	# MotionTrail là node con của Player, không nằm trong VisualRoot — đường dẫn cũ
	# luôn trả null nên vệt Dash không bao giờ đổi độ dày/alpha.
	var trail_line: Line2D = player.get_node_or_null("MotionTrail") as Line2D
	if trail_line != null:
		trail_line.width = lerp(trail_line.width, 6.0 if is_dashing else 3.0, 10.0 * delta)
		trail_line.default_color.a = 0.7 + 0.3 * (1.0 if is_dashing else 0.0)


func can_break_dash_blocks() -> bool:
	return is_dashing


func is_floating() -> bool:
	return is_dashing or not player.is_on_floor()


func _update_dash_indicator() -> void:
	"""Tắt/bật đèn chỉ báo năng lượng ở tâm nhân vật."""
	# Có thể thêm node "DashIndicator" vào VisualRoot để hiển thị
	var indicator := player.visual_root.get_node_or_null("DashIndicator") as Polygon2D
	if indicator != null:
		indicator.color = Color(1, 1, 1, 1) if dash_ready else Color(0.15, 0.15, 0.2, 1)

func recharge_dash() -> void:
	dash_ready = true
	player.dash_charge_available = true
	_update_dash_indicator()


func notify_rider_contact() -> void:
	"""Carrier platform callback: touching a teammate restores one Dash charge."""
	recharge_dash()
