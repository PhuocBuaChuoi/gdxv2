extends "res://tests/gdx_test.gd"

## Bonus asset — frame sheet, tách nền trắng, Parallax2D background.
## Không sửa potential_Assets/ và potential_assets.gd (của agent khác).

const AF = preload("res://resources/asset_frames.gd")
const Catalog = preload("res://resources/potential_assets.gd")


func test_sheet_real_dimensions() -> void:
	# Khóa kích thước file gốc — file bị thay là biết ngay.
	var want: Dictionary = {
		Catalog.CHARACTER_SHEET: Vector2i(252, 408),
		Catalog.BACKGROUND_BRIGHT: Vector2i(735, 412),
		Catalog.BACKGROUND_FOREST: Vector2i(1199, 648),
		Catalog.BUNNY_SHEET: Vector2i(288, 576),
		Catalog.FROG_SHEET: Vector2i(640, 320),
	}
	for p in want.keys():
		var tex: Texture2D = load(str(p)) as Texture2D
		assert_true(tex != null, "load duoc %s" % str(p).get_file())
		if tex != null:
			assert_eq(Vector2i(tex.get_width(), tex.get_height()), want[p], "kich thuoc that %s" % str(p).get_file())


func test_frame_counts() -> void:
	assert_eq(AF.frame_count(Catalog.CHARACTER_SHEET), 12, "character 3x4=12 frame")
	assert_eq(AF.frame_count(Catalog.BUNNY_SHEET), 32, "bunny 4x8=32 frame")
	assert_eq(AF.frame_count(Catalog.FROG_SHEET), 32, "frog 8x4=32 frame")


func test_all_frames_inside_sheet() -> void:
	for sheet in Catalog.sprite_sheets():
		var tex: Texture2D = load(str(sheet)) as Texture2D
		var full := Rect2i(Vector2i.ZERO, Vector2i(tex.get_width(), tex.get_height()))
		for i in range(AF.frame_count(str(sheet))):
			var r: Rect2i = AF.frame_rect(str(sheet), i)
			assert_true(full.encloses(r), "frame %d cua %s nam trong sheet" % [i, str(sheet).get_file()])


func test_frame_texture_matches_rect() -> void:
	var r: Rect2i = AF.frame_rect(Catalog.BUNNY_SHEET, 5)
	assert_eq(r, Rect2i(Vector2i(72, 72), Vector2i(72, 72)), "bunny frame 5 dung o")
	var at: AtlasTexture = AF.frame_texture(Catalog.BUNNY_SHEET, 5)
	assert_eq(at.region, Rect2(r), "AtlasTexture region khop metadata")
	assert_true(at.atlas != null, "AtlasTexture co atlas")


func test_white_to_alpha_synthetic() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	img.fill_rect(Rect2i(1, 1, 2, 2), Color.RED)
	var out: Image = AF.white_to_alpha(img)
	assert_near(out.get_pixel(0, 0).a, 0.0, 0.001, "goc nen trang thanh alpha 0")
	assert_near(out.get_pixel(3, 3).a, 0.0, 0.001, "vien nen trang thanh alpha 0")
	assert_near(out.get_pixel(1, 1).a, 1.0, 0.001, "pixel nhan vat giu alpha")
	assert_eq(out.get_pixel(1, 1).r, 1.0, "pixel nhan vat giu mau do")


func test_white_to_alpha_real_sheet() -> void:
	var tex: Texture2D = load(Catalog.FROG_SHEET) as Texture2D
	var region: Image = tex.get_image().get_region(Rect2i(Vector2i.ZERO, Vector2i(80, 80)))
	var out: Image = AF.white_to_alpha(region)
	assert_near(out.get_pixel(0, 0).a, 0.0, 0.001, "goc frame ech tach nen")
	var keyed: ImageTexture = AF.keyed_frame(Catalog.FROG_SHEET, 0)
	assert_eq(keyed.get_width(), 80, "keyed frame rong 80")
	assert_eq(keyed.get_height(), 80, "keyed frame cao 80")


func test_hitbox_and_pivot() -> void:
	assert_eq(AF.hitbox_rect(Vector2i(80, 80), 0.125), Rect2i(10, 10, 60, 60), "hitbox co vao 1/8")
	assert_eq(AF.PIVOT_FEET, Vector2(0.5, 1.0), "pivot chan chuan")


