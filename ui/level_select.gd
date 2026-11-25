extends Control

## T8.02 — Chọn màn: sinh thẻ tự động từ LevelManager (mở/khóa, best time/deaths) + hỗ trợ đổi ngôn ngữ.

const MENU_SCENE := "res://ui/main_menu.tscn"

var manager: Node = null

@onready var _cards: VBoxContainer = $CardsBox
@onready var _title: Label = get_node_or_null("Title") as Label
@onready var _progress: Label = get_node_or_null("ProgressLabel") as Label
@onready var _back: Button = get_node_or_null("BackBtn") as Button


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	rebuild()


func _exit_tree() -> void:
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: String) -> void:
	rebuild()


func rebuild() -> void:
	if _title != null:
		_title.text = LocalePack.tr_key("select_title")
	if _back != null:
		_back.text = LocalePack.tr_key("select_back")
	for c in _cards.get_children():
		_cards.remove_child(c)
		c.free()
	if manager == null:
		return
	var levels: Array = manager.get("levels")
	var unlocked: int = int(manager.get("unlocked"))
	var best: Dictionary = manager.get("best")
	if _progress != null:
		_progress.text = LocalePack.tr_key("select_progress", [mini(unlocked, levels.size()), levels.size()])
	for i in range(levels.size()):
		_cards.add_child(_make_card(i, i >= unlocked, best))


func _make_card(index: int, locked: bool, best: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 24)
	if locked:
		b.text = LocalePack.tr_key("select_locked", [index + 1])
		b.disabled = true
		return b
	if best.has(str(index)):
		var rec := best[str(index)] as Dictionary
		b.text = LocalePack.tr_key("select_unlocked_best", [index + 1, _fmt_time(float(rec["time"])), int(rec["deaths"])])
	else:
		b.text = LocalePack.tr_key("select_unlocked_none", [index + 1])
	var idx := index
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		manager.call("load_level", idx)
	)
	return b


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%d:%05.2f" % [total / 60, t - float(total / 60 * 60)]


func _on_back_pressed() -> bool:
	AudioManager.play_sfx("click")
	return get_tree().change_scene_to_file(MENU_SCENE) == OK
