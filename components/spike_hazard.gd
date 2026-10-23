class_name SpikeHazard
extends Area2D

## T6.05 — Gai & Bẫy Phân Cực Màu: tự gán đúng CollisionLayer theo loại.
## NEUTRAL giết cả 2 · CYAN_SAFE_P1 để P1 đi qua (P2 chết) · ORANGE_SAFE_P2
## để P2 đi qua (P1 chết). HazardDetector của player tự phát hiện (mask 40/24).
## Hỗ trợ tile_count linh hoạt (1 ô = 48px, 2 ô = 96px, 7 ô = 336px...).

@export_enum("NEUTRAL", "CYAN_SAFE_P1", "ORANGE_SAFE_P2") var hazard_type: int = 0:
	set(value):
		hazard_type = value
		_apply_layer_and_color()

@export var tile_count: int = 2:
	set(value):
		tile_count = maxi(1, value)
		_rebuild_geometry()

const HAZARD_LAYERS := {0: 4, 1: 5, 2: 6}
const HAZARD_COLORS := {
	0: Color(1, 0.3, 0.3, 0.95),
	1: Color(0.2, 0.9, 1, 0.95),
	2: Color(1, 0.6, 0.1, 0.95),
}


func _ready() -> void:
	_rebuild_geometry()
	_apply_layer_and_color()


func _rebuild_geometry() -> void:
	var total_width := float(tile_count) * 48.0
	var half_w := total_width * 0.5
	var base_y := 12.0
	var tip_y := -16.0
	
	var pts := PackedVector2Array()
	pts.append(Vector2(-half_w, base_y))
	for i in range(tile_count):
		var x_start := -half_w + float(i) * 48.0
		var x_mid := x_start + 24.0
		var x_end := x_start + 48.0
		pts.append(Vector2(x_mid, tip_y))
		pts.append(Vector2(x_end, base_y))
	
	var spikes := get_node_or_null("Spikes") as Polygon2D
	if spikes != null:
		spikes.polygon = pts
	
	var outline := get_node_or_null("SpikeOutline") as Line2D
	if outline != null:
		outline.points = pts
	
	var base_line := get_node_or_null("BaseLine") as Line2D
	if base_line != null:
		base_line.points = PackedVector2Array([Vector2(-half_w, base_y), Vector2(half_w, base_y)])
	
	var col_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null:
		if col_shape.shape is RectangleShape2D:
			# Duplicate shape if shared so instance tile_count doesn't mutate other instances
			if col_shape.shape.resource_local_to_scene == false:
				col_shape.shape = col_shape.shape.duplicate()
			(col_shape.shape as RectangleShape2D).size = Vector2(total_width, 24.0)
		col_shape.position = Vector2(0.0, -6.0)


func _apply_layer_and_color() -> void:
	collision_layer = 1 << (int(HAZARD_LAYERS.get(hazard_type, 4)) - 1)
	var col: Color = HAZARD_COLORS.get(hazard_type, Color.WHITE)
	var spikes := get_node_or_null("Spikes") as Polygon2D
	if spikes != null:
		spikes.color = Color(col.r, col.g, col.b, 0.35)
	var outline := get_node_or_null("SpikeOutline") as Line2D
	if outline != null:
		outline.default_color = Color(col.r, col.g, col.b, 1.0)
