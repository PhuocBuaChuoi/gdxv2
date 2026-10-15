extends "res://tests/gdx_test.gd"

## Khóa spec Giai đoạn 2 (T2.01–T2.06: Neon VFX + procedural shapes).

const Shapes = preload("res://scripts/procedural_shapes.gd")
const Palette = preload("res://resources/color_palette.gd")


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


func test_shape_bbox_sizes() -> void:
	assert_near(_span(Shapes.square_chamfered(), true), 48.0, 0.01, "vuong rong 48")
	assert_near(_span(Shapes.square_chamfered(), false), 48.0, 0.01, "vuong cao 48")
	assert_near(_span(Shapes.spike_triangle(), true), 48.0, 0.01, "gai day 48")
	assert_near(_span(Shapes.spike_triangle(), false), 48.0, 0.01, "gai cao 48")
	assert_near(_span(Shapes.ufo_disc(), true), 56.0, 0.01, "ufo rong 56")
	assert_near(_span(Shapes.ufo_disc(), false), 22.0, 0.01, "ufo cao 22")


func _span(pts: PackedVector2Array, use_x: bool) -> float:
	var mn: float = (pts[0] as Vector2).x if use_x else (pts[0] as Vector2).y
	var mx: float = mn
	for p in pts:
		var v: float = p.x if use_x else p.y
		mn = minf(mn, v)
		mx = maxf(mx, v)
	return mx - mn


func test_circle_closed() -> void:
	var c: PackedVector2Array = Shapes.circle_points(10.0, 24)
	assert_eq(c.size(), 25, "tron 24+1 diem")
	assert_near(c[0].x, c[c.size() - 1].x, 0.0001, "tron khep kin x")
	assert_near(c[0].y, c[c.size() - 1].y, 0.0001, "tron khep kin y")


func test_make_visual_guard() -> void:
	var root: Node2D = Shapes.make_visual(PackedVector2Array([Vector2.ZERO]), Color.BLACK, Color.WHITE)
	assert_eq(root.name, "VisualRoot", "guard van co root")
	assert_true(root.get_child_count() == 0, "guard <3 diem thi khong tao fill/outline")
	root.free()


func test_make_visual_colors() -> void:
	var root: Node2D = Shapes.make_visual(Shapes.square_chamfered(), Color(1, 0, 0, 0.5), Color(0, 1, 0), 5.0)
	assert_eq((root.get_node("FillPolygon") as Polygon2D).color, Color(1, 0, 0, 0.5), "fill dung mau/alpha")
	var line: Line2D = root.get_node("OutlineLine") as Line2D
	assert_eq(line.default_color, Color(0, 1, 0), "vien dung mau")
	assert_near(line.width, 5.0, 0.001, "width tuy chinh duoc")
	root.free()


func test_square_texture() -> void:
	var tex: ImageTexture = Shapes.square_texture(8)
	assert_eq(tex.get_width(), 8, "texture particle rong 8")
	assert_eq(tex.get_height(), 8, "texture particle cao 8")


func test_environment_bg_matches_palette() -> void:
	var we: WorldEnvironment = (load("res://levels/default_world_environment.tscn") as PackedScene).instantiate() as WorldEnvironment
	assert_eq(we.environment.background_color, Palette.COLOR_BG_DARK, "env dung mau nen chuan")
	we.free()


func test_explosion_material() -> void:
	var inst: Node = (load("res://vfx/death_explosion.tscn") as PackedScene).instantiate()
	var burst: GPUParticles2D = inst.find_child("BurstParticles", true, false) as GPUParticles2D
	var mat: ParticleProcessMaterial = burst.process_material as ParticleProcessMaterial
	assert_true(mat != null, "explosion co ParticleProcessMaterial")
	assert_near(mat.spread, 180.0, 0.001, "no tung 360 do")
	assert_true(mat.initial_velocity_max >= mat.initial_velocity_min, "van toc min<=max")
	assert_true(mat.initial_velocity_min >= 150.0, "manh vang du manh (>=150)")
	inst.free()


func test_sparks_material() -> void:
	var sparks: GPUParticles2D = (load("res://vfx/ground_sparks.tscn") as PackedScene).instantiate() as GPUParticles2D
	var mat: ParticleProcessMaterial = sparks.process_material as ParticleProcessMaterial
	assert_true(mat != null, "sparks co ParticleProcessMaterial")
	assert_true(not sparks.local_coords, "sparks de lai vet khi player chay (world space)")
	sparks.free()


func test_trail_width_map() -> void:
	var trail: Line2D = (load("res://vfx/motion_trail.tscn") as PackedScene).instantiate() as Line2D
	var want: Dictionary = {&"CUBE": 4.0, &"SHIP": 6.0, &"UFO": 4.0, &"DASH": 8.0}
	for f in want.keys():
		trail.call("set_width_for_form", f)
		assert_near(trail.width, float(want[f]), 0.001, "width dang %s" % f)
	trail.call("set_width_for_form", &"UNKNOWN_FORM")
	assert_near(trail.width, 4.0, 0.001, "dang la mac dinh 4.0")
	trail.free()


func test_trail_setup_and_tracking() -> void:
	var trail: Line2D = (load("res://vfx/motion_trail.tscn") as PackedScene).instantiate() as Line2D
	host_root.add_child(trail)
	var target := Node2D.new()
	host_root.add_child(target)
	trail.call("setup", target, Color.RED)
	assert_eq(trail.get_point_count(), 0, "setup xoa vet cu")
	assert_eq(trail.default_color, Color.RED, "setup gan mau player")
	target.position = Vector2.ZERO
	for i in range(20):
		target.position += Vector2(10.0, 0.0)
		trail._physics_process(1.0 / 60.0)
	assert_eq(trail.get_point_count(), 15, "trail tran dung 15 diem sau 20 frame")
	assert_eq(trail.get_point_position(14), target.position, "diem moi nhat = vi tri target")
	assert_eq(trail.get_point_position(0), Vector2(60.0, 0.0), "diem cu nhat truot dung")
	host_root.remove_child(trail)
	host_root.remove_child(target)
	trail.free()
	target.free()


func test_explosion_play_runtime() -> void:
	var inst: Node = (load("res://vfx/death_explosion.tscn") as PackedScene).instantiate()
	host_root.add_child(inst)
	inst.call("play", Color(0.0, 0.9, 1.0))
	var burst: GPUParticles2D = inst.find_child("BurstParticles", true, false) as GPUParticles2D
	assert_true(burst.texture is ImageTexture, "play gan texture cho hat")
	assert_eq((burst.texture as ImageTexture).get_width(), 8, "texture hat 8x8")
	assert_eq(burst.modulate, Color(0.0, 0.9, 1.0), "play nhuom mau player")
	var ring: Line2D = inst.find_child("Shockwave", true, false) as Line2D
	assert_eq(ring.points.size(), 25, "shockwave co 25 diem")
	assert_eq(ring.default_color, Color(0.0, 0.9, 1.0), "shockwave cung mau player")
	host_root.remove_child(inst)
	inst.free()
