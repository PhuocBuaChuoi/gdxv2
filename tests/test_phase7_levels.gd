extends "res://tests/gdx_test.gd"

## Phase 7 độc lập (T7.01–T7.04): tileset, template màn, controller, LevelManager.


func test_tileset() -> void:
	var ts: TileSet = load("res://resources/gd_neon_tileset.tres") as TileSet
	assert_true(ts != null, "T7.01 tileset load duoc")
	assert_eq(ts.tile_size, Vector2i(48, 48), "T7.01 grid 48px khop hitbox player")
	assert_true(ts.get_physics_layers_count() >= 1, "T7.01 co physics layer")
	assert_eq(ts.get_physics_layer_collision_layer(0), 1, "T7.01 physics = Layer 1 World_Terrain")
	var src: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
	assert_true(src != null and src.texture != null, "T7.01 atlas co texture")
	for tx in range(4):
		assert_true(src.has_tile(Vector2i(tx, 0)), "T7.01 co tile (%d,0)" % tx)
	var solid: TileData = src.get_tile_data(Vector2i(0, 0), 0)
	assert_eq(solid.get_collision_polygons_count(0), 1, "T7.01 tile solid co 1 polygon")
	var pts: PackedVector2Array = solid.get_collision_polygon_points(0, 0)
	var mn: Vector2 = pts[0]
	var mx: Vector2 = pts[0]
	for p in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	assert_near(mx.x - mn.x, 48.0, 0.01, "T7.01 solid rong full o")
	assert_near(my_center_y(pts), 0.0, 0.01, "T7.01 solid can giua o (goc tile o giua)")
	assert_true(not solid.is_collision_polygon_one_way(0, 0), "T7.01 solid khong one-way")
	var slab: TileData = src.get_tile_data(Vector2i(2, 0), 0)
	assert_true(slab.is_collision_polygon_one_way(0, 0), "T7.01 be mong one-way")
	var deco: TileData = src.get_tile_data(Vector2i(3, 0), 0)
	assert_eq(deco.get_collision_polygons_count(0), 0, "T7.01 deco khong collision")


func my_center_y(pts: PackedVector2Array) -> float:
	var mn: float = pts[0].y
	var mx: float = pts[0].y
	for p in pts:
		mn = minf(mn, p.y)
		mx = maxf(mx, p.y)
	return (mn + mx) * 0.5


func test_base_level_structure() -> void:
	var ps: PackedScene = load("res://levels/base_level.tscn") as PackedScene
	assert_true(ps != null, "T7.02 base_level load duoc")
	var lvl: Node = ps.instantiate()
	assert_true(lvl.get_node_or_null("TerrainLayer") is TileMapLayer, "T7.02 co TerrainLayer")
	var terrain: TileMapLayer = lvl.get_node_or_null("TerrainLayer") as TileMapLayer
	assert_true(terrain.tile_set != null, "T7.02 TerrainLayer gan san tileset")
	for n in ["Hazards", "Portals", "Mechanisms", "Checkpoints", "Players"]:
		assert_true(lvl.get_node_or_null(n) is Node2D, "T7.02 container " + n)
	var s1: Marker2D = lvl.get_node_or_null("SpawnP1") as Marker2D
	var s2: Marker2D = lvl.get_node_or_null("SpawnP2") as Marker2D
	assert_true(s1 != null and s2 != null, "T7.02 co 2 spawn markers")
	assert_true(s1.position.x < s2.position.x, "T7.02 P1 trai, P2 phai")
	assert_true(lvl.get_node_or_null("CoopCamera") is Camera2D, "T7.02 CoopCamera (logic T5 sau)")
	assert_true(lvl.get_node_or_null("LevelHUD") is CanvasLayer, "T7.02 LevelHUD (UI T8 sau)")
	assert_true(lvl.get_node_or_null("DefaultWorldEnvironment") is WorldEnvironment, "T7.02 tai su dung env neon")
	lvl.free()


