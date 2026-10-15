extends Line2D

## T2.05 — Vệt đuôi: lưu 15 vị trí gần nhất của target mỗi physics frame,
## tự đổi độ dày theo dạng (Ship/Dash dày hơn).
## Cách dùng: đặt MotionTrail tại ORIGIN của level (không di chuyển nó),
## rồi gọi setup(player, mau_cua_player).

const WIDTH_BY_FORM: Dictionary = {
	&"CUBE": 4.0,
	&"SHIP": 6.0,
	&"UFO": 4.0,
	&"DASH": 8.0,
}

var max_points: int = 15
var _target: Node2D


func setup(target: Node2D, color: Color) -> void:
	_target = target
	default_color = color
	clear_points()


func set_width_for_form(form: StringName) -> void:
	width = float(WIDTH_BY_FORM.get(form, 4.0))


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	add_point(to_local(_target.global_position))
	while get_point_count() > max_points:
		remove_point(0)
