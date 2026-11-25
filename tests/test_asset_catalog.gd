extends "res://tests/gdx_test.gd"

const Assets = preload("res://resources/potential_assets.gd")


## Dùng resource import thay vì Image.load_from_file(): cách cũ chỉ đọc file
## thô, không đóng gói được khi export (Godot cảnh báo lúc chạy test).
func _image(path: String) -> Image:
	var tex := load(path) as Texture2D
	return tex.get_image() if tex != null else null

func test_catalog_paths_exist() -> void:
	assert_true(Assets.is_ready_for_visual_import(), "potential asset catalog files exist")
	assert_true(FileAccess.file_exists(Assets.character_sheet()), "character sheet path exists")
	assert_eq(Assets.backgrounds().size(), 2, "catalog has two backgrounds")
	assert_eq(Assets.sprite_sheets().size(), 3, "catalog has three permitted sprite sheets")
	for path in Assets.all_paths():
		assert_true(path.begins_with("res://potential_Assets/"), "asset remains behind catalog boundary")

func test_catalog_dimensions() -> void:
	var sheet := _image(Assets.character_sheet())
	assert_true(sheet != null and not sheet.is_empty(), "character sheet loads")
	if sheet != null and not sheet.is_empty():
		assert_eq(sheet.get_width(), 252, "character sheet width")
		assert_eq(sheet.get_height(), 408, "character sheet height")
	var bright := _image(Assets.BACKGROUND_BRIGHT)
	var forest := _image(Assets.BACKGROUND_FOREST)
	assert_true(bright != null and not bright.is_empty(), "bright background loads")
	assert_true(forest != null and not forest.is_empty(), "forest background loads")
	if bright != null and not bright.is_empty():
		assert_eq(Vector2i(bright.get_width(), bright.get_height()), Vector2i(735, 412), "bright background dimensions")
	if forest != null and not forest.is_empty():
		assert_eq(Vector2i(forest.get_width(), forest.get_height()), Vector2i(1199, 648), "forest background dimensions")
	var bunny := _image(Assets.BUNNY_SHEET)
	var frog := _image(Assets.FROG_SHEET)
	assert_true(bunny != null and not bunny.is_empty(), "bunny sheet loads")
	assert_true(frog != null and not frog.is_empty(), "frog sheet loads")
	if bunny != null and not bunny.is_empty():
		assert_eq(Vector2i(bunny.get_width(), bunny.get_height()), Vector2i(288, 576), "bunny sheet dimensions")
	if frog != null and not frog.is_empty():
		assert_eq(Vector2i(frog.get_width(), frog.get_height()), Vector2i(640, 320), "frog sheet dimensions")

func test_sheet_metadata() -> void:
	var metadata: Dictionary = Assets.sheet_metadata()
	assert_eq(metadata[Assets.BUNNY_SHEET]["frame_size"], Vector2i(72, 72), "bunny frame 72x72")
	assert_true(metadata[Assets.BUNNY_SHEET]["has_alpha"], "bunny sheet has alpha")
	assert_eq(metadata[Assets.FROG_SHEET]["frame_size"], Vector2i(80, 80), "frog frame 80x80")
	assert_true(not metadata[Assets.FROG_SHEET]["has_alpha"], "frog sheet needs background cleanup")
