extends "res://tests/gdx_test.gd"

## Khóa spec Giai đoạn 2 (T2.01–T2.06: Neon VFX + procedural shapes).

const Shapes = preload("res://scripts/procedural_shapes.gd")


func test_shape_point_counts() -> void:
	assert_eq(Shapes.square_chamfered().size(), 8, "T2.02 vuong vat 8 diem")
	assert_eq(Shapes.ship_shape().size(), 5, "T2.02 tau 5 diem")
	assert_eq(Shapes.ufo_disc().size(), 12, "T2.02 ufo 12 diem")
	assert_eq(Shapes.dash_arrow().size(), 6, "T2.02 dash 6 diem")
	assert_eq(Shapes.spike_triangle().size(), 3, "T2.02 gai 3 diem")
	assert_eq(Shapes.circle_points(10.0, 8).size(), 9, "T2.02 tron 8+1 diem (khep kin)")


func test_shapes_centered() -> void:
	# Pivot xoay = tâm bounding-box (đúng cho Cube xoay, Ship nghiêng mũi).
	for pts in [Shapes.square_chamfered(), Shapes.ship_shape(), Shapes.dash_arrow(), Shapes.spike_triangle()]:
		var arr: PackedVector2Array = pts
		var mn: Vector2 = arr[0]
		var mx: Vector2 = arr[0]
		for p in arr:
			mn = mn.min(p)
			mx = mx.max(p)
		var c: Vector2 = (mn + mx) * 0.5
		assert_near(c.x, 0.0, 0.01, "T2.02 hinh can tam bbox x")
		assert_near(c.y, 0.0, 0.01, "T2.02 hinh can tam bbox y")


func test_make_visual_structure() -> void:
	var pts: PackedVector2Array = Shapes.spike_triangle()
	var root: Node2D = Shapes.make_visual(pts, Color(0, 0, 0, 0.7), Color.WHITE)
	assert_eq(root.name, "VisualRoot", "T2.03 ten VisualRoot")
	var fill: Polygon2D = root.get_node_or_null("FillPolygon") as Polygon2D
	var line: Line2D = root.get_node_or_null("OutlineLine") as Line2D
	assert_true(fill != null and line != null, "T2.03 co FillPolygon + OutlineLine")
	assert_eq(fill.polygon, pts, "T2.03 fill dung hinh")
	assert_eq(line.width, 3.0, "T2.03 vien 3.0")
	assert_eq(line.points.size(), pts.size() + 1, "T2.03 outline khep kin")
	assert_eq(line.points[line.points.size() - 1], pts[0], "T2.03 diem cuoi = diem dau")
	root.free()


func test_environment() -> void:
	var ps: PackedScene = load("res://levels/default_world_environment.tscn") as PackedScene
	assert_true(ps != null, "T2.01 env scene load duoc")
	var we: WorldEnvironment = ps.instantiate() as WorldEnvironment
	assert_true(we != null and we.environment != null, "T2.01 co WorldEnvironment + Environment")
	var e: Environment = we.environment
	assert_eq(e.background_mode, Environment.BG_CANVAS, "T2.01 nen Canvas")
	assert_true(e.glow_enabled, "T2.01 glow bat")
	assert_near(e.glow_intensity, 0.8, 0.001, "T2.01 glow intensity 0.8")
	assert_near(e.glow_bloom, 0.2, 0.001, "T2.01 bloom 0.2")
	assert_eq(e.glow_blend_mode, Environment.GLOW_BLEND_MODE_ADDITIVE, "T2.01 blend Additive")
	we.free()


func test_death_explosion() -> void:
	var ps: PackedScene = load("res://vfx/death_explosion.tscn") as PackedScene
	assert_true(ps != null, "T2.04 explosion scene load duoc")
	var inst: Node = ps.instantiate()
	var burst: GPUParticles2D = inst.find_child("BurstParticles", true, false) as GPUParticles2D
	assert_true(burst != null, "T2.04 co BurstParticles")
	assert_true(burst.amount >= 25 and burst.amount <= 35, "T2.04 25-35 manh (got=%d)" % burst.amount)
	assert_near(burst.lifetime, 0.4, 0.001, "T2.04 lifetime 0.4s")
	assert_true(burst.one_shot, "T2.04 one_shot")
	assert_true(inst.find_child("Shockwave", true, false) is Line2D, "T2.04 co Shockwave Line2D")
	inst.free()


func test_motion_trail() -> void:
	var ps: PackedScene = load("res://vfx/motion_trail.tscn") as PackedScene
	assert_true(ps != null, "T2.05 trail scene load duoc")
	var trail: Line2D = ps.instantiate() as Line2D
	assert_true(trail != null, "T2.05 goc la Line2D")
	assert_eq(int(trail.get("max_points")), 15, "T2.05 luu 15 vi tri")
	assert_true(trail.has_method("setup"), "T2.05 co setup()")
	assert_true(trail.has_method("set_width_for_form"), "T2.05 co set_width_for_form()")
	trail.call("set_width_for_form", &"DASH")
	assert_near(trail.width, 8.0, 0.001, "T2.05 Dash day 8.0")
	trail.call("set_width_for_form", &"CUBE")
	assert_near(trail.width, 4.0, 0.001, "T2.05 Cube day 4.0")
	trail.free()


func test_ground_sparks() -> void:
	var ps: PackedScene = load("res://vfx/ground_sparks.tscn") as PackedScene
	assert_true(ps != null, "T2.06 sparks scene load duoc")
	var sparks: GPUParticles2D = ps.instantiate() as GPUParticles2D
	assert_true(sparks != null, "T2.06 goc la GPUParticles2D")
	assert_true(not sparks.emitting, "T2.06 mac dinh tat (player bat khi chay dat)")
	assert_true(sparks.amount > 0, "T2.06 amount > 0")
	sparks.set_active(true)
	assert_true(sparks.emitting, "T2.06 set_active(true) bat")
	sparks.set_active(false)
	assert_true(not sparks.emitting, "T2.06 set_active(false) tat")
	sparks.free()
