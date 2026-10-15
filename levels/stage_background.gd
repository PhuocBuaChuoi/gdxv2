extends Parallax2D

## Bonus asset — background Parallax2D thuần visual, độc lập gameplay logic.
## Dùng trong base_level: instance scene này, chọn background trong Inspector.
## Ảnh: resources/potential_assets.gd (BACKGROUND_FOREST/BACKGROUND_BRIGHT).

const Catalog = preload("res://resources/potential_assets.gd")

@export_enum("FOREST", "BRIGHT") var background: String = "FOREST"

@onready var _layer: ParallaxLayer = $FarLayer
@onready var _sprite: Sprite2D = $FarLayer/Sprite2D


func _ready() -> void:
	apply_background()


func apply_background() -> void:
	var path: String = Catalog.BACKGROUND_FOREST if background == "FOREST" else Catalog.BACKGROUND_BRIGHT
	var tex: Texture2D = load(path) as Texture2D
	if tex == null or tex.get_width() <= 0:
		return
	_sprite.texture = tex
	var vw: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var vh: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	var s: float = maxf(vw / tex.get_width(), vh / tex.get_height())
	_sprite.scale = Vector2(s, s)
	_layer.motion_mirroring = Vector2(tex.get_width() * s, 0.0)
