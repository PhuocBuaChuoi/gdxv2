class_name LevelEditor
extends Control

## Dedicated Custom Level Editor: drag-and-drop Palette, live auto-tiled Canvas,
## wire linking, dynamic Inspector, Undo/Redo, .gdx.json save/export & F5 Playtest.

const HUB_SCENE := "res://ui/custom_levels_hub.tscn"
const GRID_PRESETS := [Vector2i(48, 12), Vector2i(64, 12), Vector2i(80, 14), Vector2i(96, 16)]
const FORMS := ["CUBE", "SHIP", "UFO", "DASH"]
const MAX_HISTORY := 50

var level_data: Dictionary = {}
var source_path: String = ""
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _name_committed: String = ""
var _dim_committed: float = 0.55

@onready var _name_edit: LineEdit = $RootVBox/TopBar/TopRow/NameEdit
@onready var _size_opt: OptionButton = $RootVBox/TopBar/TopRow/SizeOpt
@onready var _bg_btn: Button = $RootVBox/TopBar/TopRow/BgBtn
@onready var _dim_slider: HSlider = $RootVBox/TopBar/TopRow/DimSlider
@onready var _p1_opt: OptionButton = $RootVBox/TopBar/TopRow/P1Opt
@onready var _p2_opt: OptionButton = $RootVBox/TopBar/TopRow/P2Opt
@onready var _undo_btn: Button = $RootVBox/TopBar/TopRow/UndoBtn
@onready var _redo_btn: Button = $RootVBox/TopBar/TopRow/RedoBtn
@onready var _grid_btn: Button = $RootVBox/TopBar/TopRow/GridBtn
@onready var _validate_btn: Button = $RootVBox/TopBar/TopRow/ValidateBtn
@onready var _playtest_btn: Button = $RootVBox/TopBar/TopRow/PlaytestBtn
@onready var _save_btn: Button = $RootVBox/TopBar/TopRow/SaveBtn
@onready var _export_btn: Button = $RootVBox/TopBar/TopRow/ExportBtn
@onready var _exit_btn: Button = $RootVBox/TopBar/TopRow/ExitBtn

@onready var _select_btn: Button = $RootVBox/MainHSplit/LeftPanel/LeftVBox/QuickTools/SelectBtn
@onready var _erase_btn: Button = $RootVBox/MainHSplit/LeftPanel/LeftVBox/QuickTools/EraseBtn
@onready var _tabs: TabContainer = $RootVBox/MainHSplit/LeftPanel/LeftVBox/PaletteTabs
@onready var _canvas: EditorCanvas = $RootVBox/MainHSplit/CanvasFrame/EditorCanvas
@onready var _inspector: VBoxContainer = $RootVBox/MainHSplit/RightPanel/InspectorScroll/EditorInspector
@onready var _status_lbl: Label = $RootVBox/StatusBar/StatusLabel
@onready var _coords_lbl: Label = $RootVBox/StatusBar/CoordsLabel


func _ready() -> void:
	var mgr := get_node_or_null("/root/LevelManager")
	var pending := mgr.call("consume_pending_editor_state") as Dictionary if mgr != null and mgr.has_method("consume_pending_editor_state") else {}
	var pdata := pending.get("data", {}) as Dictionary
	if not pdata.is_empty():
		level_data = pdata.duplicate(true)
		source_path = str(pending.get("path", ""))
	else:
		level_data = CustomLevelCatalog.default_level_data("Custom Stage 1")
		source_path = ""

	_setup_toolbar_options()
	_populate_palette()
	_bind_signals()

	_canvas.load_data(level_data, true)
	_inspector.bind_canvas(_canvas)
	_push_snapshot(level_data)
	_sync_toolbar_from_data()
	LocalePack.subscribe(Callable(self, "_on_locale_changed"))
	_apply_locale()
	_set_status(LocalePack.tr_key("ed_status_ready"))


func _exit_tree() -> void:
	LocalePack.unsubscribe(Callable(self, "_on_locale_changed"))


func _on_locale_changed(_loc: String) -> void:
	_apply_locale()
	_populate_palette()
	_inspector.rebuild()


