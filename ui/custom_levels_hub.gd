extends Control

const MAIN_MENU_SCENE := "res://ui/main_menu.tscn"
const STATUS_TOAST_DURATION := 3.0

@onready var _title_label: Label = $SafeMargin/MainVBox/HeaderPanel/HeaderHBox/TitleVBox/TitleLabel
@onready var _subtitle_label: Label = $SafeMargin/MainVBox/HeaderPanel/HeaderHBox/TitleVBox/SubtitleLabel
@onready var _back_button: Button = $SafeMargin/MainVBox/HeaderPanel/HeaderHBox/BackButton
@onready var _new_button: Button = $SafeMargin/MainVBox/ActionBar/NewLevelButton
@onready var _import_button: Button = $SafeMargin/MainVBox/ActionBar/ImportButton
@onready var _open_folder_button: Button = $SafeMargin/MainVBox/ActionBar/OpenFolderButton
@onready var _status_label: Label = $SafeMargin/MainVBox/ActionBar/StatusLabel
@onready var _scroll_container: ScrollContainer = $SafeMargin/MainVBox/BodyPanel/BodyVBox/ScrollContainer
@onready var _levels_list: VBoxContainer = $SafeMargin/MainVBox/BodyPanel/BodyVBox/ScrollContainer/LevelsList
@onready var _empty_center: CenterContainer = $SafeMargin/MainVBox/BodyPanel/BodyVBox/EmptyStateCenter
@onready var _empty_label: Label = $SafeMargin/MainVBox/BodyPanel/BodyVBox/EmptyStateCenter/EmptyLabel

@onready var _import_overlay: ColorRect = $ImportOverlay
@onready var _import_title_label: Label = $ImportOverlay/ImportCenter/ImportDialog/DialogVBox/ImportTitleLabel
@onready var _import_input: TextEdit = $ImportOverlay/ImportCenter/ImportDialog/DialogVBox/ImportInput
@onready var _import_error_label: Label = $ImportOverlay/ImportCenter/ImportDialog/DialogVBox/ImportErrorLabel
@onready var _cancel_import_button: Button = $ImportOverlay/ImportCenter/ImportDialog/DialogVBox/DialogButtons/CancelImportButton
@onready var _confirm_import_button: Button = $ImportOverlay/ImportCenter/ImportDialog/DialogVBox/DialogButtons/ConfirmImportButton

var _locale_cb: Callable
var _status_timer: float = 0.0
var _entries: Array[Dictionary] = []
var _row_card_style: StyleBoxFlat


func _ready() -> void:
	_build_styles()
	_connect_signals()
	_locale_cb = Callable(self, "_on_locale_changed")
	LocalePack.subscribe(_locale_cb)
	_apply_locale()
	_refresh_levels()
	_new_button.grab_focus()


func _exit_tree() -> void:
	if _locale_cb.is_valid():
		LocalePack.unsubscribe(_locale_cb)


func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer = maxf(0.0, _status_timer - delta)
		if _status_timer <= 0.0:
			_status_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _import_overlay.visible:
			_close_import_dialog()
		else:
			_on_back_pressed()


func _build_styles() -> void:
	_row_card_style = StyleBoxFlat.new()
	_row_card_style.bg_color = Color(0.06, 0.11, 0.21, 0.9)
	_row_card_style.border_width_left = 1
	_row_card_style.border_width_top = 1
	_row_card_style.border_width_right = 1
	_row_card_style.border_width_bottom = 1
	_row_card_style.border_color = Color(0.18, 0.72, 0.92, 0.55)
	_row_card_style.corner_radius_top_left = 6
	_row_card_style.corner_radius_top_right = 6
	_row_card_style.corner_radius_bottom_right = 6
	_row_card_style.corner_radius_bottom_left = 6
	_row_card_style.content_margin_left = 18.0
	_row_card_style.content_margin_top = 12.0
	_row_card_style.content_margin_right = 18.0
	_row_card_style.content_margin_bottom = 12.0

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.04, 0.07, 0.14, 0.96)
	input_style.border_width_left = 1
	input_style.border_width_top = 1
	input_style.border_width_right = 1
	input_style.border_width_bottom = 1
	input_style.border_color = Color(0.22, 0.85, 1.0, 0.65)
	input_style.corner_radius_top_left = 4
	input_style.corner_radius_top_right = 4
	input_style.corner_radius_bottom_right = 4
	input_style.corner_radius_bottom_left = 4
	input_style.content_margin_left = 12.0
	input_style.content_margin_top = 10.0
	input_style.content_margin_right = 12.0
	input_style.content_margin_bottom = 10.0
	_import_input.add_theme_stylebox_override("normal", input_style)
	_import_input.add_theme_stylebox_override("focus", input_style)

	_cancel_import_button.focus_next = _confirm_import_button.get_path()
	_cancel_import_button.focus_previous = _import_input.get_path()
	_cancel_import_button.focus_neighbor_right = _confirm_import_button.get_path()
	_confirm_import_button.focus_next = _import_input.get_path()
	_confirm_import_button.focus_previous = _cancel_import_button.get_path()
	_confirm_import_button.focus_neighbor_left = _cancel_import_button.get_path()
	_import_input.focus_next = _cancel_import_button.get_path()
	_import_input.focus_previous = _confirm_import_button.get_path()


