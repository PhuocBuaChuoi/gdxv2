class_name AssetFrames
extends RefCounted

## Bonus asset — frame hóa sprite sheet + chuẩn hóa nền + pivot/hitbox.
## - KHÔNG ghi vào potential_Assets/ (assets gốc chỉ đọc).
## - Metadata/kê khai quyền: resources/potential_assets.gd (của agent khác — không sửa).
## - Sheet nền trắng (character, frog): tách nền bằng white_to_alpha lúc runtime,
##   cache RAM. Sheet đã có alpha (bunny): dùng trực tiếp AtlasTexture.
## - Export-safe: chỉ dùng load()/AtlasTexture/get_image(), không Image.load_from_file.

const Catalog = preload("res://resources/potential_assets.gd")

## Pivot chân nhân vật (Sprite2D.offset/position đặt theo chân).
const PIVOT_FEET := Vector2(0.5, 1.0)

static var _tex_cache: Dictionary = {}
static var _frame_cache: Dictionary = {}
static var _alpha_cache: Dictionary = {}


static func sheet_texture(sheet_path: String) -> Texture2D:
	if not _tex_cache.has(sheet_path):
		_tex_cache[sheet_path] = load(sheet_path) as Texture2D
	return _tex_cache[sheet_path] as Texture2D


static func grid(sheet_path: String) -> Dictionary:
	return (Catalog.sheet_metadata() as Dictionary).get(sheet_path, {})


static func frame_count(sheet_path: String) -> int:
	var g: Dictionary = grid(sheet_path)
	return int(g.get("columns", 0)) * int(g.get("rows", 0))


## Rect frame thứ index (hàng trên xuống, trái sang phải).
static func frame_rect(sheet_path: String, index: int) -> Rect2i:
	var g: Dictionary = grid(sheet_path)
	var cols: int = maxi(int(g.get("columns", 1)), 1)
	var fs: Vector2i = g.get("frame_size", Vector2i(1, 1))
	return Rect2i(Vector2i((index % cols) * fs.x, (index / cols) * fs.y), fs)


static func frame_texture(sheet_path: String, index: int) -> AtlasTexture:
	var key := "%s#%d" % [sheet_path, index]
	if not _frame_cache.has(key):
		var at := AtlasTexture.new()
		at.atlas = sheet_texture(sheet_path)
		at.region = frame_rect(sheet_path, index)
		_frame_cache[key] = at
	return _frame_cache[key] as AtlasTexture


## Nền = màu pixel (0,0); pixel nào gần nền trong ngưỡng thì alpha=0.
## threshold ~0.12 nuốt nhiễu JPG quanh viền; giữ nguyên pixel nhân vật.
static func white_to_alpha(img: Image, threshold: float = 0.12) -> Image:
	var out: Image = img.duplicate() as Image
	if out.is_compressed():
		out.decompress()
	out.convert(Image.FORMAT_RGBA8)
	if out.is_empty():
		return out
	var bg: Color = out.get_pixel(0, 0)
	var limit: float = threshold * threshold * 3.0
	for y in range(out.get_height()):
		for x in range(out.get_width()):
			var c: Color = out.get_pixel(x, y)
			var dr: float = c.r - bg.r
			var dg: float = c.g - bg.g
			var db: float = c.b - bg.b
			if dr * dr + dg * dg + db * db <= limit:
				out.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
	return out


## Frame đã tách nền của sheet nền trắng (cache theo path).
static func keyed_frame(sheet_path: String, index: int) -> ImageTexture:
	var key := "keyed:%s#%d" % [sheet_path, index]
	if not _alpha_cache.has(key):
		var tex: Texture2D = sheet_texture(sheet_path)
		var r: Rect2i = frame_rect(sheet_path, index)
		_alpha_cache[key] = ImageTexture.create_from_image(white_to_alpha(tex.get_image().get_region(r)))
	return _alpha_cache[key] as ImageTexture


## Hitbox đề xuất: co vào theo tỉ lệ để khỏi chết oan mép sprite.
static func hitbox_rect(frame_size: Vector2i, inset_ratio: float = 0.12) -> Rect2i:
	var ix: int = int(frame_size.x * inset_ratio)
	var iy: int = int(frame_size.y * inset_ratio)
	return Rect2i(ix, iy, maxi(frame_size.x - ix * 2, 1), maxi(frame_size.y - iy * 2, 1))
