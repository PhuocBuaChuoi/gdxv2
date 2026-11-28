class_name PaletteItemButton
extends Button

## Draggable palette button: supports both clicking to equip brush/tool AND dragging straight onto EditorCanvas.

signal item_activated(item_data: Dictionary)

var item_data: Dictionary = {}


func setup(data: Dictionary, label_text: String, icon_path: String) -> void:
	item_data = data.duplicate(true)
	text = label_text
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(0, 38)
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_font_size_override("font_size", 14)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon = load(icon_path) as Texture2D
		expand_icon = true
	pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		item_activated.emit(item_data)
	)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data.is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.custom_minimum_size = Vector2(44, 44)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path := str(item_data.get("icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		preview.texture = load(icon_path) as Texture2D
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return {"from_palette": true, "item": item_data.duplicate(true)}