func _connect_signals() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_new_button.pressed.connect(_on_new_pressed)
	_import_button.pressed.connect(_open_import_dialog)
	_open_folder_button.pressed.connect(_on_open_folder_pressed)
	_cancel_import_button.pressed.connect(_close_import_dialog)
	_confirm_import_button.pressed.connect(_on_confirm_import_pressed)


func _on_locale_changed(_locale: String) -> void:
	_apply_locale()
	_rebuild_rows()


func _apply_locale() -> void:
	_title_label.text = LocalePack.tr_key("hub_title")
	_subtitle_label.text = LocalePack.tr_key("hub_subtitle")
	_new_button.text = LocalePack.tr_key("hub_new")
	_import_button.text = LocalePack.tr_key("hub_import")
	_open_folder_button.text = LocalePack.tr_key("hub_open_folder")
	_back_button.text = LocalePack.tr_key("select_back")
	_empty_label.text = LocalePack.tr_key("hub_empty")
	_import_title_label.text = LocalePack.tr_key("hub_import_title")
	_confirm_import_button.text = LocalePack.tr_key("hub_import_btn")
	_cancel_import_button.text = LocalePack.tr_key("hub_cancel")
	if _import_error_label.visible:
		_import_error_label.text = LocalePack.tr_key("hub_import_err")


func _refresh_levels() -> void:
	var mgr := get_node_or_null("/root/LevelManager")
	if mgr != null and mgr.has_method("rescan"):
		mgr.call("rescan")
	_entries.clear()
	var raw_list: Array = CustomLevelStore.list_levels()
	for raw_item in raw_list:
		var parsed := _normalize_entry(raw_item)
		if not parsed.is_empty():
			_entries.append(parsed)
	_rebuild_rows()


func _find_first_row_button(row: Node) -> Button:
	for child in row.get_children():
		if child is Button:
			return child as Button
		var found := _find_first_row_button(child)
		if found != null:
			return found
	return null


func _normalize_entry(raw_item: Variant) -> Dictionary:
	var path := ""
	var data: Dictionary = {}
	var display_name := ""

	if raw_item is Dictionary:
		var item_dict: Dictionary = raw_item
		path = _safe_str(item_dict.get("path", item_dict.get("file_path", "")))
		display_name = _safe_str(item_dict.get("name", item_dict.get("title", "")))
		if item_dict.get("data") is Dictionary:
			data = (item_dict["data"] as Dictionary).duplicate(true)
		elif item_dict.get("level_data") is Dictionary:
			data = (item_dict["level_data"] as Dictionary).duplicate(true)
		elif item_dict.has("objects") or item_dict.has("ascii_map") or item_dict.has("tiles") or item_dict.has("grid_cols") or item_dict.has("grid_width"):
			data = item_dict.duplicate(true)
	elif raw_item is String:
		path = str(raw_item)

	if data.is_empty() and path != "":
		var loaded: Dictionary = CustomLevelStore.load_file(path)
		if not loaded.is_empty():
			data = loaded
		elif FileAccess.file_exists(path):
			var parsed_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed_json is Dictionary:
				data = parsed_json

	if display_name == "" and not data.is_empty():
		display_name = _safe_str(data.get("name", data.get("title", data.get("level_name", ""))))
		if display_name == "" and data.get("meta") is Dictionary:
			display_name = _safe_str((data["meta"] as Dictionary).get("name", ""))
	if display_name == "" and path != "":
		display_name = path.get_file().trim_suffix(".gdx.json")
	if display_name == "":
		display_name = "Custom Level"

	return {
		"path": path,
		"data": data,
		"name": display_name,
	}


