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
	monitoring = is_on
	_update_visual()


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, period)
	var want := ((_phase < period * duty) == start_on) or (period <= 0.0)
	if want != is_on:
		is_on = want
		monitoring = is_on
		_update_visual()
	if is_on:
		var beam := get_node_or_null("Beam") as Polygon2D
		if beam != null:
			beam.color.a = 0.42 + 0.16 * sin(_phase * 22.0)


func _apply_layer_and_color() -> void:
	collision_layer = 1 << (int(SpikeHazard.HAZARD_LAYERS.get(hazard_type, 4)) - 1)
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

