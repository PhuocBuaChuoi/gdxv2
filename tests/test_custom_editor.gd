extends "res://tests/gdx_test.gd"

## Custom Level Editor, Portable `.gdx.json` Store, Catalog, Builder, Wiring & Undo/Redo tests.


func test_catalog_covers_all_assets_and_validation() -> void:
	var all_types := {}
	var deco_count := 0
	for item in CustomLevelCatalog.PALETTE_ITEMS:
		var t := str(item.get("type", item.get("id", "")))
		all_types[t] = true
		if t == "DecoProp":
			deco_count += 1
	assert_true(deco_count == 6, "Catalog co du 6 asset trang tri DecoProp")
	for req in ["SpikeHazard", "LaserHazard", "FormPortal", "GravityPortal", "JumpPad", "JumpOrb", "DashOrb", "PressureButton", "MechanizedPlatform", "EnergyGate", "BreakableDashBlock", "CoopBox", "BalancedFloatPair", "RestorePoint", "DualExitGate", "ControlSign"]:
		assert_true(all_types.has(req), "Catalog co du loai " + req)

	var empty_data := {"ascii_map": ["="], "objects": []}
	var bad_res := CustomLevelCatalog.validate_level_data(empty_data)
	assert_true(not bool(bad_res["ok"]), "Validate tu choi man thieu spawn/gate")

	var good_data := CustomLevelCatalog.default_level_data("Test Stage")
	var good_res := CustomLevelCatalog.validate_level_data(good_data)
	assert_true(bool(good_res["ok"]), "Default template hop le")


func test_portable_gdx_json_store_round_trip() -> void:
	var tmp_dir := OS.get_temp_dir().path_join("gdxv2_custom_store_test_%d" % Time.get_ticks_msec())
	var data := CustomLevelCatalog.default_level_data("Portable Sky Bridge")
	(data["objects"] as Array).append({
		"uid": "btn_a", "type": "PressureButton", "container": "Mechanisms",
		"pos": [480.0, 420.0], "props": {"mode": 0, "activator": 1, "paired_uid": "", "pair_window": 0.5},
	})
	(data["objects"] as Array).append({
		"uid": "gate_a", "type": "EnergyGate", "container": "Mechanisms",
		"pos": [960.0, 360.0], "props": {"gate_size": [2, 3], "require_all": true, "open_time": 0.18, "linked_uids": ["btn_a"]},
	})

	var saved := CustomLevelStore.save_level(data, "", tmp_dir)
	assert_true(saved.ends_with(".gdx.json"), "Luu dung duoi .gdx.json")
	assert_true(FileAccess.file_exists(saved), "File portable .gdx.json ton tai")

	var listed := CustomLevelStore.list_levels(tmp_dir)
	assert_eq(listed.size(), 1, "Quet duoc 1 man custom trong thu muc")
	var loaded := CustomLevelStore.load_file(saved)
	assert_eq(str(loaded.get("name", "")), "Portable Sky Bridge", "Doc dung ten man")
	assert_eq((loaded.get("objects", []) as Array).size(), 3, "Doc du 3 objects")

	var json_str := CustomLevelStore.export_json_string(loaded)
	var imp := CustomLevelStore.import_json_string(json_str, tmp_dir)
	assert_true(bool(imp["ok"]), "Import JSON string thanh cong")

	var dup := CustomLevelStore.duplicate_file(saved, tmp_dir)
	assert_true(dup != "" and FileAccess.file_exists(dup), "Nhan ban file .gdx.json thanh cong")

	for f in CustomLevelStore.list_level_files(tmp_dir):
		CustomLevelStore.delete_file(f)
	DirAccess.remove_absolute(tmp_dir)