func _setup_toolbar_options() -> void:
	_size_opt.clear()
	for gp in GRID_PRESETS:
		_size_opt.add_item("%dx%d" % [gp.x, gp.y])
	_p1_opt.clear()
	_p2_opt.clear()
	for f in FORMS:
		_p1_opt.add_item("P1: " + f)
		_p2_opt.add_item("P2: " + f)


func _sync_toolbar_from_data() -> void:
	var n := str(level_data.get("name", "Custom Stage"))
	_name_edit.text = n
	_name_committed = n
	var cols := int(level_data.get("grid_cols", 48))
	var rows := int(level_data.get("grid_rows", 12))
	var matched_idx := -1
	for i in range(GRID_PRESETS.size()):
		if GRID_PRESETS[i] == Vector2i(cols, rows):
			matched_idx = i
			break
	_size_opt.selected = matched_idx
	_bg_btn.text = "%s %s" % [LocalePack.tr_key("ed_bg"), str(level_data.get("background", "FOREST"))]
	var dv := float(level_data.get("dim", 0.55))
	_dim_slider.set_value_no_signal(dv)
	_dim_committed = dv
	_p1_opt.selected = maxi(0, FORMS.find(str(level_data.get("start_form_p1", "CUBE"))))
	_p2_opt.selected = maxi(0, FORMS.find(str(level_data.get("start_form_p2", "CUBE"))))


func _apply_locale() -> void:
	_name_edit.placeholder_text = LocalePack.tr_key("ed_name_placeholder")
	_bg_btn.text = "%s %s" % [LocalePack.tr_key("ed_bg"), str(level_data.get("background", "FOREST"))]
	_undo_btn.text = LocalePack.tr_key("ed_undo")
	_redo_btn.text = LocalePack.tr_key("ed_redo")
	_grid_btn.text = LocalePack.tr_key("ed_grid")
	_validate_btn.text = LocalePack.tr_key("ed_validate")
	_playtest_btn.text = LocalePack.tr_key("ed_playtest")
	_save_btn.text = LocalePack.tr_key("ed_save")
	_export_btn.text = LocalePack.tr_key("ed_export")
	_exit_btn.text = LocalePack.tr_key("ed_exit")
	_select_btn.text = LocalePack.tr_key("ed_tool_select")
	_erase_btn.text = LocalePack.tr_key("ed_tool_erase")
	var tab_keys := ["ed_tab_terrain", "ed_tab_hazards", "ed_tab_portals", "ed_tab_mech", "ed_tab_deco"]
	for i in range(mini(_tabs.get_tab_count(), tab_keys.size())):
		_tabs.set_tab_title(i, LocalePack.tr_key(tab_keys[i]))


func _populate_palette() -> void:
	for tab_idx in range(_tabs.get_tab_count()):
		var scroll := _tabs.get_child(tab_idx) as ScrollContainer
		if scroll == null or scroll.get_child_count() == 0:
			continue
		var vbox := scroll.get_child(0) as VBoxContainer
		for c in vbox.get_children():
			vbox.remove_child(c)
			c.queue_free()
		for item in CustomLevelCatalog.items_for_tab(tab_idx):
			var btn := PaletteItemButton.new()
			btn.setup(item, LocalePack.tr_key(str(item.get("label_key", ""))), str(item.get("icon", "")))
			btn.item_activated.connect(func(d: Dictionary) -> void:
				_canvas.set_tool(d)
				_set_status(LocalePack.tr_key(str(d.get("label_key", ""))))
			)
			vbox.add_child(btn)