func test_sheet_validation() -> void:
	for sheet in Catalog.sprite_sheets():
		assert_eq(AF.validate_sheet(str(sheet)), [], "metadata khop file that %s" % str(sheet).get_file())
	assert_true(AF.validate_sheet("res://khong_ton_tai.png").size() > 0, "sheet la bao loi")
	assert_true(FileAccess.file_exists("res://resources/ASSET_PROVENANCE.md"), "co ho so provenance")


func test_frame_rect_clamped() -> void:
	var last: Rect2i = AF.frame_rect(Catalog.FROG_SHEET, 31)
	assert_eq(AF.frame_rect(Catalog.FROG_SHEET, 999), last, "index qua lon kep ve frame cuoi")
	assert_eq(AF.frame_rect(Catalog.FROG_SHEET, -5), AF.frame_rect(Catalog.FROG_SHEET, 0), "index am kep ve frame 0")


func test_make_sprite_visual() -> void:
	var root: Node2D = AF.make_sprite_visual(Catalog.BUNNY_SHEET, 3)
	assert_eq(root.name, "VisualRoot", "goc VisualRoot ghep thang vao player duoc")
	var spr: Sprite2D = root.get_node_or_null("Sprite") as Sprite2D
	assert_true(spr != null and spr.texture != null, "co Sprite + texture")
	assert_true(spr.centered, "sprite can giua de pivot xoay")
	assert_eq((spr.texture as AtlasTexture).region, Rect2(AF.frame_rect(Catalog.BUNNY_SHEET, 3)), "bunny frame 3")
	assert_near(spr.scale.x * 72.0, 48.0, 0.01, "scale vua hitbox 48px")
	root.free()
	var frog_root: Node2D = AF.make_sprite_visual(Catalog.FROG_SHEET, 0)
	var frog_tex: Texture2D = (frog_root.get_node("Sprite") as Sprite2D).texture
	assert_true(frog_tex is ImageTexture, "sheet nen trang dung frame da tach nen")
	frog_root.free()


func test_fit_scale() -> void:
	assert_eq(AF.fit_scale(Vector2i(80, 80), 40.0), Vector2(0.5, 0.5), "fit 80->40 giu ti le")
	assert_eq(AF.fit_scale(Vector2i(0, 0), 40.0), Vector2.ONE, "size 0 tra ve ONE")


func test_skin_registry() -> void:
	const Skins = preload("res://resources/character_skins.gd")
	assert_eq(Skins.all_skins(), ["bird", "bunny", "frog"], "3 skins da dinh nghia")
	for skin in Skins.all_skins():
		assert_true(FileAccess.file_exists(Skins.sheet_of(str(skin))), "sheet %s ton tai" % str(skin))
		for st in ["idle", "run", "jump"]:
			var key: String = st if Skins.has_state(str(skin), st) else ("run_right" if st == "run" else st)
			assert_true(Skins.has_state(str(skin), key), "%s co state %s" % [str(skin), key])
	assert_eq(Skins.sheet_of("skin-la"), "", "skin la tra ve rong")
	assert_eq(Skins.state_frames("skin-la", "idle"), [], "skin la khong frame")


func test_skin_state_frames() -> void:
	const Skins = preload("res://resources/character_skins.gd")
	var total: int = AF.frame_count(Catalog.CHARACTER_SHEET)
	for idx in (Skins.states("bird")["run_right"] as Array):
		assert_true(int(idx) >= 0 and int(idx) < total, "bird run_right index hop le")
	assert_eq((Skins.state_frames("bird", "run_right") as Array).size(), 3, "bird run 3 frame")
	assert_eq((Skins.state_frames("frog", "idle") as Array).size(), 8, "frog idle 8 frame")
	assert_eq((Skins.state_frames("bunny", "crouch") as Array).size(), 4, "bunny crouch 4 frame")
	var frog_tex: Texture2D = (Skins.state_frames("frog", "jump") as Array)[0]
	assert_true(frog_tex is ImageTexture, "frog nen trang dung frame tach nen")
	var bunny_tex: Texture2D = (Skins.state_frames("bunny", "run") as Array)[0]
	assert_true(bunny_tex is AtlasTexture, "bunny co alpha dung Atlas truc tiep")


func test_make_skin_visual() -> void:
	const Skins = preload("res://resources/character_skins.gd")
	var root: Node2D = Skins.make_skin_visual("bunny", "jump", 10.0)
	assert_eq(root.name, "VisualRoot", "skin visual ghep vao player duoc")
	var body: AnimatedSprite2D = root.get_node_or_null("Body") as AnimatedSprite2D
	assert_true(body != null and body.is_playing(), "Body tu chay")
	assert_eq(body.sprite_frames.get_frame_count("default"), 4, "bunny jump 4 frame")
	assert_near(body.sprite_frames.get_animation_speed("default"), 10.0, 0.001, "fps theo cau hinh")
	root.free()
	var empty: Node2D = Skins.make_skin_visual("skin-la", "idle")
	assert_eq((empty.get_node("Body") as AnimatedSprite2D).sprite_frames.get_frame_count("default"), 0, "skin la khong crash")
	empty.free()