func test_custom_level_builder_wires_triggers_and_terrain() -> void:
	var data := CustomLevelCatalog.default_level_data("Runtime Builder Test")
	var objs := data["objects"] as Array
	objs.append({
		"uid": "btn_1", "type": "PressureButton", "container": "Mechanisms",
		"pos": [528.0, 420.0], "props": {"mode": 0, "activator": 0},
	})
	objs.append({
		"uid": "plat_1", "type": "MechanizedPlatform", "container": "Mechanisms",
		"pos": [720.0, 336.0], "props": {"move_offset": [0.0, -96.0], "speed": 140.0, "require_all": false, "linked_uids": ["btn_1"]},
	})
	objs.append({
		"uid": "egate_1", "type": "EnergyGate", "container": "Mechanisms",
		"pos": [1056.0, 360.0], "props": {"gate_size": [2, 3], "require_all": true, "open_time": 0.18, "linked_uids": ["btn_1"]},
	})
	objs.append({
		"uid": "deco_1", "type": "DecoProp", "container": "Decorations",
		"pos": [300.0, 432.0], "props": {"prop_type": 4, "flip_h": true},
	})

	var lvl := CustomLevelBuilder.build_scene(data, 6, "res://levels/custom/test.gdx.json", false)
	assert_true(lvl != null, "CustomLevelBuilder dung scene thanh cong")
	host_root.add_child(lvl)

	assert_true(bool(lvl.get_meta("is_custom_level", false)), "Gan meta custom_level")
	var layer := lvl.get_node("TerrainLayer") as TileMapLayer
	assert_true(layer.get_used_cells().size() >= 96, "TerrainLayer ve du san 48x2 tu ascii_map")

	var btn := lvl.get_node("Mechanisms/btn_1") as PressureButton
	var plat := lvl.get_node("Mechanisms/plat_1") as MechanizedPlatform
	var egate := lvl.get_node("Mechanisms/egate_1") as EnergyGate
	assert_true(btn != null and plat != null and egate != null, "Du button/platform/energy_gate")
	assert_eq(plat.linked_triggers.size(), 1, "Platform duoc noi day trigger")
	assert_eq(plat.get_node_or_null(plat.linked_triggers[0]), btn, "Platform linked_triggers tro dung PressureButton")
	assert_eq(egate.get_node_or_null(egate.linked_triggers[0]), btn, "EnergyGate linked_triggers tro dung PressureButton")

	btn.set("is_on", true)
	egate.call("_physics_process", 1.0 / 60.0)
	assert_true(egate.is_open, "EnergyGate mo that khi PressureButton bat")

	host_root.remove_child(lvl)
	lvl.free()


func test_level_manager_orders_custom_after_initial_six() -> void:
	var tmp_file := CustomLevelStore.RES_CUSTOM_DIR.path_join("_test_ordering_probe.gdx.json")
	var data := CustomLevelCatalog.default_level_data("Ordering Probe")
	CustomLevelStore.save_level(data, tmp_file)

	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	var list := mgr.get("levels") as Array
	assert_true(list.size() >= 7, "Co it nhat 6 man goc + 1 man custom")
	assert_eq(list[0], "res://levels/level_01.tscn", "Index 0 la Man 1")
	assert_eq(list[5], "res://levels/level_06.tscn", "Index 5 la Man 6")
	assert_true(bool(mgr.call("is_custom_index", 6)), "Man custom xep sau 6 man khoi dau (>= index 6)")

	CustomLevelStore.delete_file(tmp_file)
	host_root.remove_child(mgr)
	mgr.free()