func _bind_signals() -> void:
	_name_edit.text_changed.connect(func(nt: String) -> void: level_data["name"] = nt)
	var commit_name := func() -> void:
		if _name_edit.text != _name_committed:
			_name_committed = _name_edit.text
			level_data["name"] = _name_committed
			_push_snapshot(level_data)
	_name_edit.text_submitted.connect(func(_nt: String) -> void:
		commit_name.call()
		_name_edit.release_focus()
	)
	_name_edit.focus_exited.connect(commit_name)
	_size_opt.item_selected.connect(_on_size_selected)
	_bg_btn.pressed.connect(_on_bg_toggled)
	_dim_slider.value_changed.connect(func(v: float) -> void:
		level_data["dim"] = v
		_canvas.update_background_dim(v)
	)
	_dim_slider.drag_ended.connect(func(changed: bool) -> void:
		if changed or not is_equal_approx(float(level_data.get("dim", 0.55)), _dim_committed):
			_dim_committed = float(level_data.get("dim", 0.55))
			_push_snapshot(level_data)
	)
	_p1_opt.item_selected.connect(func(idx: int) -> void:
		level_data["start_form_p1"] = FORMS[idx]
		_push_snapshot(level_data)
	)
	_p2_opt.item_selected.connect(func(idx: int) -> void:
		level_data["start_form_p2"] = FORMS[idx]
		_push_snapshot(level_data)
	)

	_undo_btn.pressed.connect(undo)
	_redo_btn.pressed.connect(redo)
	_grid_btn.pressed.connect(func() -> void:
		_canvas.show_grid = not _canvas.show_grid
		_canvas.rebuild_all()
	)
	_validate_btn.pressed.connect(_on_validate_pressed)
	_playtest_btn.pressed.connect(_on_playtest_pressed)
	_save_btn.pressed.connect(_on_save_pressed)
	_export_btn.pressed.connect(_on_export_pressed)
	_exit_btn.pressed.connect(_on_exit_pressed)

	_select_btn.pressed.connect(func() -> void:
		_canvas.set_tool({"kind": "select"})
		_set_status(LocalePack.tr_key("ed_tool_select"))
	)
	_erase_btn.pressed.connect(func() -> void:
		_canvas.set_tool({"kind": "erase"})
		_set_status(LocalePack.tr_key("ed_tool_erase"))
	)

	_canvas.data_mutated.connect(func(push_hist: bool, _reason: String) -> void:
		if push_hist:
			_push_snapshot(level_data)
	)
	_canvas.selection_changed.connect(func(_id: String) -> void: _inspector.rebuild())
	_canvas.hover_cell_changed.connect(func(c: Vector2i) -> void: _coords_lbl.text = "(%d, %d)" % [c.x, c.y])
	_canvas.link_completed.connect(func(msg: String) -> void: _set_status(msg))

	_inspector.property_changed.connect(func(push_hist: bool) -> void:
		if push_hist:
			_push_snapshot(level_data)
	)
	_inspector.request_link_wire.connect(func(uid: String, mode_name: String) -> void:
		_canvas.start_wire_link(uid, mode_name)
		_set_status(LocalePack.tr_key("ed_insp_link_start"))
	)
	_inspector.request_rotate.connect(func() -> void: _canvas.rotate_selected())
	_inspector.request_duplicate.connect(func() -> void: _canvas.duplicate_selected())
	_inspector.request_delete.connect(func() -> void: _canvas.delete_object(_canvas.selected_id))


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.keycode == KEY_SPACE and not _is_typing_text() and _canvas != null and _canvas._hover_inside:
			# Prevent focused toolbar/palette buttons from activating via ui_select while Space+Dragging to pan
			var fo := get_viewport().gui_get_focus_owner()
			if fo != null and fo != _canvas:
				_canvas.grab_focus()
				get_viewport().set_input_as_handled()


func _is_typing_text() -> bool:
	var fo := get_viewport().gui_get_focus_owner()
	return fo is LineEdit or fo is TextEdit


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var typing := _is_typing_text()
	if k.ctrl_pressed and k.keycode == KEY_Z and not typing:
		undo()
	elif k.ctrl_pressed and k.keycode == KEY_Y and not typing:
		redo()
	elif k.ctrl_pressed and k.keycode == KEY_S:
		_on_save_pressed()
	elif k.ctrl_pressed and k.keycode == KEY_D and not typing:
		_canvas.duplicate_selected()
	elif k.keycode == KEY_F5:
		_on_playtest_pressed()
	elif k.keycode == KEY_DELETE and not typing:
		_canvas.delete_object(_canvas.selected_id)
	elif k.keycode == KEY_R and not typing:
		_canvas.rotate_selected()
	elif k.keycode == KEY_ESCAPE and str(_canvas.active_tool.get("kind", "")) == "link":
		_canvas.set_tool({"kind": "select"})
		_set_status(LocalePack.tr_key("ed_status_ready"))


