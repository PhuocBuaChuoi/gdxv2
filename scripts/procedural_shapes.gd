class_name GdxShapes
extends RefCounted

## T2.02 — Sinh mảng tọa độ procedural cho mọi hình trong game
## (vuông vát, mũi tàu, đĩa UFO, tên Dash, gai tam giác, vòng tròn).
## Mọi hình căn giữa gốc tọa độ, cỡ mặc định ~48px khớp hitbox player (T3.01).
##
## T2.03 — Khung hiển thị chuẩn cho mọi đối tượng:
##   VisualRoot (Node2D)
##   ├─ FillPolygon (Polygon2D) — màu nền/alpha
##   └─ OutlineLine (Line2D)    — viền neon width 3.0, khép kín
## Sau này thay đồ họa chỉ cần gắn Sprite2D vào VisualRoot, không đụng collision.
##
## Quy ước dùng chung: game code gọi qua `preload` (không phụ thuộc class cache
## của editor) — vd: const Shapes = preload("res://scripts/procedural_shapes.gd").


## Hình vuông vát góc (Cube): 8 điểm, thuận chiều kim đồng hồ.
static func square_chamfered(size: float = 48.0, chamfer: float = 10.0) -> PackedVector2Array:
	var h: float = size * 0.5
	var c: float = clampf(chamfer, 0.0, h)
	return PackedVector2Array([
		Vector2(-h + c, -h), Vector2(h - c, -h),
		Vector2(h, -h + c), Vector2(h, h - c),
		Vector2(h - c, h), Vector2(-h + c, h),
		Vector2(-h, h - c), Vector2(-h, -h + c),
	])


## Mũi tàu (Ship): nhọn đầu phải, thân chữ nhật — 5 điểm.
static func ship_shape(size: float = 48.0) -> PackedVector2Array:
	var h: float = size * 0.5
	return PackedVector2Array([
		Vector2(h, 0.0),
		Vector2(-h * 0.15, -h * 0.6),
		Vector2(-h, -h * 0.6),
		Vector2(-h, h * 0.6),
		Vector2(-h * 0.15, h * 0.6),
	])


## Đĩa bay UFO: ellipse ngang — 12 điểm.
static func ufo_disc(width: float = 56.0, height: float = 22.0, segments: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * width * 0.5, sin(a) * height * 0.5))
	return pts


## Mũi tên Dash: chevron ">" căn giữa bounding-box — 6 điểm.
static func dash_arrow(size: float = 48.0) -> PackedVector2Array:
	var s: float = size / 48.0
	var pts := PackedVector2Array([
		Vector2(18.0, 0.0),
		Vector2(-18.0, -16.0),
		Vector2(-18.0, -7.0),
		Vector2(-2.0, 0.0),
		Vector2(-18.0, 7.0),
		Vector2(-18.0, 16.0),
	])
	for i in range(pts.size()):
		pts[i] *= s
	return pts


## Gai tam giác cân, đáy dưới — 3 điểm.
static func spike_triangle(base: float = 48.0, height: float = 48.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-base * 0.5, height * 0.5),
		Vector2(base * 0.5, height * 0.5),
		Vector2(0.0, -height * 0.5),
	])


## Vòng tròn khép kín (nối điểm cuối về điểm đầu): segments+1 điểm.
static func circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var a: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


## Dựng khung hiển thị chuẩn T2.03 từ mảng điểm bất kỳ.
static func make_visual(points: PackedVector2Array, fill_color: Color, edge_color: Color, edge_width: float = 3.0) -> Node2D:
	var root := Node2D.new()
	root.name = "VisualRoot"
	if points.size() < 3:
		return root
	var fill_poly := Polygon2D.new()
	fill_poly.name = "FillPolygon"
	fill_poly.polygon = points
	fill_poly.color = fill_color
	var outline := Line2D.new()
	outline.name = "OutlineLine"
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	outline.points = closed
	outline.width = edge_width
	outline.default_color = edge_color
	outline.antialiased = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	root.add_child(fill_poly)
	root.add_child(outline)
	return root


## Texture vuông trắng cho GPUParticles2D (mảnh vỡ, tia lửa) — zero asset.
static func square_texture(size_px: int = 8) -> ImageTexture:
	var img := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)
