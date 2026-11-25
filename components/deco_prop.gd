@tool
class_name DecoProp
extends Node2D

## Purely visual decorative prop (no collision) for enriching level atmosphere.

@export_enum("PYLON", "CRYSTALS", "FOLIAGE", "VINE", "TERMINAL", "ARROW") var prop_type: int = 0:
	set(value):
		prop_type = value
		_apply_prop()

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_apply_prop()

const PROP_TEXTURES := {
	0: preload("res://assets/sprites/deco_pylon.png"),
	1: preload("res://assets/sprites/deco_crystals.png"),
	2: preload("res://assets/sprites/deco_foliage.png"),
	3: preload("res://assets/sprites/deco_hanging_vines.png"),
	4: preload("res://assets/sprites/deco_terminal.png"),
	5: preload("res://assets/sprites/deco_arrow_sign.png"),
}

# Offset sprite so prop bottom/top aligns naturally at anchor (0,0) -> e.g. ground y=432 or ceiling y=96
const PROP_OFFSETS := {
	0: Vector2(0, -48),  # PYLON (48x96): base sits at y=0
	1: Vector2(0, -24),  # CRYSTALS (48x48): base sits at y=0
	2: Vector2(0, -16),  # FOLIAGE (48x32): base sits at y=0
	3: Vector2(0, 32),   # VINE (48x64): top hangs from y=0
	4: Vector2(0, -32),  # TERMINAL (48x64): base sits at y=0
	5: Vector2(0, -24),  # ARROW (48x48): base sits at y=0
}


func _ready() -> void:
	_apply_prop()


func _apply_prop() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	spr.texture = PROP_TEXTURES.get(prop_type, PROP_TEXTURES[0])
	spr.position = PROP_OFFSETS.get(prop_type, Vector2.ZERO)
	spr.flip_h = flip_h
