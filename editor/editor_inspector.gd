class_name GdxEditorInspector
extends VBoxContainer

## Dynamic property inspector for the currently selected spawn or placed object in EditorCanvas.

signal property_changed(push_history: bool)
signal request_link_wire(uid: String, mode_name: String)
signal request_rotate()
signal request_duplicate()
signal request_delete()

var _canvas: EditorCanvas = null
var _building: bool = false


func bind_canvas(canvas: EditorCanvas) -> void:
	_canvas = canvas
	rebuild()


func rebuild() -> void:
	_building = true
	for c in get_children():
		remove_child(c)
		c.queue_free()

	if _canvas == null or _canvas.selected_id == "":
		var empty_lbl := Label.new()
		empty_lbl.text = LocalePack.tr_key("ed_insp_none")
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.add_theme_font_size_override("font_size", 15)
		empty_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98, 0.9))
		add_child(empty_lbl)
		_building = false
		return

	var sid := _canvas.selected_id
	if sid == "spawn_p1" or sid == "spawn_p2":
		_add_header("Spawn P1" if sid == "spawn_p1" else "Spawn P2")
		var arr := _canvas.level_data.get(sid, [144.0, 384.0]) as Array
		_add_vec2_row(LocalePack.tr_key("ed_insp_pos"), Vector2(float(arr[0]), float(arr[1])), func(v: Vector2) -> void:
			_canvas.level_data[sid] = [v.x, v.y]
			_canvas.rebuild_all()
			property_changed.emit(true)
		)
		_building = false
		return

	var obj := _canvas.find_object(sid)
	if obj.is_empty():
		_building = false
		return

	var obj_type := str(obj.get("type", ""))
	var props := obj["props"] as Dictionary
	_add_header("%s" % obj_type)

	var p_arr := obj.get("pos", [0.0, 0.0]) as Array
	_add_vec2_row(LocalePack.tr_key("ed_insp_pos"), Vector2(float(p_arr[0]), float(p_arr[1])), func(v: Vector2) -> void:
		obj["pos"] = [v.x, v.y]
		_canvas.rebuild_all()
		property_changed.emit(true)
	)

	match obj_type:
		"SpikeHazard":
			_add_enum_row(LocalePack.tr_key("ed_prop_hazard_type"), ["NEUTRAL", "CYAN_SAFE_P1", "ORANGE_SAFE_P2"], int(props.get("hazard_type", 0)), func(v: int) -> void:
				props["hazard_type"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_spin_row(LocalePack.tr_key("ed_prop_tile_count"), 1.0, 16.0, 1.0, float(props.get("tile_count", 2)), func(v: float) -> void:
				props["tile_count"] = int(v)
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_enum_row(LocalePack.tr_key("ed_prop_orientation"), ["UP", "DOWN", "LEFT", "RIGHT"], int(props.get("orientation", 0)), func(v: int) -> void:
				props["orientation"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
		"LaserHazard":
			_add_enum_row(LocalePack.tr_key("ed_prop_hazard_type"), ["NEUTRAL", "CYAN_SAFE_P1", "ORANGE_SAFE_P2"], int(props.get("hazard_type", 0)), func(v: int) -> void:
				props["hazard_type"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_spin_row(LocalePack.tr_key("ed_prop_period"), 0.2, 10.0, 0.1, float(props.get("period", 2.0)), func(v: float) -> void:
				props["period"] = v
				property_changed.emit(true)
			)
			_add_spin_row(LocalePack.tr_key("ed_prop_duty"), 0.0, 1.0, 0.05, float(props.get("duty", 0.5)), func(v: float) -> void:
				props["duty"] = v
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_start_on"), bool(props.get("start_on", true)), func(v: bool) -> void:
				props["start_on"] = v
				property_changed.emit(true)
			)
		"FormPortal":
			var forms := ["CUBE", "SHIP", "UFO", "DASH"]
			var f_idx := maxi(0, forms.find(str(props.get("target_form", "CUBE"))))
			_add_enum_row(LocalePack.tr_key("ed_prop_target_form"), forms, f_idx, func(v: int) -> void:
				props["target_form"] = forms[v]
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			var players := ["BOTH", "P1_ONLY", "P2_ONLY"]
			var p_idx := maxi(0, players.find(str(props.get("allowed_player", "BOTH"))))
			_add_enum_row(LocalePack.tr_key("ed_prop_allowed_player"), players, p_idx, func(v: int) -> void:
				props["allowed_player"] = players[v]
				property_changed.emit(true)
			)
		"GravityPortal":
			_add_enum_row(LocalePack.tr_key("ed_prop_direction_mode"), ["FIXED", "TOGGLE"], int(props.get("direction_mode", 1)), func(v: int) -> void:
				props["direction_mode"] = v
				property_changed.emit(true)
			)
			var dir_idx := 1 if int(props.get("target_direction", -1)) >= 0 else 0
			_add_enum_row(LocalePack.tr_key("ed_prop_target_direction"), ["Inverted (-1)", "Normal (+1)"], dir_idx, func(v: int) -> void:
				props["target_direction"] = 1 if v == 1 else -1
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_one_shot"), bool(props.get("one_shot", false)), func(v: bool) -> void:
				props["one_shot"] = v
				property_changed.emit(true)
			)
		"JumpPad":
			_add_enum_row(LocalePack.tr_key("ed_prop_pad_type"), ["YELLOW", "PINK", "RED"], int(props.get("pad_type", 0)), func(v: int) -> void:
				props["pad_type"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
		"JumpOrb":
			_add_enum_row(LocalePack.tr_key("ed_prop_orb_type"), ["YELLOW", "BLUE", "DASH"], int(props.get("orb_type", 0)), func(v: int) -> void:
				props["orb_type"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
		"PressureButton":
			_add_enum_row(LocalePack.tr_key("ed_prop_mode"), ["HOLD", "TOGGLE", "SIMULTANEOUS"], int(props.get("mode", 0)), func(v: int) -> void:
				props["mode"] = v
				property_changed.emit(true)
			)
			_add_enum_row(LocalePack.tr_key("ed_prop_activator"), ["ANY", "P1_ONLY", "P2_ONLY", "HEAVY_BLOCK"], int(props.get("activator", 0)), func(v: int) -> void:
				props["activator"] = v
				property_changed.emit(true)
			)
			var pair_btn := Button.new()
			pair_btn.text = LocalePack.tr_key("ed_insp_pair_btn")
			pair_btn.pressed.connect(func() -> void: request_link_wire.emit(sid, "pair"))
			add_child(pair_btn)
		"MechanizedPlatform":
			var off := props.get("move_offset", [0.0, -96.0]) as Array
			_add_vec2_row("Offset", Vector2(float(off[0]), float(off[1])), func(v: Vector2) -> void:
				props["move_offset"] = [v.x, v.y]
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_spin_row(LocalePack.tr_key("ed_prop_speed"), 20.0, 500.0, 10.0, float(props.get("speed", 140.0)), func(v: float) -> void:
				props["speed"] = v
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_require_all"), bool(props.get("require_all", false)), func(v: bool) -> void:
				props["require_all"] = v
				property_changed.emit(true)
			)
			_add_wire_controls(sid, props)
		"EnergyGate":
			var gs := props.get("gate_size", [2, 3]) as Array
			_add_spin_row(LocalePack.tr_key("ed_prop_gate_w"), 1.0, 8.0, 1.0, float(gs[0]), func(v: float) -> void:
				props["gate_size"] = [int(v), int(gs[1])]
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_spin_row(LocalePack.tr_key("ed_prop_gate_h"), 1.0, 8.0, 1.0, float(gs[1]), func(v: float) -> void:
				props["gate_size"] = [int(gs[0]), int(v)]
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_require_all"), bool(props.get("require_all", true)), func(v: bool) -> void:
				props["require_all"] = v
				property_changed.emit(true)
			)
			_add_wire_controls(sid, props)
		"RestorePoint":
			_add_spin_row(LocalePack.tr_key("ed_prop_checkpoint_order"), 0.0, 20.0, 1.0, float(props.get("checkpoint_order", 1)), func(v: float) -> void:
				props["checkpoint_order"] = int(v)
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_require_both"), bool(props.get("require_both_players", false)), func(v: bool) -> void:
				props["require_both_players"] = v
				property_changed.emit(true)
			)
		"DualExitGate":
			_add_spin_row(LocalePack.tr_key("ed_prop_hold_time"), 0.1, 3.0, 0.1, float(props.get("hold_time", 0.5)), func(v: float) -> void:
				props["hold_time"] = v
				property_changed.emit(true)
			)
		"DecoProp":
			_add_enum_row("Asset", ["PYLON", "CRYSTALS", "FOLIAGE", "VINE", "TERMINAL", "ARROW"], int(props.get("prop_type", 0)), func(v: int) -> void:
				props["prop_type"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
			_add_check_row(LocalePack.tr_key("ed_prop_flip_h"), bool(props.get("flip_h", false)), func(v: bool) -> void:
				props["flip_h"] = v
				_canvas.rebuild_all()
				property_changed.emit(true)
			)
		"ControlSign":
			var l := Label.new()
			l.text = LocalePack.tr_key("ed_prop_sign_text")
			add_child(l)
			var te := LineEdit.new()
			te.text = str(props.get("text", "P1 & P2 CO-OP!"))
			te.text_changed.connect(func(nt: String) -> void:
				if _building: return
				props["text"] = nt
				_canvas.rebuild_all()
				property_changed.emit(false)
			)
			add_child(te)

	# Action buttons (Rotate / Duplicate / Delete)
	var sep := HSeparator.new()
	add_child(sep)
	if obj_type == "SpikeHazard" or obj_type == "DecoProp":
		var rbtn := Button.new()
		rbtn.text = LocalePack.tr_key("ed_insp_rotate")
		rbtn.pressed.connect(func() -> void: request_rotate.emit())
		add_child(rbtn)
	var dbtn := Button.new()
	dbtn.text = LocalePack.tr_key("ed_insp_duplicate")
	dbtn.pressed.connect(func() -> void: request_duplicate.emit())
	add_child(dbtn)
	var del_btn := Button.new()
	del_btn.text = LocalePack.tr_key("ed_insp_delete")
	del_btn.pressed.connect(func() -> void: request_delete.emit())
	add_child(del_btn)

	_building = false


func _add_wire_controls(sid: String, props: Dictionary) -> void:
	var links := props.get("linked_uids", []) as Array
	var lbl := Label.new()
	lbl.text = LocalePack.tr_key("ed_insp_links", [links.size()])
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)
	var link_btn := Button.new()
	link_btn.text = LocalePack.tr_key("ed_insp_link_btn")
	link_btn.pressed.connect(func() -> void: request_link_wire.emit(sid, "trigger"))
	add_child(link_btn)
	if not links.is_empty():
		var clr := Button.new()
		clr.text = LocalePack.tr_key("ed_insp_clear_links")
		clr.pressed.connect(func() -> void:
			props["linked_uids"] = []
			_canvas.rebuild_all()
			property_changed.emit(true)
			rebuild()
		)
		add_child(clr)


func _add_header(title_text: String) -> void:
	var lbl := Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
	add_child(lbl)


func _add_vec2_row(label_text: String, val: Vector2, on_change: Callable) -> void:
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 14)
	add_child(l)
	var row := HBoxContainer.new()
	var sx := SpinBox.new()
	sx.min_value = -2000
	sx.max_value = 8000
	sx.step = 12
	sx.value = val.x
	sx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sy := SpinBox.new()
	sy.min_value = -2000
	sy.max_value = 3000
	sy.step = 12
	sy.value = val.y
	sy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sx.value_changed.connect(func(nx: float) -> void:
		if not _building: on_change.call(Vector2(nx, sy.value))
	)
	sy.value_changed.connect(func(ny: float) -> void:
		if not _building: on_change.call(Vector2(sx.value, ny))
	)
	row.add_child(sx)
	row.add_child(sy)
	add_child(row)


func _add_spin_row(label_text: String, min_v: float, max_v: float, step_v: float, val: float, on_change: Callable) -> void:
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 14)
	add_child(l)
	var sb := SpinBox.new()
	sb.min_value = min_v
	sb.max_value = max_v
	sb.step = step_v
	sb.value = val
	sb.value_changed.connect(func(nv: float) -> void:
		if not _building: on_change.call(nv)
	)
	add_child(sb)


func _add_enum_row(label_text: String, items: Array, selected: int, on_change: Callable) -> void:
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 14)
	add_child(l)
	var ob := OptionButton.new()
	for it in items:
		ob.add_item(str(it))
	ob.selected = clampi(selected, 0, maxi(items.size() - 1, 0))
	ob.item_selected.connect(func(idx: int) -> void:
		if not _building: on_change.call(idx)
	)
	add_child(ob)


func _add_check_row(label_text: String, checked: bool, on_change: Callable) -> void:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = checked
	cb.toggled.connect(func(nv: bool) -> void:
		if not _building: on_change.call(nv)
	)
	add_child(cb)