func _on_size_selected(idx: int) -> void:
	var preset: Vector2i = GRID_PRESETS[clampi(idx, 0, GRID_PRESETS.size() - 1)]
	level_data["grid_cols"] = preset.x
	level_data["grid_rows"] = preset.y
	level_data["ascii_map"] = CustomLevelCatalog.resize_ascii_map(level_data.get("ascii_map", []), preset.x, preset.y)
	_canvas.load_data(level_data, false)
	_push_snapshot(level_data)


func _on_bg_toggled() -> void:
	var cur := str(level_data.get("background", "FOREST"))
	level_data["background"] = "BRIGHT" if cur == "FOREST" else "FOREST"
	_bg_btn.text = "%s %s" % [LocalePack.tr_key("ed_bg"), str(level_data["background"])]
	_canvas.rebuild_all()
	_push_snapshot(level_data)


func _push_snapshot(snap: Dictionary) -> void:
	_undo_stack.append(snap.duplicate(true))
	if _undo_stack.size() > MAX_HISTORY:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_refresh_history_buttons()


func undo() -> bool:
	if _undo_stack.size() <= 1:
		return false
	var current := _undo_stack.pop_back() as Dictionary
	_redo_stack.append(current)
	level_data = (_undo_stack.back() as Dictionary).duplicate(true)
	_canvas.load_data(level_data, false)
	_sync_toolbar_from_data()
	_inspector.rebuild()
	_refresh_history_buttons()
	return true


func redo() -> bool:
	if _redo_stack.is_empty():
		return false
	var nxt := _redo_stack.pop_back() as Dictionary
	_undo_stack.append(nxt.duplicate(true))
	level_data = nxt.duplicate(true)
	_canvas.load_data(level_data, false)
	_sync_toolbar_from_data()
	_inspector.rebuild()
	_refresh_history_buttons()
	return true


func _refresh_history_buttons() -> void:
	if _undo_btn != null:
		_undo_btn.disabled = _undo_stack.size() <= 1
	if _redo_btn != null:
		_redo_btn.disabled = _redo_stack.is_empty()


func _on_validate_pressed() -> Dictionary:
	var res := CustomLevelCatalog.validate_level_data(level_data)
	var errs := res.get("errors", []) as Array
	var warns := res.get("warnings", []) as Array
	if not errs.is_empty():
		_set_status("ERROR: " + " | ".join(errs), Color(1.0, 0.4, 0.4))
	elif not warns.is_empty():
		_set_status("WARN: " + " | ".join(warns), Color(1.0, 0.82, 0.3))
	else:
		_set_status(LocalePack.tr_key("ed_valid_ok", [(level_data.get("objects", []) as Array).size()]), Color(0.35, 1.0, 0.65))
	return res


func _on_save_pressed() -> String:
	AudioManager.play_sfx("click")
	var saved := CustomLevelStore.save_level(level_data, source_path)
	if saved != "":
		source_path = saved
		var mgr := get_node_or_null("/root/LevelManager")
		if mgr != null:
			mgr.call("rescan")
		_set_status(LocalePack.tr_key("ed_saved_ok", [saved]), Color(0.35, 1.0, 0.65))
	else:
		_set_status(LocalePack.tr_key("ed_saved_err"), Color(1.0, 0.4, 0.4))
	return saved


func _on_export_pressed() -> void:
	AudioManager.play_sfx("click")
	DisplayServer.clipboard_set(CustomLevelStore.export_json_string(level_data))
	_set_status(LocalePack.tr_key("hub_copied"), Color(0.35, 1.0, 0.65))


func _on_playtest_pressed() -> void:
	AudioManager.play_sfx("click")
	var res := _on_validate_pressed()
	if not bool(res.get("ok", false)):
		return
	var mgr := get_node_or_null("/root/LevelManager")
	if mgr != null and mgr.has_method("start_playtest"):
		mgr.call("start_playtest", level_data, source_path)


func _on_exit_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file(HUB_SCENE)


func _set_status(msg: String, col: Color = Color(0.84, 0.95, 1.0)) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg
		_status_lbl.add_theme_color_override("font_color", col)
