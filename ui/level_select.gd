extends Control

## T8.02 — Chọn màn: sinh thẻ tự động từ LevelManager (mở/khóa, best time/deaths).

const MENU_SCENE := "res://ui/main_menu.tscn"

var manager: Node = null

@onready var _cards: VBoxContainer = $CardsBox
@onready var _progress: Label = get_node_or_null("ProgressLabel") as Label


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	rebuild()


func rebuild() -> void:
	for c in _cards.get_children():
		_cards.remove_child(c)
		c.free()
	if manager == null:
		return
	var levels: Array = manager.get("levels")
	var unlocked: int = int(manager.get("unlocked"))
	var best: Dictionary = manager.get("best")
	if _progress != null:
		_progress.text = "Tiến độ: %d / %d màn đã mở khóa" % [mini(unlocked, levels.size()), levels.size()]
	for i in range(levels.size()):
		_cards.add_child(_make_card(i, i >= unlocked, best))


func _make_card(index: int, locked: bool, best: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 24)
	if locked:
		b.text = "Màn %d — Khóa" % (index + 1)
		b.disabled = true
		return b
	var extra := "  —  Chưa hoàn thành"
	if best.has(str(index)):
		extra = "  —  Kỷ lục %s  ·  %d chết" % [_fmt_time(float((best[str(index)] as Dictionary)["time"])), int((best[str(index)] as Dictionary)["deaths"])]
	b.text = "Màn %d%s" % [index + 1, extra]
	var idx := index
	b.pressed.connect(func() -> void: manager.call("load_level", idx))
	return b


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%d:%05.2f" % [total / 60, t - float(total / 60 * 60)]


func _on_back_pressed() -> bool:
	return get_tree().change_scene_to_file(MENU_SCENE) == OK
