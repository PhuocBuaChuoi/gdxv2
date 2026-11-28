extends Parallax2D

## Bonus asset — background Parallax2D thuần visual, độc lập gameplay logic.
## Dùng trong base_level: instance scene này, chọn background trong Inspector.
## Ảnh: resources/potential_assets.gd (BACKGROUND_FOREST/BACKGROUND_BRIGHT).

const Catalog = preload("res://resources/potential_assets.gd")

@export_enum("FOREST", "BRIGHT") var background: String = "FOREST"
## Độ sáng nền (1.0 chuẩn, <1.0 cho màn đêm/cave để neon gameplay nổi).
@export_range(0.4, 1.0) var dim: float = 1.0
## Toc do troi ngang tu dong (px/s, 0 = tat) — background song + muot hon
## ma khong phu thuoc camera. Mirroring co san xu ly lap vo han.
@export_range(0.0, 40.0) var drift_speed: float = 6.0

var _drift: float = 0.0

@onready var _layer: ParallaxLayer = $FarLayer
@onready var _sprite: Sprite2D = $FarLayer/Sprite2D
var _mirror: Sprite2D = null


func _ready() -> void:
	_ensure_mirror()
	apply_background()


func _process(delta: float) -> void:
	if drift_speed <= 0.0 or _layer == null:
		return
	# Chu ky = 2x rong anh (anh goc + ban lat guong) -> wrap khong thay giat.
	var span := maxf(1.0, repeat_size.x)
	_drift = fmod(_drift + drift_speed * delta, span)
	scroll_offset.x = _drift


func apply_background() -> void:
	var path: String = Catalog.BACKGROUND_FOREST if background == "FOREST" else Catalog.BACKGROUND_BRIGHT
	var tex: Texture2D = load(path) as Texture2D
	if tex == null or tex.get_width() <= 0:
		return
	_sprite.texture = tex
	var vw: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var vh: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	# Phu cuc lon cho moi man: phong to 1.8x de phu vuot ca tran va vuc sau, khong bao gio lo vien den
	var s: float = maxf(vw / tex.get_width(), vh / tex.get_height()) * 1.8
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0.0, 360.0)
	_sprite.modulate = Color(dim, dim, dim)
	_layer.motion_scale = Vector2(0.12, 0.04)
	_layer.motion_mirroring = Vector2(tex.get_width() * s, 0.0)
	var span: float = tex.get_width() * s
	# Ban lat guong dat canh ban goc -> hai mep anh trung khop tung pixel,
	# nen tile lap lai khong lo duong noi. repeat_size = ca cap (2x).
	_ensure_mirror()
	_mirror.texture = tex
	_mirror.scale = Vector2(-s, s)
	_mirror.position = _sprite.position + Vector2(span, 0.0)
	_mirror.modulate = _sprite.modulate
	scroll_scale = Vector2(0.12, 0.04)
	repeat_size = Vector2(span * 2.0, 0.0)
	repeat_times = 16


func _ensure_mirror() -> void:
	if _mirror != null and is_instance_valid(_mirror):
		return
	_mirror = Sprite2D.new()
	_mirror.name = "Sprite2DMirror"
	_layer.add_child(_mirror)