func _rebuild_rows() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	var focus_was_in_list := focus_owner != null and _levels_list.is_ancestor_of(focus_owner)
	for child in _levels_list.get_children():
		_levels_list.remove_child(child)
		child.queue_free()

	var is_empty := _entries.is_empty()
	_empty_center.visible = is_empty
	_scroll_container.visible = not is_empty
	if is_empty:
		if focus_was_in_list and not _import_overlay.visible:
			_new_button.grab_focus()
		return

	for entry in _entries:
		_levels_list.add_child(_create_level_row(entry))

	if focus_was_in_list and not _import_overlay.visible and _levels_list.get_child_count() > 0:
		var first_play := _find_first_row_button(_levels_list.get_child(0))
		if first_play != null:
			first_play.grab_focus()
		else:
			_new_button.grab_focus()


func _create_level_row(entry: Dictionary) -> Control:
	var path: String = str(entry.get("path", ""))
	var data: Dictionary = entry.get("data", {})
	var level_name: String = str(entry.get("name", "Custom Level"))

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _row_card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = level_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0, 1.0))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_vbox.add_child(name_label)

	var meta_label := Label.new()
	meta_label.text = _format_meta(path, data)
	meta_label.add_theme_font_size_override("font_size", 15)
	meta_label.add_theme_color_override("font_color", Color(0.62, 0.82, 0.94, 0.85))
	meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_vbox.add_child(meta_label)

	var buttons_hbox := HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 8)
	buttons_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(buttons_hbox)

	var play_btn := _make_row_button(LocalePack.tr_key("hub_play"), Color(0.75, 1.0, 0.85, 1.0), 110)
	play_btn.pressed.connect(func() -> void: _on_play_entry(data, path))
	buttons_hbox.add_child(play_btn)

	var edit_btn := _make_row_button(LocalePack.tr_key("hub_edit"), Color(1.0, 1.0, 1.0, 1.0), 110)
	edit_btn.pressed.connect(func() -> void: _on_edit_entry(data, path))
	buttons_hbox.add_child(edit_btn)

	var dup_btn := _make_row_button(LocalePack.tr_key("hub_duplicate"), Color(1.0, 1.0, 1.0, 1.0), 130)
	dup_btn.pressed.connect(func() -> void: _on_duplicate_entry(path))
	buttons_hbox.add_child(dup_btn)

	var export_btn := _make_row_button(LocalePack.tr_key("hub_export"), Color(0.82, 0.96, 1.0, 1.0), 140)
	export_btn.pressed.connect(func() -> void: _on_export_entry(data))
	buttons_hbox.add_child(export_btn)

	var del_btn := _make_row_button(LocalePack.tr_key("hub_delete"), Color(1.0, 0.62, 0.62, 1.0), 110)
	del_btn.pressed.connect(func() -> void: _on_delete_entry(path))
	buttons_hbox.add_child(del_btn)

	return card


func _make_row_button(label_text: String, tint: Color, min_w: int) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.modulate = tint
	btn.custom_minimum_size = Vector2(min_w, 46)
	btn.add_theme_font_size_override("font_size", 17)
	return btn


func _safe_str(val: Variant, fallback: String = "") -> String:
	if val == null:
		return fallback
	return str(val)


func _pick_positive_int(data: Dictionary, keys: Array[String]) -> int:
	for k in keys:
		if not data.has(k):
			continue
		var v: Variant = data[k]
		if v is int or v is float:
			var iv: int = int(v)
			if iv > 0:
				return iv
		elif v is String and (v as String).is_valid_int():
			var iv: int = int(v)
			if iv > 0:
				return iv
	return 0


func _format_meta(path: String, data: Dictionary) -> String:
	var parts: PackedStringArray = []
	if path != "":
		parts.append(path.get_file())
	var w: int = _pick_positive_int(data, ["grid_cols", "grid_width", "width"])
	var h: int = _pick_positive_int(data, ["grid_rows", "grid_height", "height"])
	if w <= 0 or h <= 0:
		var amap: Variant = data.get("ascii_map", null)
		if amap is Array and not (amap as Array).is_empty():
			if h <= 0:
				h = (amap as Array).size()
			if w <= 0:
				w = str((amap as Array)[0]).length()
	if w > 0 and h > 0:
		parts.append("%dx%d" % [w, h])
	var objs: Variant = data.get("objects", null)
	if objs is Array:
		parts.append("%d obj" % (objs as Array).size())
	var bg: String = _safe_str(data.get("background", ""))
	if bg != "":
		parts.append(bg)
	return "  ·  ".join(parts)


