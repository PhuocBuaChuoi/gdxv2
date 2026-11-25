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
	is_on = start_on
	_set_active(is_on)
	_update_visual()


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, period)
	var want := ((_phase < period * duty) == start_on) or (period <= 0.0)
	if want != is_on:
		is_on = want
		_set_active(is_on)
		_update_visual()
	if is_on:
		var beam := get_node_or_null("Beam") as Polygon2D
		if beam != null:
			beam.color.a = 0.42 + 0.16 * sin(_phase * 22.0)


## Bật/tắt hazard THẬT. `monitoring` chỉ điều khiển việc laser tự quét body; còn
## HazardDetector của player phát hiện area qua `monitorable` + layer. Bản cũ chỉ
## tắt `monitoring` nên tia đang TẮT vẫn giết người đi qua.
## Layer 0 khi tắt để chắc chắn cặp va chạm bị gỡ, bật lại thì detector nhận
## `area_entered` như lần đầu (kể cả khi player đang đứng sẵn trong tia).
func _set_active(on: bool) -> void:
	monitoring = on
	monitorable = on
	collision_layer = _hazard_layer() if on else 0


func _hazard_layer() -> int:
	return 1 << (int(SpikeHazard.HAZARD_LAYERS.get(hazard_type, 4)) - 1)


func _apply_layer_and_color() -> void:
	collision_layer = _hazard_layer() if is_on else 0
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

