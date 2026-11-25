class_name MenuDancer
extends Node2D

## T8.01 — Nhân vật tự chạy/nhảy phía sau menu.
## Luôn giữ Polygon2D "Body" để kiểm tra tương thích, đồng thời hiển thị skin pixel động.

const Skins = preload("res://resources/character_skins.gd")

@export var dancer_color: Color = Color(0, 0.9, 1.0)
@export var phase: float = 0.0
@export var speed: float = 3.2
@export var hop_height: float = 32.0
@export_enum("NONE", "BIRD", "BUNNY", "FROG") var skin_name: String = "NONE"
@export var flip_facing: bool = false

var _base_y: float = 0.0
var _t: float = 0.0
var _body: Polygon2D = null
var _skin_node: Node2D = null


func _ready() -> void:
	_base_y = position.y
	var square := PackedVector2Array([
		Vector2(-18, -26), Vector2(18, -26), Vector2(26, -18), Vector2(26, 18),
		Vector2(18, 26), Vector2(-18, 26), Vector2(-26, 18), Vector2(-26, -18)
	])
	_body = Polygon2D.new()
	_body.name = "Body"
	_body.polygon = square
	_body.color = Color(dancer_color, 0.55)
	add_child(_body)

	var outline := Line2D.new()
	outline.name = "Outline"
	outline.points = PackedVector2Array(square)
	outline.points.append(square[0])
	outline.width = 3.0
	outline.default_color = dancer_color
	add_child(outline)

	var key := skin_name.to_lower()
	if key != "none" and Skins.all_skins().has(key):
		var anim_state := "idle"
		if key == Skins.BIRD:
			anim_state = "run_left" if flip_facing else "run_right"
		_skin_node = Skins.make_skin_visual(key, anim_state, 8.0, 96.0, Color.WHITE)
		if _skin_node != null:
			var spr := _skin_node.get_node_or_null("Body") as AnimatedSprite2D
			if spr != null:
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				if flip_facing and not Skins.has_state(key, "run_left"):
					spr.flip_h = true
			add_child(_skin_node)
			_body.visible = false
			outline.visible = false


func _process(delta: float) -> void:
	_t += delta
	var cycle := _t * speed + phase
	position.y = _base_y - absf(sin(cycle)) * hop_height
	rotation = sin(cycle) * 0.08 if _skin_node != null else sin(cycle) * 0.18
