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
		_set_color(GdxPalette.COLOR_FORM_CUBE)
	
	elif form == "SHIP":
		_set_shape("ship_shape", fill_poly, outline_line)
		_set_color(GdxPalette.COLOR_FORM_SHIP)
		
	elif form == "UFO":
		_set_shape("ufo_disc", fill_poly, outline_line)
		_set_color(GdxPalette.COLOR_FORM_UFO)
		
	elif form == "DASH":
		_set_shape("dash_arrow", fill_poly, outline_line)
		_set_color(GdxPalette.COLOR_FORM_DASH)


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
	var dir: float = -1.0 if scale.x < 0.0 else 1.0
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
	# T4.08: 1.3 -> 1.0 trong TỔNG 0.15s (0.075 lên + 0.075 xuống).
	# Bản cũ tween lên 0.15s rồi gán thẳng về 1.0 nên bị giật.
	tween.tween_property(self, "scale", Vector2(1.3 * dir, 1.3), 0.075)
	tween.tween_property(self, "scale", Vector2(dir, 1.0), 0.075)