func test_row_frames() -> void:
	var row0: Array = AF.row_frames(Catalog.CHARACTER_SHEET, 0)
	assert_eq(row0.size(), 3, "character 1 hang = 3 frame")
	assert_true(row0[0] is ImageTexture, "sheet nen trang tra frame da tach nen")
	var brow: Array = AF.row_frames(Catalog.BUNNY_SHEET, 2)
	assert_eq(brow.size(), 4, "bunny 1 hang = 4 frame")
	assert_true(brow[0] is AtlasTexture, "sheet alpha tra AtlasTexture truc tiep")


func test_make_animated_visual() -> void:
	var root: Node2D = AF.make_animated_visual(Catalog.CHARACTER_SHEET, 1, 8.0)
	assert_eq(root.name, "VisualRoot", "animated goc VisualRoot ghep vao player duoc")
	var body: AnimatedSprite2D = root.get_node_or_null("Body") as AnimatedSprite2D
	assert_true(body != null, "co AnimatedSprite2D Body")
	assert_true(body.centered, "can giua de pivot xoay")
	assert_true(body.is_playing(), "tu chay animation")
	assert_eq(body.sprite_frames.get_frame_count("default"), 3, "hang character 3 frame")
	assert_near(body.scale.y * 102.0, 48.0, 0.5, "cao frame vua hitbox 48")
	assert_near(body.scale.x, body.scale.y, 0.0001, "scale giu ti le")
	root.free()


func test_all_frames_have_content() -> void:
	# Mọi frame sau khi tách nền phải có nội dung thật (3–97% đặc):
	# bắt frame trống/lệch lưới. step=3 cho nhanh mà vẫn đại diện.
	for sheet in Catalog.sprite_sheets():
		for i in range(AF.frame_count(str(sheet))):
			var keyed: ImageTexture = AF.keyed_frame(str(sheet), i)
			var r: float = AF.opaque_ratio(keyed.get_image(), 3)
			assert_true(r > 0.03 and r < 0.97, "frame %d %s co noi dung (%.2f)" % [i, str(sheet).get_file(), r])


func test_stage_background() -> void:
	var ps: PackedScene = load("res://levels/stage_background.tscn") as PackedScene
	assert_true(ps != null, "stage_background load duoc")
	var bg: Parallax2D = ps.instantiate() as Parallax2D
	assert_true(bg != null, "goc la Parallax2D (khong dung gameplay logic)")
	host_root.add_child(bg)
	var layer: ParallaxLayer = bg.get_node_or_null("FarLayer") as ParallaxLayer
	assert_true(layer != null, "co FarLayer")
	assert_true(layer.motion_scale.x <= 1.0, "nen khong troi nhanh hon camera (1.0 = khoa skybox, drift tu tao chuyen dong)")
	var spr: Sprite2D = layer.get_node_or_null("Sprite2D") as Sprite2D
	assert_true(spr.texture != null, "_ready gan texture mac dinh")
	assert_eq(spr.texture.get_width(), 2398, "mac dinh la nen rung (texture tileable = 2x anh goc)")
	bg.set("background", "BRIGHT")
	bg.call("apply_background")
	assert_eq(spr.texture.get_width(), 1470, "doi sang nen sang (texture tileable = 2x anh goc)")
	bg.set("dim", 0.5)
	bg.call("apply_background")
	assert_near(spr.modulate.r, 0.5, 0.001, "dim ha sang nen dem")
	host_root.remove_child(bg)
	bg.free()


func test_stage_background_drift_smooth() -> void:
	var bg := (load("res://levels/stage_background.tscn") as PackedScene).instantiate()
	host_root.add_child(bg)
	var x0: float = (bg as Parallax2D).scroll_offset.x
	bg.call("_process", 1.0)
	assert_true((bg as Parallax2D).scroll_offset.x > x0, "T2 drift background troi muot")
	bg.set("drift_speed", 0.0)
	var x1: float = (bg as Parallax2D).scroll_offset.x
	bg.call("_process", 1.0)
	assert_near((bg as Parallax2D).scroll_offset.x, x1, 0.001, "drift=0 dung yen")
	host_root.remove_child(bg)
	bg.free()
