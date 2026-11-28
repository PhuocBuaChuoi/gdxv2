extends Parallax2D

## Bonus asset — background Parallax2D thuần visual, độc lập gameplay logic.
## Dùng trong base_level: instance scene này, chọn background trong Inspector.
## Ảnh: resources/potential_assets.gd (BACKGROUND_FOREST/BACKGROUND_BRIGHT).

const Catalog = preload("res://resources/potential_assets.gd")

@export_enum("FOREST", "BRIGHT") var background: String = "FOREST":
	set(value):
		background = value
		# Đổi background từ Inspector/code phải tự cập nhật ảnh, không cần gọi
		# apply_background() thủ công (bug cũ: level đổi nền nhưng vẫn ảnh cũ).
		if is_inside_tree() and _sprite != null:
			apply_background()
@export var custom_texture: Texture2D = null
## Độ sáng nền (1.0 chuẩn, <1.0 cho màn đêm/cave để neon gameplay nổi).
@export_range(0.4, 1.0) var dim: float = 1.0
## Toc do troi ngang tu dong (px/s, 0 = tat) — background song + muot hon
## ma khong phu thuoc camera. Mirroring co san xu ly lap vo han.
@export_range(0.0, 40.0) var drift_speed: float = 6.0

var _drift: float = 0.0

@onready var _layer: ParallaxLayer = $FarLayer
@onready var _sprite: Sprite2D = $FarLayer/Sprite2D


func _ready() -> void:
	apply_background()


func _process(delta: float) -> void:
	if drift_speed <= 0.0 or _layer == null:
		return
	# Chu ky = 2x rong anh (anh goc + ban lat guong) -> wrap khong thay giat.
	var span := maxf(1.0, repeat_size.x)
	_drift = fmod(_drift + drift_speed * delta, span)
	scroll_offset.x = _drift


func apply_background() -> void:
	var tex: Texture2D = custom_texture
	if tex == null:
		var path: String = Catalog.BACKGROUND_FOREST if background == "FOREST" else Catalog.BACKGROUND_BRIGHT
		tex = load(path) as Texture2D
	if tex == null or tex.get_width() <= 0:
		return
	var tile_tex := _tileable_texture(tex)
	_sprite.texture = tile_tex
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if custom_texture != null else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	var vw: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var vh: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	# Phu cuc lon cho moi man: neu la AI pixel art 16:9 thi scale 1.25x cho sac net va can doi
	var mult: float = 1.25 if custom_texture != null else 1.8
	var s: float = maxf(vw / tex.get_width(), vh / tex.get_height()) * mult
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0.0, 280.0 if custom_texture != null else 360.0)
	_sprite.modulate = Color(dim, dim, dim)
	# Texture đã ghép [ảnh gốc | ảnh lật] nên hai mép nối luôn khớp pixel.
	# Parallax2D tự lặp texture của con theo repeat_size (docs 4.7).
	var span: float = tile_tex.get_width() * s
	_sprite.position = Vector2(span * 0.5, _sprite.position.y)
	scroll_scale = Vector2(0.12, 0.04)
	repeat_size = Vector2(span, 0.0)
	repeat_times = 16


## Ghép ảnh với bản lật ngang để có texture tileable (không lộ đường nối khi
## Parallax2D lặp nền theo chiều ngang).
func _tileable_texture(source: Texture2D) -> Texture2D:
	var src := source.get_image()
	if src == null or src.is_empty():
		return source
	var w := src.get_width()
	var h := src.get_height()
	var tile := Image.create(w * 2, h, false, src.get_format())
	tile.blit_rect(src, Rect2i(0, 0, w, h), Vector2i.ZERO)
	var flipped := src.duplicate()
	flipped.flip_x()
	tile.blit_rect(flipped, Rect2i(0, 0, w, h), Vector2i(w, 0))
	return ImageTexture.create_from_image(tile)