func test_level_controller() -> void:
	var lvl: Node = (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	assert_eq(int(lvl.get("level_index")), 0, "T7.03 level_index mac dinh 0")
	assert_eq(str(lvl.get("start_form_p1")), "CUBE", "T7.03 P1 bat dau Cube")
	assert_eq(str(lvl.get("start_form_p2")), "CUBE", "T7.03 P2 bat dau Cube")
	assert_true(bool(lvl.get("running")), "T7.03 vao man tu chay timer")
	lvl.call("_process", 0.5)
	assert_near(float(lvl.get("level_time")), 0.5, 0.001, "T7.03 timer tich luy")
	lvl.call("add_death")
	lvl.call("add_death")
	assert_eq(int(lvl.get("deaths")), 2, "T7.03 dem deaths")
	lvl.call("reset_stats")
	assert_eq(int(lvl.get("deaths")), 0, "T7.03 reset deaths")
	assert_near(float(lvl.get("level_time")), 0.0, 0.001, "T7.03 reset timer")
	assert_eq(lvl.call("get_spawn", 1), Vector2(-96, 0), "T7.03 spawn P1")
	assert_eq(lvl.call("get_spawn", 2), Vector2(96, 0), "T7.03 spawn P2")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_manager() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/LevelManager"), "*res://autoloads/level_manager.gd", "T7.04 autoload dang ky")
	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	assert_true(mgr.get("levels") is Array, "T7.04 quet danh sach level_*")
	assert_true(not bool(mgr.call("load_level", -1)), "T7.04 index am bi tu choi (khong doi scene)")
	assert_true(not bool(mgr.call("load_level", 999)), "T7.04 index qua lon bi tu choi")
	assert_eq(int(mgr.get("current_index")), -1, "load that bai khong doi current_index")
	assert_true(mgr.has_method("load_next_level"), "T7.04 co load_next_level")
	assert_true(mgr.has_method("reload_current_level"), "T7.04 co reload_current_level")
	var temp_save := OS.get_temp_dir().path_join("gdxv2_test_phase7_save_tmp.cfg")
	mgr.set("save_path", temp_save)
	mgr.call("record_result", 0, 95.5, 3)
	assert_true((mgr.get("best") as Dictionary).has("0"), "T7.04 record_result updates best got=%s" % str(mgr.get("best")))
	assert_true(FileAccess.file_exists(temp_save), "T7.04 save file exists")
	var mgr2: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	mgr2.set("save_path", temp_save)
	host_root.add_child(mgr2)
	mgr2.call("load_progress")
	assert_eq(int(mgr2.get("unlocked")), int(mgr.get("unlocked")), "T7.04 luu/tai unlocked")
	assert_true((mgr2.get("best") as Dictionary).has("0"), "T7.04 luu/tai best got=%s path=%s" % [str(mgr2.get("best")), str(mgr2.get("save_path"))])
	host_root.remove_child(mgr)
	host_root.remove_child(mgr2)
	mgr.free()
	mgr2.free()
	DirAccess.remove_absolute(temp_save)
	assert_true(not FileAccess.file_exists(temp_save), "T7.04 xoa file tam sau test")


func test_base_level_background() -> void:
	var lvl: Node = (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	var bg: Parallax2D = lvl.get_node_or_null("StageBackground") as Parallax2D
	assert_true(bg != null, "base_level tich hop StageBackground Parallax2D")
	if bg != null:
		assert_true(bg.get_node_or_null("FarLayer/Sprite2D") is Sprite2D, "background co sprite nen")
	lvl.free()


func test_level_01_loads_and_paints() -> void:
	var ps: PackedScene = load("res://levels/level_01.tscn") as PackedScene
	assert_true(ps != null, "level_01 load duoc")
	var lvl: Node = ps.instantiate()
	assert_eq(int(lvl.get("level_index")), 0, "level_01 index zero-based")
	host_root.add_child(lvl)
	var terrain: TileMapLayer = lvl.get_node("TerrainLayer") as TileMapLayer
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(0, 9)), Vector2i(1, 3), "san trai: vien N+W (mask 9)")
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(40, 6)), Vector2i(1, 3), "mep trai mep cao: vien N+W (mask 9)")
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(47, 7)), Vector2i(2, 1), "mep phai map: vien E (mask 2)")
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(1, 10)), Vector2i(0, 0), "long dat: khong vien (mask 0)")
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(36, 6)), Vector2i(2, 0), "cau mot chieu")
	assert_eq(terrain.get_cell_atlas_coords(Vector2i(20, 0)), Vector2i(-1, -1), "troi trong")
	var p1: Node2D = lvl.get_node("Players/PlayerP1") as Node2D
	var p2: Node2D = lvl.get_node("Players/PlayerP2") as Node2D
	assert_eq(p1.global_position, (lvl.get_node("SpawnP1") as Marker2D).global_position, "P1 dung vi tri spawn")
	assert_eq(p2.global_position, (lvl.get_node("SpawnP2") as Marker2D).global_position, "P2 dung vi tri spawn")
	for spawn_name in ["SpawnP1", "SpawnP2"]:
		var spawn := lvl.get_node(spawn_name) as Marker2D
		var tile := Vector2i(floori(spawn.position.x / 48.0), floori(spawn.position.y / 48.0))
		assert_eq(terrain.get_cell_source_id(tile), -1, "%s khong nam trong tile solid" % spawn_name)
	var cps: Array = lvl.get_node("Checkpoints").get_children()
	assert_eq(cps.size(), 2, "level_01 co 2 restore points")
	var orders: Array = []
	for c in cps:
		orders.append(int(c.get("checkpoint_order")))
	orders.sort()
	assert_eq(orders, [1, 2], "checkpoint order 1,2")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_01_uses_animated_character_skins() -> void:
	var lvl: Node = (load("res://levels/level_01.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var p1: Node = lvl.get_node("Players/PlayerP1")
	var p2: Node = lvl.get_node("Players/PlayerP2")
	assert_eq(str(p1.get("skin")), "BIRD", "Level 1 P1 dung skin bird")
	assert_eq(str(p2.get("skin")), "FROG", "Level 1 P2 dung skin frog")
	var jump_pad := lvl.get_node_or_null("Mechanisms/JumpPadStart")
	var gravity_orb := lvl.get_node_or_null("Mechanisms/GravityJumpOrb")
	assert_true(jump_pad != null and jump_pad.get_node_or_null("Glow") != null, "Level 1 co jump pad neon")
	assert_true(gravity_orb != null and gravity_orb.get_node_or_null("Glow") != null, "Level 1 co gravity orb neon")
	for player_name in ["Players/PlayerP1", "Players/PlayerP2"]:
		var player := lvl.get_node(player_name)
		var body := player.get_node_or_null("VisualRoot/SkinVisual/Body") as AnimatedSprite2D
		assert_true(body != null and body.is_playing(), "%s co AnimatedSprite2D dang chay" % player_name)
	var p1_body := p1.get_node("VisualRoot/SkinVisual/Body") as AnimatedSprite2D
	p1.call("_set_skin_animation", "jump")
	assert_eq(p1_body.sprite_frames.get_frame_count("default"), 1, "bird jump dung frame nhay")
	p1.set("gravity_direction", -1)
	p1.call("_update_skin_animation")
	assert_eq(str(p1.get("_skin_animation")), "flip", "bird dao gravity dung animation flip")
	assert_true(p1.get_node("VisualRoot/OutlineLine") is Line2D, "skin van giu vien neon procedural")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_01_coop_design_guarantees() -> void:
	var lvl: Node = (load("res://levels/level_01.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var terrain: TileMapLayer = lvl.get_node("TerrainLayer") as TileMapLayer
	# Ho gai rong hon tam nhay toi da => bat buoc phai phoi hop.
	var max_jump := (2.0 * GdxPlayer.JUMP_VELOCITY / GdxPlayer.BASE_GRAVITY) * GdxPlayer.MOVE_SPEED
	var gap_tiles := _longest_gap(terrain, 9)
	assert_true(float(gap_tiles) * 48.0 > max_jump + 16.0, "ho gai (%d o) > tam nhay %.1fpx" % [gap_tiles, max_jump])
	# Meo cao 3 o: tren tam nhay don, duoi tam nhay khi cuoi len dau dong doi.
	var floor_row := 9
	var ledge_row := 6
	var climb := float(floor_row - ledge_row) * 48.0
	var jump_height := GdxPlayer.JUMP_VELOCITY * GdxPlayer.JUMP_VELOCITY / (2.0 * GdxPlayer.BASE_GRAVITY)
	assert_true(climb > jump_height + 10.0, "meo cao %.0fpx > tam nhay don %.1fpx" % [climb, jump_height])
	assert_true(climb < jump_height + 51.0, "meo cao %.0fpx < tam nhay co dong doi %.1fpx" % [climb, jump_height + 51.0])
	var cyan := 0
	var orange := 0
	for h in lvl.get_node("Hazards").get_children():
		if h is SpikeHazard:
			if int(h.get("hazard_type")) == 1:
				cyan += 1
			elif int(h.get("hazard_type")) == 2:
				orange += 1
	assert_true(cyan >= 4, "co ho gai Cyan an toan cho P1 (%d)" % cyan)
	assert_true(orange >= 4, "co ho gai Orange an toan cho P2 (%d)" % orange)
	var btn_a := lvl.get_node("Mechanisms/ButtonA") as PressureButton
	var btn_b := lvl.get_node("Mechanisms/ButtonB") as PressureButton
	var btn_c := lvl.get_node("Mechanisms/ButtonC") as PressureButton
	assert_eq(btn_a.activator, 1, "ButtonA chi P1 bam")
	assert_eq(btn_b.activator, 2, "ButtonB chi P2 bam")
	assert_eq(btn_c.mode, 0, "ButtonC giu de nang thang may")
	var bridges_a := _linked_platforms(lvl, "../ButtonA")
	var bridges_b := _linked_platforms(lvl, "../ButtonB")
	assert_true(bridges_a.size() >= 4, "ButtonA mo cau cho P2 (%d nhip)" % bridges_a.size())
	assert_true(bridges_b.size() >= 4, "ButtonB mo cau cho P1 (%d nhip)" % bridges_b.size())
	for p in bridges_a + bridges_b:
		var platform := p as MechanizedPlatform
		assert_true(platform.move_offset != Vector2.ZERO, "%s co hanh trinh" % platform.name)
		var top := platform.position.y + platform.move_offset.y - 12.0
		assert_true(top > 288.0 and top < 420.0, "%s ha xuong tam voi (%0.0f)" % [platform.name, top])
	var lift_platforms := _linked_platforms(lvl, "../ButtonC")
	assert_eq(lift_platforms.size(), 1, "chi 1 thang may cho ButtonC")
	if lift_platforms.size() == 1:
		var lift := lift_platforms[0] as MechanizedPlatform
		assert_true(lift.move_offset.y < 0.0, "thang may di len")
		assert_near(lift.position.y + lift.move_offset.y - 12.0, 288.0, 0.5, "thang may len ngang mep cao")
	host_root.remove_child(lvl)
	lvl.free()


func _longest_gap(layer: TileMapLayer, row: int) -> int:
	var best := 0
	var run := 0
	var width := layer.get_used_rect().size.x
	for x in range(0, width):
		if layer.get_cell_source_id(Vector2i(x, row)) == -1:
			run += 1
			best = maxi(best, run)
		else:
			run = 0
	return best


func _linked_platforms(lvl: Node, trigger_path: String) -> Array:
	var found: Array = []
	for child in lvl.get_node("Mechanisms").get_children():
		if child is MechanizedPlatform:
			for p in (child as MechanizedPlatform).linked_triggers:
				if String(p) == trigger_path:
					found.append(child)
					break
	return found


func test_main_scene_launches_level_01() -> void:
	var main: Node = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate()
	var level := main.get_node_or_null("Level01")
	assert_true(level != null and level.get_script() == load("res://levels/level_controller.gd"), "Main instance Level 1")
	assert_true(main.get_node_or_null("BaseLevel") == null, "Main khong instance base template")
	var manager := host_root.get_node_or_null("/root/LevelManager")
	if manager != null:
		host_root.add_child(main)
		assert_eq(int(manager.get("current_index")), 0, "Main dong bo current_index Level 1")
		host_root.remove_child(main)
	main.free()


func test_manager_finds_level_01() -> void:
	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	assert_true((mgr.get("levels") as Array).has("res://levels/level_01.tscn"), "manager tu thay level_01 khong can dang ky")
	host_root.remove_child(mgr)
	mgr.free()


func test_level_background_select() -> void:
	var lvl: Node = (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	assert_eq(str(lvl.get("background")), "FOREST", "mac dinh nen rung (hanh vi cu)")
	var spr_before: Sprite2D = lvl.get_node_or_null("StageBackground/FarLayer/Sprite2D") as Sprite2D
	assert_true(spr_before != null, "background sprite ton tai ban dau")
	if spr_before != null:
		assert_near(float(spr_before.texture.get_width()), 1199.0, 1.0, "nen mac dinh la forest")
	lvl.set("background", "BRIGHT")
	var spr_after: Sprite2D = lvl.get_node_or_null("StageBackground/FarLayer/Sprite2D") as Sprite2D
	assert_true(spr_after != null, "background sprite van ton sau khi doi")
	if spr_after != null:
		assert_near(float(spr_after.texture.get_width()), 1199.0, 1.0, "doi nen sang theo cau hinh man")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_02_loads_and_paints() -> void:
	var ps: PackedScene = load("res://levels/level_02.tscn") as PackedScene
	assert_true(ps != null, "level_02 load duoc")
	var lvl: Node = ps.instantiate()
	assert_eq(int(lvl.get("level_index")), 1, "level_02 index 1")
	assert_eq(str(lvl.get("background")), "BRIGHT", "level_02 background BRIGHT")
	host_root.add_child(lvl)

	var portal := lvl.get_node_or_null("Portals/ShipPortal")
	assert_true(portal != null, "level_02 co ShipPortal (T7.06)")
	assert_eq(str(portal.get("target_form")), "SHIP", "portal chuyen thanh SHIP")
	assert_eq(str(portal.get("allowed_player")), "P1_ONLY", "portal danh rieng cho P1_ONLY")

	var hazards := lvl.get_node_or_null("Hazards")
	assert_true(hazards != null and hazards.get_child_count() >= 3, "level_02 co ho gai can tau co-op cho qua")

	var button := lvl.get_node_or_null("Mechanisms/PressureButton")
	var box := lvl.get_node_or_null("Mechanisms/CoopBox")
	var door := lvl.get_node_or_null("Mechanisms/DoorPlatform") as MechanizedPlatform
	var gate := lvl.get_node_or_null("Mechanisms/DualExitGate")
	assert_true(button != null, "level_02 co PressureButton")
	assert_true(box != null, "level_02 co CoopBox de Ship dung tether keo")
	assert_true(door != null, "level_02 co DoorPlatform chan loi di")
	assert_true(gate != null, "level_02 co DualExitGate")
	assert_true(door.linked_triggers.has(NodePath("../PressureButton")), "DoorPlatform duoc noi day voi PressureButton")

	var p1: Node2D = lvl.get_node("Players/PlayerP1") as Node2D
	var p2: Node2D = lvl.get_node("Players/PlayerP2") as Node2D
	assert_eq(p1.global_position, (lvl.get_node("SpawnP1") as Marker2D).global_position, "P1 dung vi tri spawn")
	assert_eq(p2.global_position, (lvl.get_node("SpawnP2") as Marker2D).global_position, "P2 dung vi tri spawn")

	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	assert_true((mgr.get("levels") as Array).has("res://levels/level_02.tscn"), "manager tu dong thay level_02")
	host_root.remove_child(mgr)
	mgr.free()

	host_root.remove_child(lvl)
	lvl.free()


func test_level_02_coop_design_guarantees() -> void:
	var lvl: Node = (load("res://levels/level_02.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var terrain: TileMapLayer = lvl.get_node("TerrainLayer") as TileMapLayer
	var max_jump := (2.0 * GdxPlayer.JUMP_VELOCITY / GdxPlayer.BASE_GRAVITY) * GdxPlayer.MOVE_SPEED
	var gap_tiles := _longest_gap(terrain, 9)
	assert_true(float(gap_tiles) * 48.0 > max_jump + 16.0, "level_02: ho gai vuot tam nhay Cube, bat buoc Ship cho qua")
	var sign_node := lvl.get_node_or_null("ControlSign") as Label
	assert_true(sign_node != null and sign_node.text.contains("SHIP"), "level_02 co huong dan Ship")
	var portal := lvl.get_node("Portals/ShipPortal") as FormPortal
	assert_eq(portal.target_form, "SHIP", "portal chuyen P1 thanh Ship")
	assert_eq(portal.allowed_player, "P1_ONLY", "portal chi cho P1")
	var btn := lvl.get_node("Mechanisms/PressureButton") as PressureButton
	var box := lvl.get_node("Mechanisms/CoopBox") as RigidBody2D
	var door := lvl.get_node("Mechanisms/DoorPlatform") as MechanizedPlatform
	assert_true(btn != null and box != null and door != null, "level_02 co du Button, CoopBox va DoorPlatform")
	assert_true(door.move_offset != Vector2.ZERO, "door platform co hanh trinh nang/ha")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_03_loads_and_paints() -> void:
	var ps: PackedScene = load("res://levels/level_03.tscn") as PackedScene
	assert_true(ps != null, "level_03 load duoc")
	var lvl: Node = ps.instantiate()
	assert_eq(int(lvl.get("level_index")), 2, "level_03 index 2")
	host_root.add_child(lvl)

	var ufo := lvl.get_node_or_null("Portals/UfoPortal")
	var grav_in := lvl.get_node_or_null("Portals/P1GravityPortal")
	var grav_out := lvl.get_node_or_null("Portals/ExitGravityPortal")
	assert_true(ufo != null and str(ufo.get("target_form")) == "UFO", "level_03 co Cổng UFO (T7.07)")
	assert_true(grav_in != null and int(grav_in.get("target_direction")) == -1, "level_03 co Cổng đảo trọng lực lên trần")
	assert_true(grav_out != null and int(grav_out.get("target_direction")) == 1, "level_03 co Cổng hoàn trọng lực về thường")

	var btn_top := lvl.get_node_or_null("Mechanisms/ButtonTop") as PressureButton
	var btn_bot := lvl.get_node_or_null("Mechanisms/ButtonBottom") as PressureButton
	var wall := lvl.get_node_or_null("Mechanisms/MiddleWall") as MechanizedPlatform
	assert_true(btn_top != null and btn_bot != null, "level_03 co cap nut bam doi")
	assert_eq(btn_top.mode, 2, "ButtonTop la mode SIMULTANEOUS")
	assert_eq(btn_bot.mode, 2, "ButtonBottom la mode SIMULTANEOUS")
	assert_eq(btn_top.paired_button, NodePath("../ButtonBottom"), "ButtonTop lien ket voi ButtonBottom")
	assert_eq(btn_bot.paired_button, NodePath("../ButtonTop"), "ButtonBottom lien ket voi ButtonTop")
	assert_true(wall != null and wall.require_all, "MiddleWall yeu cau ca 2 nut duoc kich hoat")

	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	assert_true((mgr.get("levels") as Array).has("res://levels/level_03.tscn"), "manager tu dong thay level_03")
	host_root.remove_child(mgr)
	mgr.free()

	host_root.remove_child(lvl)
	lvl.free()


func test_level_03_coop_design_guarantees() -> void:
	var lvl: Node = (load("res://levels/level_03.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var sign_node := lvl.get_node_or_null("ControlSign") as Label
	assert_true(sign_node != null and sign_node.text.contains("UFO"), "level_03 co huong dan UFO")
	var grav_in := lvl.get_node("Portals/P1GravityPortal") as GravityPortal
	var grav_out := lvl.get_node("Portals/ExitGravityPortal") as GravityPortal
	assert_eq(grav_in.target_direction, -1, "grav_in dao trong luc len tran")
	assert_eq(grav_out.target_direction, 1, "grav_out tra trong luc ve thuong")
	var ufo := lvl.get_node("Portals/UfoPortal") as FormPortal
	assert_eq(ufo.target_form, "UFO", "ufo portal chuyen thanh UFO")
	var btn_top := lvl.get_node("Mechanisms/ButtonTop") as PressureButton
	var btn_bot := lvl.get_node("Mechanisms/ButtonBottom") as PressureButton
	var wall := lvl.get_node("Mechanisms/MiddleWall") as MechanizedPlatform
	assert_eq(btn_top.mode, 2, "btn_top la simultaneous")
	assert_eq(btn_bot.mode, 2, "btn_bot la simultaneous")
	assert_eq(btn_top.paired_button, NodePath("../ButtonBottom"), "btn_top cap voi btn_bot")
	assert_true(wall.require_all, "MiddleWall bat buoc ca 2 nut duoc bam dong thoi")
	host_root.remove_child(lvl)
	lvl.free()


func test_level_04_loads_and_paints() -> void:
	var ps: PackedScene = load("res://levels/level_04.tscn") as PackedScene
	assert_true(ps != null, "level_04 load duoc")
	var lvl: Node = ps.instantiate()
	assert_eq(int(lvl.get("level_index")), 3, "level_04 index 3")
	host_root.add_child(lvl)

	var dash_p := lvl.get_node_or_null("Portals/DashPortal")
	var ship_p := lvl.get_node_or_null("Portals/ShipPortal")
	var ufo_p := lvl.get_node_or_null("Portals/UfoPortal")
	var cube_p := lvl.get_node_or_null("Portals/CubeFinalPortal")
	assert_true(dash_p != null and str(dash_p.get("target_form")) == "DASH", "level_04 co DashPortal")
	assert_true(ship_p != null and str(ship_p.get("target_form")) == "SHIP", "level_04 co ShipPortal")
	assert_true(ufo_p != null and str(ufo_p.get("target_form")) == "UFO", "level_04 co UfoPortal")
	assert_true(cube_p != null and str(cube_p.get("target_form")) == "CUBE", "level_04 co CubeFinalPortal")

	var wall := lvl.get_node_or_null("Mechanisms/BreakableDashWall")
	var orb := lvl.get_node_or_null("Mechanisms/DashOrb")
	var btn := lvl.get_node_or_null("Mechanisms/CeilingButton")
	var door := lvl.get_node_or_null("Mechanisms/ExitPlatformDoor") as MechanizedPlatform
	var gate := lvl.get_node_or_null("Mechanisms/DualExitGate")
	assert_true(wall != null, "level_04 co BreakableDashWall cho Dash tong vo")
	assert_true(orb != null, "level_04 co DashOrb de hoi luot")
	assert_true(btn != null and door != null, "level_04 co CeilingButton va ExitPlatformDoor")
	assert_true(gate != null, "level_04 co DualExitGate hoan thanh chuoi man")
	assert_true(door.linked_triggers.has(NodePath("../CeilingButton")), "Door duoc noi day voi CeilingButton")

	host_root.remove_child(lvl)
	lvl.free()


func test_level_04_coop_design_guarantees() -> void:
	var lvl: Node = (load("res://levels/level_04.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var sign_node := lvl.get_node_or_null("ControlSign") as Label
	assert_true(sign_node != null and sign_node.text.contains("GRAND FINALE"), "level_04 co huong dan Grand Finale")
	var dash_p := lvl.get_node("Portals/DashPortal") as FormPortal
	var ship_p := lvl.get_node("Portals/ShipPortal") as FormPortal
	var ufo_p := lvl.get_node("Portals/UfoPortal") as FormPortal
	var cube_p := lvl.get_node("Portals/CubeFinalPortal") as FormPortal
	assert_eq(dash_p.target_form, "DASH", "co DashPortal")
	assert_eq(ship_p.target_form, "SHIP", "co ShipPortal")
	assert_eq(ufo_p.target_form, "UFO", "co UfoPortal")
	assert_eq(cube_p.target_form, "CUBE", "co CubeFinalPortal")
	var wall := lvl.get_node("Mechanisms/BreakableDashWall") as BreakableDashBlock
	var orb := lvl.get_node("Mechanisms/DashOrb") as DashOrb
	var laser := lvl.get_node("Hazards/LaserGate") as LaserHazard
	var btn := lvl.get_node("Mechanisms/CeilingButton") as PressureButton
	var door := lvl.get_node("Mechanisms/ExitPlatformDoor") as MechanizedPlatform
	assert_true(wall != null and orb != null and laser != null and btn != null and door != null, "level_04 co du cac co che")
	assert_true(door.linked_triggers.has(NodePath("../CeilingButton")), "door platform noi day voi ceiling button")
	host_root.remove_child(lvl)
	lvl.free()


func test_full_level_progression_chain() -> void:
	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	var levels_list: Array = mgr.get("levels") as Array
	assert_true(levels_list.size() >= 4, "LevelManager tim thay du it nhat 4 man choi")
	assert_eq(levels_list[0], "res://levels/level_01.tscn", "Man 1 la level_01")
	assert_eq(levels_list[1], "res://levels/level_02.tscn", "Man 2 la level_02")
	assert_eq(levels_list[2], "res://levels/level_03.tscn", "Man 3 la level_03")
	assert_eq(levels_list[3], "res://levels/level_04.tscn", "Man 4 la level_04")
	host_root.remove_child(mgr)
	mgr.free()


func test_level_controller_configures_ceiling_and_floor_bounds() -> void:
	var lvl: Node = (load("res://levels/level_01.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var p1 := lvl.get_node("Players/PlayerP1") as GdxPlayer
	var p2 := lvl.get_node("Players/PlayerP2") as GdxPlayer
	var cam := lvl.get_node("CoopCamera") as CoopCamera
	var ceil_y: float = float(lvl.get("ceiling_y"))
	var floor_y: float = float(lvl.get("floor_kill_y"))
	assert_true(ceil_y <= 0.0, "ceiling_y dat tran <= 0")
	assert_true(floor_y >= 576.0, "floor_kill_y dat vuc duoi map >= 576")
	assert_eq(p1.ceiling_y, ceil_y, "P1 dong bo ceiling_y")
	assert_eq(p1.floor_kill_y, floor_y, "P1 dong bo floor_kill_y")
	assert_eq(p2.ceiling_y, ceil_y, "P2 dong bo ceiling_y")
	assert_eq(p2.floor_kill_y, floor_y, "P2 dong bo floor_kill_y")
	assert_true(p1.enforce_vertical_bounds and p2.enforce_vertical_bounds, "ca 2 player bat enforce bounds")
	assert_eq(cam.limit_top, floori(ceil_y), "camera limit_top dong bo tran")
	assert_eq(cam.limit_bottom, ceili(floor_y), "camera limit_bottom dong bo san")
	host_root.remove_child(lvl)
	lvl.free()





func test_all_level_spawns_have_ground() -> void:
	for n in ["level_01", "level_02", "level_03", "level_04"]:
		var lvl: Node = (load("res://levels/%s.tscn" % n) as PackedScene).instantiate()
		host_root.add_child(lvl)
		var layer: TileMapLayer = lvl.get_node("TerrainLayer") as TileMapLayer
		var markers: Array = [lvl.get_node("SpawnP1"), lvl.get_node("SpawnP2")]
		var cps: Node = lvl.get_node("Checkpoints")
		for cp in cps.get_children():
			for mn in ["SpawnP1", "SpawnP2"]:
				var mk: Node = (cp as Node).get_node_or_null(mn)
				if mk != null:
					markers.append(mk)
		for mk in markers:
			assert_true(_ground_below(layer, (mk as Node2D).global_position), "%s: %s dung tren dat (khong roi ho)" % [n, (mk as Node).name])
		host_root.remove_child(lvl)
		lvl.free()


func _ground_below(layer: TileMapLayer, world_pos: Vector2) -> bool:
	var cell: Vector2i = layer.local_to_map(layer.to_local(world_pos))
	for dy in range(0, 3):
		if layer.get_cell_source_id(Vector2i(cell.x, cell.y + dy)) != -1:
			return true
	return false