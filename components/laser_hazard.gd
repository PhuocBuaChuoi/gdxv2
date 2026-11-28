class_name LaserHazard
extends Area2D

## T6.05 — Tia Laser Phân Cực: chớp tắt theo chu kỳ (`period` giây, tỉ lệ
## BẬT = `duty`). Khi TẮT monitoring cũng tắt → đi qua an toàn. Cùng bảng
## màu/layer như SpikeHazard nên HazardDetector tự bắt.

@export_enum("NEUTRAL", "CYAN_SAFE_P1", "ORANGE_SAFE_P2") var hazard_type: int = 0:
	set(value):
		hazard_type = value
		_apply_layer_and_color()
@export_range(0.1, 10.0) var period: float = 2.0
@export_range(0.0, 1.0) var duty: float = 0.5
@export var start_on: bool = true

var is_on: bool = true
var _phase: float = 0.0


func _ready() -> void:
	_apply_layer_and_color()
	is_on = _want_on_at(0.0)
	_set_active(is_on)
	_update_visual()


func _process(delta: float) -> void:
	if period > 0.0:
		_phase = fmod(_phase + delta, period)
	else:
		_phase += delta
	var want := _want_on_at(_phase)
	if want != is_on:
		is_on = want
		_set_active(is_on)
		_update_visual()
	if is_on:
		var beam := get_node_or_null("Beam") as Polygon2D
		if beam != null:
			beam.color.a = 0.42 + 0.16 * sin(_phase * 22.0)


## Bật/tắt hazard THẬT. `monitoring` chỉ điều khiển việc laser tự quét body; còn
## HazardDetector của player phát hiện area qua layer + `monitorable`.
## Tia LUÔN ở layer hazard + `monitorable`, chỉ SHAPE bị gỡ khi TẮT. Đổi
## layer/monitorable không làm Godot dựng lại cặp area đang trùng sẵn: đo live
## (MCP, level_04) player đứng trong tia lúc bật lại vẫn sống, `get_overlapping_areas()`
## của HazardDetector rỗng dù tia BẬT/layer 8/monitorable true. Gỡ rồi ráp lại
## shape thì cặp va chạm mới được tạo lại và `area_entered` mới bắn ra.
## duty = 0 nghia la 0% thoi gian BAT -> phai luon TAT, duty = 1 -> luon BAT.
## Cong thuc cu so sanh thang voi start_on nen duty=0 + start_on=false dao
## nguoc va cho ra tia BAT vinh vien (duty=0 lai nguy hiem nhat).
func _want_on_at(phase: float) -> bool:
	if period <= 0.0:
		return start_on
	if duty <= 0.0:
		return false
	if duty >= 1.0:
		return true
	return (phase < period * duty) == start_on


func _set_active(on: bool) -> void:
	monitoring = true
	monitorable = true
	collision_layer = _hazard_layer()
	for shape in _beam_shapes():
		shape.disabled = not on


func _beam_shapes() -> Array[CollisionShape2D]:
	var out: Array[CollisionShape2D] = []
	for child in get_children():
		if child is CollisionShape2D:
			out.append(child)
	return out


func _hazard_layer() -> int:
	return 1 << (int(SpikeHazard.HAZARD_LAYERS.get(hazard_type, 4)) - 1)


func _apply_layer_and_color() -> void:
	collision_layer = _hazard_layer()
	var beam := get_node_or_null("Beam") as Polygon2D
	if beam != null:
		var c: Color = SpikeHazard.HAZARD_COLORS.get(hazard_type, Color.WHITE)
		beam.color = Color(c.r, c.g, c.b, 0.48)


func _update_visual() -> void:
	var beam := get_node_or_null("Beam") as Polygon2D
	if beam != null:
		beam.visible = is_on
	var core := get_node_or_null("CoreLine") as Line2D
	if core != null:
		core.visible = is_on

