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
	0: preload("res://assets/sprites/deco_pylon_anim.png"),
	1: preload("res://assets/sprites/deco_crystals_anim.png"),
	2: preload("res://assets/sprites/deco_foliage.png"),
	3: preload("res://assets/sprites/deco_hanging_vines_anim.png"),
	4: preload("res://assets/sprites/deco_terminal_anim.png"),
	5: preload("res://assets/sprites/deco_arrow_sign.png"),
}

const PROP_FRAMES := {
	0: 4,
	1: 4,
	2: 1,
	3: 4,
	4: 4,
	5: 1,
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

var _anim_time: float = 0.0


func _ready() -> void:
	_anim_time = fmod(absf(global_position.x) * 0.013, 4.0)
	_apply_prop()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var total_frames := int(PROP_FRAMES.get(prop_type, 1))
	if total_frames <= 1:
		return
	_anim_time += delta
	SpriteAnim.step_sheet(get_node_or_null("Sprite2D") as Sprite2D, _anim_time, 5.5, total_frames)


func _apply_prop() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr == null:
		return
	var tex: Texture2D = PROP_TEXTURES.get(prop_type, PROP_TEXTURES[0])
	var frames := int(PROP_FRAMES.get(prop_type, 1))
	SpriteAnim.setup_sheet(spr, tex, frames)
	spr.position = PROP_OFFSETS.get(prop_type, Vector2.ZERO)
	spr.flip_h = flip_h