func _next_default_stage_name() -> String:
	var used: Dictionary = {}
	for entry in _entries:
		used[str(entry.get("name", "")).to_lower()] = true
	var idx := 1
	while true:
		var candidate := "Custom Stage %d" % idx
		if not used.has(candidate.to_lower()):
			return candidate
		idx += 1
	return "Custom Stage 1"


func _on_new_pressed() -> void:
	var data: Dictionary = CustomLevelCatalog.default_level_data(_next_default_stage_name())
	LevelManager.open_editor(data, "")


func _on_play_entry(data: Dictionary, path: String) -> void:
	LevelManager.play_custom_data(data, path)


func _on_edit_entry(data: Dictionary, path: String) -> void:
	LevelManager.open_editor(data, path)


func _on_duplicate_entry(path: String) -> void:
	if path == "":
		return
	var dup_path: String = CustomLevelStore.duplicate_file(path)
	if dup_path == "":
		_show_status(LocalePack.tr_key("hub_io_err"))
		return
	LevelManager.rescan()
	_refresh_levels()


func _on_export_entry(data: Dictionary) -> void:
	var json_str: String = CustomLevelStore.export_json_string(data)
	DisplayServer.clipboard_set(json_str)
	_show_status(LocalePack.tr_key("hub_copied"))


func _on_delete_entry(path: String) -> void:
	if path == "":
		return
	if not CustomLevelStore.delete_file(path):
		_show_status(LocalePack.tr_key("hub_io_err"))
		return
	LevelManager.rescan()
	_refresh_levels()


func _on_open_folder_pressed() -> void:
	CustomLevelStore.open_custom_folder()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _open_import_dialog() -> void:
	_import_error_label.visible = false
	_import_error_label.text = ""
	_import_input.text = ""
	_import_overlay.visible = true
	_import_input.grab_focus()


func _close_import_dialog() -> void:
	_import_overlay.visible = false
	_import_button.grab_focus()


func _on_confirm_import_pressed() -> void:
	var raw: String = _import_input.text.strip_edges()
	if raw.length() >= 2 and ((raw.begins_with("\"") and raw.ends_with("\"")) or (raw.begins_with("'") and raw.ends_with("'"))):
		raw = raw.substr(1, raw.length() - 2).strip_edges()

	if raw.is_empty():
		_show_import_error()
		return

	var imported_raw: Variant = null
	if _looks_like_file_path(raw):
		if not FileAccess.file_exists(raw) and not FileAccess.file_exists(ProjectSettings.globalize_path(raw)):
			_show_import_error("hub_import_not_found")
			return
		imported_raw = CustomLevelStore.import_from_file(raw)
	else:
		imported_raw = CustomLevelStore.import_json_string(raw)

	if not (imported_raw is Dictionary):
		_show_import_error()
		return
	var imported: Dictionary = imported_raw
	if imported.is_empty():
		_show_import_error()
		return
	if imported.has("ok") and not bool(imported.get("ok", true)):
		_show_import_error()
		return

	var level_data: Dictionary = imported
	if imported.get("data") is Dictionary and not imported.has("objects") and not imported.has("ascii_map") and not imported.has("tiles"):
		level_data = imported["data"]

	var already_saved_path: String = _safe_str(imported.get("path", ""))
	var already_saved: bool = (imported.has("ok") and bool(imported["ok"])) or not already_saved_path.is_empty()
	if not already_saved:
		if not _save_imported_level(level_data):
			_show_import_error("hub_import_write_err")
			return

	LevelManager.rescan()
	_close_import_dialog()
	_refresh_levels()


func _looks_like_file_path(raw: String) -> bool:
	if raw.begins_with("{") or raw.begins_with("["):
		return false
	if FileAccess.file_exists(raw):
		return true
	var lower := raw.to_lower()
	return lower.ends_with(".gdx.json") or lower.ends_with(".json") or raw.begins_with("res://") or raw.begins_with("user://")


func _save_imported_level(data: Dictionary) -> bool:
	var res: Variant = CustomLevelStore.save_level(data)
	if res is bool:
		return res
	if res is String:
		return not (res as String).is_empty()
	if res is Dictionary:
		var d := res as Dictionary
		if d.has("ok"):
			return bool(d.get("ok", false))
		return not str(d.get("path", "")).is_empty()
	return res != null


func _show_import_error(key: String = "hub_import_err") -> void:
	_import_error_label.text = LocalePack.tr_key(key)
	_import_error_label.visible = true


func _show_status(msg: String) -> void:
	_status_label.text = msg
	_status_timer = STATUS_TOAST_DURATION