func test_editor_drag_drop_and_undo_redo() -> void:
	var ed := (load("res://ui/level_editor.tscn") as PackedScene).instantiate() as LevelEditor
	host_root.add_child(ed)
	var canvas := ed.get_node("RootVBox/MainHSplit/CanvasFrame/EditorCanvas") as EditorCanvas
	var initial_count := (ed.level_data["objects"] as Array).size()

	# Simulate Drag-and-Drop placement from Palette onto Canvas
	var drop_item := CustomLevelCatalog.find_palette_item("spike_cyan")
	canvas._drop_data(Vector2(300, 300), {"from_palette": true, "item": drop_item})
	assert_eq((ed.level_data["objects"] as Array).size(), initial_count + 1, "Keo tha tu Palette dat object thanh cong")

	canvas.rotate_selected()
	var placed := (ed.level_data["objects"] as Array).back() as Dictionary
	assert_eq(int((placed["props"] as Dictionary)["orientation"]), 1, "Xoay SpikeHazard thanh cong")

	assert_true(ed.undo(), "Undo lan 1 hoan tac xoay")
	var after_u1 := (ed.level_data["objects"] as Array).back() as Dictionary
	assert_eq(int((after_u1["props"] as Dictionary)["orientation"]), 0, "Orientation tro ve 0 sau Undo")

	assert_true(ed.undo(), "Undo lan 2 xoa object vua tha")
	assert_eq((ed.level_data["objects"] as Array).size(), initial_count, "So object tro ve ban dau sau Undo")

	assert_true(ed.redo(), "Redo dat lai object")
	assert_eq((ed.level_data["objects"] as Array).size(), initial_count + 1, "Redo khoi phuc object")

	host_root.remove_child(ed)
	ed.free()


