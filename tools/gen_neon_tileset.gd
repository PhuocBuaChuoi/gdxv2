extends SceneTree

## T7.01 - Build tool: sinh atlas PNG + gd_neon_tileset.tres, chay headless.
## KHONG phai test (ten khong bat dau bang test_ nen runner bo qua).
## Chay: powershell -ExecutionPolicy Bypass -File tools/build_tileset.ps1
## (import editor truoc de PNG load duoc qua ResourceLoader).
##
## Thiet ke (grid 48px khop hitbox player T3.01, goc toa do tile o GIUA):
##   row 0: (0,0) solid long  - khoi dac, collision vuong full
##          (1,0) edge-block - khoi dac vien neon 4 canh (giu cho tuong thich)
##          (2,0) one-way    - be mong 1/4 tren, one_way, dung xuyen tu duoi
##          (3,0) deco       - trang tri mo, KHONG collision
##   rows 1..4: 16 bien the solid co vien TU DONG theo hang xom:
##          mask bit N=1, E=2, S=4, W=8 (bit = huong KHONG co hang xom solid)
##          atlas coords = (mask % 4, 1 + mask / 4)
##   -> vien neon chay lien mach quanh tung khoi, khong con luoi 48px.
## Physics layer 0 = Layer 1 World_Terrain (collision_layer=1, mask=0).

const TILE := 48
const COLS := 4
const ROWS := 5
const ATLAS_PATH := "res://resources/neon_tiles_atlas.png"
const TILESET_PATH := "res://resources/gd_neon_tileset.tres"

## Cyberpunk / Geometry Dash palette
const BODY := Color("#0e1320")
const BODY_INSET := Color("#1a233a")
const BODY_TECH := Color("#243354")
const BODY_NOTCH := Color("#354d7e")

const NEON := Color("#2fe0ff")
const NEON_SOFT := Color("#1baecc")
const NEON_DIM := Color("#0e5f73")
const NEON_HOT := Color("#e8fcff")

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	quit(_run())
	return true


func _run() -> int:
	var img := Image.create(TILE * COLS, TILE * ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_body(img, 0, 0)
	_fill_body(img, 1, 0)
	_draw_edges(img, 1, 0, 0xF)
	_draw_oneway(img, 2, 0)
	_draw_deco(img, 3, 0)
	for mask in range(16):
		if mask == 0:
			continue
		_fill_body(img, mask % COLS, 1 + (mask >> 2))
		_draw_edges(img, mask % COLS, 1 + (mask >> 2), mask)
	if img.save_png(ATLAS_PATH) != OK:
		printerr("GEN FAIL: khong save duoc ", ATLAS_PATH)
		return 1
	var tex: Texture2D = load(ATLAS_PATH) as Texture2D
	if tex == null:
		printerr("GEN FAIL: PNG chua import - chay editor import truoc (xem tools/build_tileset.ps1)")
		return 1
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src)
	for ty in range(ROWS):
		for tx in range(COLS):
			src.create_tile(Vector2i(tx, ty))
	_solid_collision(src, Vector2i(0, 0), false)
	_solid_collision(src, Vector2i(1, 0), false)
	_slab_collision(src, Vector2i(2, 0))
	for ty in range(1, ROWS):
		for tx in range(COLS):
			_solid_collision(src, Vector2i(tx, ty), false)
	if ResourceSaver.save(ts, TILESET_PATH) != OK:
		printerr("GEN FAIL: khong save duoc ", TILESET_PATH)
		return 1
	print("GEN OK: ", ATLAS_PATH, " + ", TILESET_PATH)
	return 0


func _origin(tx: int, ty: int) -> Vector2i:
	return Vector2i(tx * TILE, ty * TILE)


func _fill_body(img: Image, tx: int, ty: int) -> void:
	var o: Vector2i = _origin(tx, ty)
	# 1. Base deep cyber slate
	img.fill_rect(Rect2i(o, Vector2i(TILE, TILE)), BODY)
	
	# 2. Inset geometric frame (4px margin)
	img.fill_rect(Rect2i(o + Vector2i(4, 4), Vector2i(TILE - 8, 1)), BODY_INSET)
	img.fill_rect(Rect2i(o + Vector2i(4, TILE - 5), Vector2i(TILE - 8, 1)), BODY_INSET)
	img.fill_rect(Rect2i(o + Vector2i(4, 4), Vector2i(1, TILE - 8)), BODY_INSET)
	img.fill_rect(Rect2i(o + Vector2i(TILE - 5, 4), Vector2i(1, TILE - 8)), BODY_INSET)
	
	# 3. 4 Corner tech brackets (inside 8px)
	var c_offsets := [
		Vector2i(8, 8), Vector2i(TILE - 10, 8),
		Vector2i(8, TILE - 10), Vector2i(TILE - 10, TILE - 10)
	]
	for c in c_offsets:
		img.fill_rect(Rect2i(o + c, Vector2i(2, 2)), BODY_NOTCH)
	
	# 4. Center cyber emblem / tech cross
	var mid := Vector2i(o.x + TILE / 2, o.y + TILE / 2)
	img.fill_rect(Rect2i(mid - Vector2i(4, 0), Vector2i(9, 1)), BODY_TECH)
	img.fill_rect(Rect2i(mid - Vector2i(0, 4), Vector2i(1, 9)), BODY_TECH)
	img.set_pixel(mid.x, mid.y, BODY_NOTCH)


