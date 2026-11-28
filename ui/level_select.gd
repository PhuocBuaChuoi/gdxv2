extends Control

## T8.02 — Chọn màn: sinh thẻ tự động từ LevelManager (6 màn chiến dịch đầu + màn custom .gdx.json phía sau).

const MENU_SCENE := "res://ui/main_menu.tscn"
const PAGE_SIZE := 6

var manager: Node = null
var _page: int = 0

@onready var _cards: VBoxContainer = $CardsBox
@onready var _title: Label = get_node_or_null("Title") as Label
@onready var _progress: Label = get_node_or_null("ProgressLabel") as Label
@onready var _back: Button = get_node_or_null("BackBtn") as Button
@onready var _page_row: Control = get_node_or_null("PageRow") as Control
@onready var _prev_btn: Button = get_node_or_null("PageRow/PrevBtn") as Button
@onready var _next_btn: Button = get_node_or_null("PageRow/NextBtn") as Button
@onready var _page_lbl: Label = get_node_or_null("PageRow/PageLabel") as Label


func _ready() -> void:
	if manager == null:
		manager = get_node_or_null("/root/LevelManager")
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_music")
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
	if _prev_btn != null:
		_prev_btn.text = LocalePack.tr_key("select_prev")
	if _next_btn != null:
		_next_btn.text = LocalePack.tr_key("select_next")
	for c in _cards.get_children():
		_cards.remove_child(c)
		c.free()
	if manager == null:
		return
	if manager.has_method("rescan"):
		manager.call("rescan")
	var levels_v: Variant = manager.get("levels")
	var levels: Array = levels_v as Array if levels_v is Array else []
	var unlocked: int = int(manager.get("unlocked"))
	var best_v: Variant = manager.get("best")
	var best: Dictionary = best_v as Dictionary if best_v is Dictionary else {}
	var camp_count := int(manager.call("campaign_count")) if manager.has_method("campaign_count") else mini(6, levels.size())
	var custom_count := maxi(0, levels.size() - camp_count)
	if _progress != null:
		_progress.text = LocalePack.tr_key("select_progress", [mini(unlocked, camp_count), camp_count, custom_count])

	var total_pages := maxi(1, ceili(float(levels.size()) / float(PAGE_SIZE)))
	_page = clampi(_page, 0, total_pages - 1)
	if _page_row != null:
		_page_row.visible = total_pages > 1
	if _page_lbl != null:
		_page_lbl.text = LocalePack.tr_key("select_page", [_page + 1, total_pages])
	if _prev_btn != null:
		_prev_btn.disabled = _page <= 0
	if _next_btn != null:
		_next_btn.disabled = _page >= total_pages - 1

	var start_idx := _page * PAGE_SIZE
	var end_idx := mini(start_idx + PAGE_SIZE, levels.size())
	for i in range(start_idx, end_idx):
		var is_custom := bool(manager.call("is_custom_index", i)) if manager.has_method("is_custom_index") else false
		var is_locked := false if is_custom else (i >= unlocked)
		_cards.add_child(_make_card(i, is_locked, is_custom, best))


func _make_card(index: int, locked: bool, is_custom: bool, best: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_font_size_override("font_size", 23)
	if is_custom:
		var meta_v: Variant = manager.call("custom_info_at", index) if manager.has_method("custom_info_at") else {}
		var meta: Dictionary = meta_v as Dictionary if meta_v is Dictionary else {}
		var cname := str(meta.get("name", "Custom"))
		var rec_v: Variant = manager.call("best_record_for", index) if manager.has_method("best_record_for") else {}
		var rec: Dictionary = rec_v as Dictionary if rec_v is Dictionary else {}
		if not rec.is_empty():
			var t_v: Variant = rec.get("time", 0.0)
			var d_v: Variant = rec.get("deaths", 0)
			var rec_time := float(t_v) if (t_v is int or t_v is float) else 0.0
			var rec_deaths := int(d_v) if (d_v is int or d_v is float) else 0
			b.text = LocalePack.tr_key("select_custom_best", [index + 1, cname, _fmt_time(rec_time), rec_deaths])
		else:
			b.text = LocalePack.tr_key("select_custom_none", [index + 1, cname])
	elif locked:
		b.text = LocalePack.tr_key("select_locked", [index + 1])
		b.disabled = true
		return b
	elif best.has(str(index)) and best[str(index)] is Dictionary:
		var rec := best[str(index)] as Dictionary
		var t_v: Variant = rec.get("time", 0.0)
		var d_v: Variant = rec.get("deaths", 0)
		var rec_time := float(t_v) if (t_v is int or t_v is float) else 0.0
		var rec_deaths := int(d_v) if (d_v is int or d_v is float) else 0
		b.text = LocalePack.tr_key("select_unlocked_best", [index + 1, _fmt_time(rec_time), rec_deaths])
	else:
		b.text = LocalePack.tr_key("select_unlocked_none", [index + 1])
	var idx := index
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx("click")
		manager.call("load_level", idx)
	)
	return b


func _on_prev_page() -> void:
	AudioManager.play_sfx("click")
	_page -= 1
	rebuild()


func _on_next_page() -> void:
	AudioManager.play_sfx("click")
	_page += 1
	rebuild()


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	return "%d:%05.2f" % [total / 60, t - float(total / 60 * 60)]


func _on_back_pressed() -> bool:
	AudioManager.play_sfx("click")
	return get_tree().change_scene_to_file(MENU_SCENE) == OK
