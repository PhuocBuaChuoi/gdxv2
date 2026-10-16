class_name SpikeHazard
extends Area2D

## T6.05 — Gai & Bẫy Phân Cực Màu: tự gán đúng CollisionLayer theo loại.
## NEUTRAL giết cả 2 · CYAN_SAFE_P1 để P1 đi qua (P2 chết) · ORANGE_SAFE_P2
## để P2 đi qua (P1 chết). HazardDetector của player tự phát hiện (mask 40/24).

@export_enum("NEUTRAL", "CYAN_SAFE_P1", "ORANGE_SAFE_P2") var hazard_type: int = 0:
	set(value):
		hazard_type = value
		_apply_layer_and_color()

const HAZARD_LAYERS := {0: 4, 1: 5, 2: 6}
const HAZARD_COLORS := {
	0: Color(1, 0.3, 0.3, 0.95),
	1: Color(0.2, 0.9, 1, 0.95),
	2: Color(1, 0.6, 0.1, 0.95),
}


func _ready() -> void:
	_apply_layer_and_color()


func _apply_layer_and_color() -> void:
	collision_layer = 1 << (int(HAZARD_LAYERS.get(hazard_type, 4)) - 1)
	var col: Color = HAZARD_COLORS.get(hazard_type, Color.WHITE)
	var spikes := get_node_or_null("Spikes") as Polygon2D
	if spikes != null:
		spikes.color = col
	var outline := get_node_or_null("SpikeOutline") as Line2D
	if outline != null:
		outline.default_color = Color(col.r, col.g, col.b, 1.0)