func _draw_edges(img: Image, tx: int, ty: int, mask: int) -> void:
	var o: Vector2i = _origin(tx, ty)
	# W (West / Left)
	if mask & 8:
		img.fill_rect(Rect2i(o, Vector2i(2, TILE)), NEON_SOFT)
		img.fill_rect(Rect2i(o + Vector2i(2, 0), Vector2i(1, TILE)), NEON)
		img.fill_rect(Rect2i(o + Vector2i(3, 0), Vector2i(2, TILE)), NEON_DIM)
	# E (East / Right)
	if mask & 2:
		img.fill_rect(Rect2i(o + Vector2i(TILE - 2, 0), Vector2i(2, TILE)), NEON_SOFT)
		img.fill_rect(Rect2i(o + Vector2i(TILE - 3, 0), Vector2i(1, TILE)), NEON)
		img.fill_rect(Rect2i(o + Vector2i(TILE - 5, 0), Vector2i(2, TILE)), NEON_DIM)
	# N (North / Top walking runway)
	if mask & 1:
		img.fill_rect(Rect2i(o, Vector2i(TILE, 1)), NEON_HOT)
		img.fill_rect(Rect2i(o + Vector2i(0, 1), Vector2i(TILE, 2)), NEON)
		img.fill_rect(Rect2i(o + Vector2i(0, 3), Vector2i(TILE, 1)), NEON_SOFT)
		img.fill_rect(Rect2i(o + Vector2i(0, 4), Vector2i(TILE, 2)), NEON_DIM)
	# S (South / Ceiling)
	if mask & 4:
		img.fill_rect(Rect2i(o + Vector2i(0, TILE - 2), Vector2i(TILE, 2)), NEON_SOFT)
		img.fill_rect(Rect2i(o + Vector2i(0, TILE - 4), Vector2i(TILE, 2)), NEON_DIM)


func _draw_oneway(img: Image, tx: int, ty: int) -> void:
	var o: Vector2i = _origin(tx, ty)
	img.fill_rect(Rect2i(o, Vector2i(TILE, 1)), NEON_HOT)
	img.fill_rect(Rect2i(o + Vector2i(0, 1), Vector2i(TILE, 2)), NEON)
	img.fill_rect(Rect2i(o + Vector2i(0, 3), Vector2i(TILE, 2)), NEON_SOFT)
	img.fill_rect(Rect2i(o + Vector2i(0, 5), Vector2i(TILE, 3)), Color(NEON_DIM, 0.6))
	# Subtle upward chevron indicators
	var c_dim := Color(NEON, 0.45)
	for i in range(4):
		var cx := o.x + 6 + i * 10
		img.set_pixel(cx + 2, o.y + 8, c_dim)
		img.set_pixel(cx + 1, o.y + 9, c_dim)
		img.set_pixel(cx + 3, o.y + 9, c_dim)


func _draw_deco(img: Image, tx: int, ty: int) -> void:
	var o: Vector2i = _origin(tx, ty)
	var c := Color(NEON_SOFT, 0.25)
	var c_hot := Color(NEON_HOT, 0.45)
	img.fill_rect(Rect2i(o + Vector2i(TILE / 2 - 1, 6), Vector2i(2, TILE - 12)), c)
	img.fill_rect(Rect2i(o + Vector2i(6, TILE / 2 - 1), Vector2i(TILE - 12, 2)), c)
	img.fill_rect(Rect2i(o + Vector2i(TILE / 2 - 2, TILE / 2 - 2), Vector2i(4, 4)), c_hot)


func _full_rect() -> PackedVector2Array:
	var h := 24.0
	return PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])


func _solid_collision(src: TileSetAtlasSource, coords: Vector2i, one_way: bool) -> void:
	var td: TileData = src.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, _full_rect())
	td.set_collision_polygon_one_way(0, 0, one_way)


func _slab_collision(src: TileSetAtlasSource, coords: Vector2i) -> void:
	var td: TileData = src.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-24, -24), Vector2(24, -24), Vector2(24, -12), Vector2(-24, -12)]))
	td.set_collision_polygon_one_way(0, 0, true)
