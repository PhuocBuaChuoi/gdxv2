extends SceneTree

## T7.01 — Build tool: sinh atlas PNG + gd_neon_tileset.tres, chạy headless.
## KHÔNG phải test (tên không bắt đầu bằng test_ nên runner bỏ qua).
## Chạy: powershell -ExecutionPolicy Bypass -File tools/build_tileset.ps1
## (import editor trước để PNG load được qua ResourceLoader).
##
## Thiết kế (grid 48px khớp hitbox player T3.01, gốc tọa độ tile ở GIỮA):
##   tile (0,0) solid      — khối đặc, collision vuông full
##   tile (1,0) edge-glow  — khối đặc viền neon, collision vuông full
##   tile (2,0) one-way     — bệ mỏng 1/4 trên, one_way, đứng xuyên từ dưới
##   tile (3,0) deco        — trang trí mờ, KHÔNG collision
## Physics layer 0 = Layer 1 World_Terrain (collision_layer=1, mask=0).

const TILE := 48
const ATLAS_PATH := "res://resources/neon_tiles_atlas.png"
const TILESET_PATH := "res://resources/gd_neon_tileset.tres"

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	quit(_run())
	return true


func _run() -> int:
	var img := Image.create(TILE * 4, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_solid(img, 0)
	_draw_edge(img, 1)
	_draw_oneway(img, 2)
	_draw_deco(img, 3)
	if img.save_png(ATLAS_PATH) != OK:
		printerr("GEN FAIL: khong save duoc ", ATLAS_PATH)
		return 1
	var tex: Texture2D = load(ATLAS_PATH) as Texture2D
	if tex == null:
		printerr("GEN FAIL: PNG chua import — chay editor import truoc (xem tools/build_tileset.ps1)")
		return 1
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	# Gắn source vào TileSet TRƯỚC khi cấu hình tile: TileData cần
	# đọc số physics layers từ TileSet, gắn sau sẽ out-of-bounds.
	ts.add_source(src)
	for tx in range(4):
		src.create_tile(Vector2i(tx, 0))
	_solid_collision(src, Vector2i(0, 0), false)
	_solid_collision(src, Vector2i(1, 0), false)
	_slab_collision(src, Vector2i(2, 0))
	# Tile (3,0) deco: không thêm polygon = không collision.
	if ResourceSaver.save(ts, TILESET_PATH) != OK:
		printerr("GEN FAIL: khong save duoc ", TILESET_PATH)
		return 1
	print("GEN OK: ", ATLAS_PATH, " + ", TILESET_PATH)
	return 0


func _tile_origin(tx: int) -> Vector2i:
	return Vector2i(tx * TILE, 0)


func _draw_solid(img: Image, tx: int) -> void:
	var o: Vector2i = _tile_origin(tx)
	img.fill_rect(Rect2i(o, Vector2i(TILE, TILE)), Color("#232838"))
	img.fill_rect(Rect2i(o, Vector2i(TILE, 3)), Color("#3a4358"))
	img.fill_rect(Rect2i(o + Vector2i(0, TILE - 3), Vector2i(TILE, 3)), Color("#141821"))
	img.fill_rect(Rect2i(o, Vector2i(2, TILE)), Color("#2e3547"))


func _draw_edge(img: Image, tx: int) -> void:
	_draw_solid(img, tx)
	var o: Vector2i = _tile_origin(tx)
	var c := Color("#0e7d8c")
	img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(TILE - 2, 2)), c)
	img.fill_rect(Rect2i(o + Vector2i(1, TILE - 3), Vector2i(TILE - 2, 2)), c)
	img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(2, TILE - 2)), c)
	img.fill_rect(Rect2i(o + Vector2i(TILE - 3, 1), Vector2i(2, TILE - 2)), c)


func _draw_oneway(img: Image, tx: int) -> void:
	var o: Vector2i = _tile_origin(tx)
	img.fill_rect(Rect2i(o, Vector2i(TILE, 12)), Color("#35e0ff"))
	img.fill_rect(Rect2i(o + Vector2i(0, 12), Vector2i(TILE, 3)), Color("#0e7d8c"))


func _draw_deco(img: Image, tx: int) -> void:
	var o: Vector2i = _tile_origin(tx)
	var c := Color(1, 1, 1, 0.12)
	img.fill_rect(Rect2i(o + Vector2i(TILE / 2 - 1, 4), Vector2i(2, TILE - 8)), c)
	img.fill_rect(Rect2i(o + Vector2i(4, TILE / 2 - 1), Vector2i(TILE - 8, 2)), c)


func _full_rect() -> PackedVector2Array:
	var h := 24.0
	return PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])


func _solid_collision(src: TileSetAtlasSource, coords: Vector2i, one_way: bool) -> void:
	var td: TileData = src.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, _full_rect())
	td.set_collision_polygon_one_way(0, 0, one_way)


func _slab_collision(src: TileSetAtlasSource, coords: Vector2i) -> void:
	# Bệ mỏng 1/4 trên của tile (tọa độ tile, gốc giữa ô).
	var td: TileData = src.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-24, -24), Vector2(24, -24), Vector2(24, -12), Vector2(-24, -12)]))
	td.set_collision_polygon_one_way(0, 0, true)