func test_custom_levels_hub_meta_import_and_texture_filter() -> void:
	var hub := (load("res://ui/custom_levels_hub.tscn") as PackedScene).instantiate() as Control
	assert_true(hub != null, "Load duoc custom_levels_hub.tscn")
	assert_eq(hub.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "Root Control cua CustomLevelsHub co texture_filter = 1 (NEAREST)")
	host_root.add_child(hub)

	# 1. _format_meta() doc grid_cols / grid_rows tu default_level_data() va fallback grid_width / grid_height
	var def_data := CustomLevelCatalog.default_level_data("Hub Meta Stage", 48, 12)
	var meta_str: String = str(hub.call("_format_meta", "res://levels/custom/hub_meta.gdx.json", def_data))
	assert_true(meta_str.contains("48x12"), "_format_meta hien thi dung grid_cols x grid_rows (48x12)")
	var legacy_data := {"grid_width": 32, "grid_height": 16, "objects": [], "background": "CYBER"}
	var legacy_meta: String = str(hub.call("_format_meta", "", legacy_data))
	assert_true(legacy_meta.contains("32x16"), "_format_meta van fallback grid_width x grid_height (32x16)")
	var null_meta_data := {"grid_cols": null, "grid_rows": null, "background": null, "ascii_map": ["==========", "=========="]}
	var null_meta: String = str(hub.call("_format_meta", "", null_meta_data))
	assert_true(not null_meta.contains("<null>"), "_format_meta khong hien <null> khi field JSON bi null")
	assert_true(null_meta.contains("10x2"), "_format_meta fallback kich thuoc tu ascii_map khi thieu grid_cols/grid_rows")

	# 2. Import JSON string qua UI khong duoc luu trung lap _2.gdx.json
	var unique_name := "HubImportNoDup_%d" % Time.get_ticks_msec()
	var imp_data := CustomLevelCatalog.default_level_data(unique_name, 36, 12)
	var slug := CustomLevelStore.slugify(unique_name)
	var before_files := CustomLevelStore.list_level_files()

	hub.call("_open_import_dialog")
	var import_input := hub.get_node("ImportOverlay/ImportCenter/ImportDialog/DialogVBox/ImportInput") as TextEdit
	var import_err := hub.get_node("ImportOverlay/ImportCenter/ImportDialog/DialogVBox/ImportErrorLabel") as Label
	var import_overlay := hub.get_node("ImportOverlay") as ColorRect

	# Empty / invalid JSON payload -> hien loi, khong dong dialog
	import_input.text = "   "
	hub.call("_on_confirm_import_pressed")
	assert_true(import_err.visible, "Import rong phai hien thong bao loi")
	assert_true(import_overlay.visible, "Dialog giu nguyen khi import rong")

	import_input.text = "{\"missing_ascii\": true}"
	hub.call("_on_confirm_import_pressed")
	assert_true(import_err.visible, "Import JSON thieu ascii_map phai hien thong bao loi")
	assert_true(import_overlay.visible, "Dialog giu nguyen khi import loi")

	# Valid JSON string -> luu dung 1 file, khong tao _2.gdx.json
	import_input.text = CustomLevelStore.export_json_string(imp_data)
	hub.call("_on_confirm_import_pressed")
	assert_true(not import_overlay.visible, "Import hop le phai dong dialog")

	var after_files := CustomLevelStore.list_level_files()
	assert_eq(after_files.size(), before_files.size() + 1, "Import JSON chi luu dung 1 file moi (khong luu trung lan 2)")
	var created_files: Array[String] = []
	for f in after_files:
		if not before_files.has(f):
			created_files.append(f)
	assert_eq(created_files.size(), 1, "Chi co duy nhat 1 file moi duoc tao")
	if created_files.size() == 1:
		assert_true(created_files[0].ends_with("/%s.gdx.json" % slug), "Ten file luu dung slug goc, khong bi _2.gdx.json")
	var levels_list := hub.get_node("SafeMargin/MainVBox/BodyPanel/BodyVBox/ScrollContainer/LevelsList") as VBoxContainer
	var found_rendered_row := false
	for row_node in levels_list.get_children():
		var row_labels: Array[Node] = row_node.find_children("*", "Label", true, false)
		var has_name := false
		var has_meta := false
		for lbl_node in row_labels:
			var t := (lbl_node as Label).text
			if t == unique_name:
				has_name = true
			if t.contains("%s.gdx.json" % slug) and t.contains("36x12"):
				has_meta = true
		if has_name and has_meta:
			found_rendered_row = true
			break
	assert_true(found_rendered_row, "Row render trong LevelsList hien dung ten va metadata 36x12 sau khi import")

	# Duplicate & Delete qua hub methods
	if created_files.size() == 1:
		hub.call("_on_duplicate_entry", created_files[0])
		var after_dup := CustomLevelStore.list_level_files()
		assert_eq(after_dup.size(), after_files.size() + 1, "Duplicate qua hub tao them dung 1 ban sao")
		for f in after_dup:
			if not before_files.has(f):
				hub.call("_on_delete_entry", f)
		var after_del := CustomLevelStore.list_level_files()
		assert_eq(after_del.size(), before_files.size(), "Delete qua hub xoa sach file vua tao")
	else:
		for cf in created_files:
			CustomLevelStore.delete_file(cf)

	# 3. Import tu file path (.gdx.json) voi single quotes -> cung chi luu dung 1 file moi
	var tmp_src := OS.get_temp_dir().path_join("%s_src.gdx.json" % slug)
	var f_src := FileAccess.open(tmp_src, FileAccess.WRITE)
	assert_true(f_src != null, "Tao file nguon tam thanh cong")
	if f_src != null:
		f_src.store_string(CustomLevelStore.export_json_string(imp_data))
		f_src.close()
	var before_file_imp := CustomLevelStore.list_level_files()
	hub.call("_open_import_dialog")
	import_input.text = "'" + tmp_src + "'"
	hub.call("_on_confirm_import_pressed")
	var after_file_imp := CustomLevelStore.list_level_files()
	assert_eq(after_file_imp.size(), before_file_imp.size() + 1, "Import tu file path chi luu dung 1 file moi")
	for f in after_file_imp:
		if not before_file_imp.has(f):
			CustomLevelStore.delete_file(f)
	if FileAccess.file_exists(tmp_src):
		DirAccess.remove_absolute(tmp_src)
	LevelManager.rescan()

	host_root.remove_child(hub)
	hub.free()
