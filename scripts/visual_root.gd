class_name VisualRootController
extends Node2D


## T2.03 & T4.08 — Controller cho VisualRoot node.
## Quản lý switching giữa các dạng (Cube/Ship/UFO/Dash) và hiệu ứng biến hình.


func switch_form(form: StringName) -> void:
	"""Chuyển đổi visual theo form (T4.08)."""
	var fill_poly: Polygon2D = get_node_or_null("FillPolygon") as Polygon2D
	var outline_line: Line2D = get_node_or_null("OutlineLine") as Line2D
	
	if form == "CUBE":
		_set_shape("square_chamfered", fill_poly, outline_line)
		_set_color(Color(0, 0.9, 1.0)) # Cyan P1 default
	
	elif form == "SHIP":
		_set_shape("ship_shape", fill_poly, outline_line)
		_set_color(Color(0, 1.0, 0.9)) # Teal Ship
		
	elif form == "UFO":
		_set_shape("ufo_disc", fill_poly, outline_line)
		_set_color(Color(1.0, 0.6, 0.0)) # Orange UFO
		
	elif form == "DASH":
		_set_shape("dash_arrow", fill_poly, outline_line)
		_set_color(Color(1.0, 0.0, 1.0)) # Magenta Dash


func _set_shape(shape_fn: String, fill_poly: Polygon2D, outline_line: Line2D) -> void:
	var points: PackedVector2Array
	match shape_fn:
		"square_chamfered":
			points = GdxShapes.square_chamfered()
		"ship_shape":
			points = GdxShapes.ship_shape()
		"ufo_disc":
			points = GdxShapes.ufo_disc()
		"dash_arrow":
			points = GdxShapes.dash_arrow()
	
	if fill_poly != null:
		fill_poly.polygon = points
	if outline_line != null:
		var closed: PackedVector2Array = PackedVector2Array(points)
		closed.append(points[0])
		outline_line.points = closed


func _set_color(base_color: Color) -> void:
	var fill_poly: Polygon2D = get_node_or_null("FillPolygon") as Polygon2D
	var outline_line: Line2D = get_node_or_null("OutlineLine") as Line2D
	
	if fill_poly != null:
		fill_poly.color = Color(base_color, 0.70)
	if outline_line != null:
		outline_line.default_color = base_color


func show_transformation_effect() -> void:
	"""Hiệu ứng chớp sáng khi đổi dạng (T4.08): scale từ 1.3 về 1.0 trong 0.15s."""
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_callback(func(): scale = Vector2.ONE)
