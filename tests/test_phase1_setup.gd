extends "res://tests/gdx_test.gd"

## Khóa cứng toàn bộ spec Giai đoạn 1 (T1.02–T1.10).
## Nếu ai sửa project.godot/input/layers/palette mà lệch spec → test đỏ ngay.
## (extends bằng path + preload để chạy headless không cần editor import.)

const Palette = preload("res://resources/color_palette.gd")


func test_input_p1_keys() -> void:
	assert_action_keys(&"p1_left", [65], "T1.06 p1_left=A")
	assert_action_keys(&"p1_right", [68], "T1.06 p1_right=D")
	assert_action_keys(&"p1_jump", [87, 32], "T1.06 p1_jump=W+Space")
	assert_action_keys(&"p1_action", [83], "T1.06 p1_action=S")


func test_input_p2_keys() -> void:
	assert_action_keys(&"p2_left", [4194319], "T1.07 p2_left=Left")
	assert_action_keys(&"p2_right", [4194321], "T1.07 p2_right=Right")
	assert_action_keys(&"p2_jump", [4194320], "T1.07 p2_jump=Up")
	assert_action_keys(&"p2_action", [4194322], "T1.07 p2_action=Down")


func test_input_system_keys() -> void:
	assert_action_keys(&"game_restart_checkpoint", [82], "T1.08 restart=R")
	assert_action_keys(&"game_pause", [4194305], "T1.08 pause=Esc")


func test_display_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920, "T1.02 width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080, "T1.02 height")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "T1.02 stretch mode")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand", "T1.02 stretch aspect")


func test_physics_settings() -> void:
	assert_eq(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 120, "T1.03 ticks=120")


func test_physics_layers() -> void:
	var want: Array = ["World_Terrain", "Player_1", "Player_2", "Hazard_Neutral", "Hazard_P1_Safe", "Hazard_P2_Safe", "Interactables", "Pushable_Blocks"]
	for i in range(1, 9):
		assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % i), want[i - 1], "T1.05 layer_%d" % i)


func test_autoload_events() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/Events"), "*res://autoloads/events.gd", "T1.10 autoload dang ky")
	assert_true(load("res://autoloads/events.gd") != null, "T1.10 events.gd load duoc")


func test_palette() -> void:
	assert_eq(Palette.COLOR_P1_CYAN, Color(0.0, 0.9, 1.0), "T1.09 P1 cyan")
	assert_eq(Palette.COLOR_P2_ORANGE, Color(1.0, 0.55, 0.1), "T1.09 P2 orange")
	assert_eq(Palette.COLOR_NEUTRAL_WHITE, Color(1.0, 1.0, 1.0), "T1.09 neutral white")
	assert_eq(Palette.COLOR_BG_DARK, Color(0.05, 0.06, 0.10), "T1.09 bg dark")
	assert_eq(Palette.COLOR_PORTAL_CUBE, Color(0.2, 1.0, 0.4), "T1.09 portal cube")
	assert_eq(Palette.COLOR_PORTAL_SHIP, Color(1.0, 0.3, 0.9), "T1.09 portal ship")
	assert_eq(Palette.COLOR_PORTAL_UFO, Color(1.0, 0.9, 0.2), "T1.09 portal ufo")
	assert_eq(Palette.COLOR_PORTAL_DASH, Color(0.5, 0.4, 1.0), "T1.09 portal dash")


func test_entry_files() -> void:
	assert_true(load("res://scenes/main/Main.tscn") != null, "main scene load duoc")
	assert_true(FileAccess.file_exists("res://assets/sprites/icon.svg"), "icon.svg ton tai (config/icon)")


func test_input_key_counts() -> void:
	var singles: Array[StringName] = [&"p1_left", &"p1_right", &"p1_action", &"p2_left", &"p2_right", &"p2_jump", &"p2_action", &"game_restart_checkpoint", &"game_pause"]
	for a in singles:
		assert_eq(action_keys(a).size(), 1, "action '%s' co dung 1 phim" % a)
	assert_eq(action_keys(&"p1_jump").size(), 2, "p1_jump co dung 2 phim (W+Space)")


func test_input_deadzones() -> void:
	var actions: Array[StringName] = [&"p1_left", &"p1_right", &"p1_jump", &"p1_action", &"p2_left", &"p2_right", &"p2_jump", &"p2_action", &"game_restart_checkpoint", &"game_pause"]
	for a in actions:
		assert_near(InputMap.action_get_deadzone(a), 0.5, 0.0001, "deadzone '%s' = 0.5" % a)


func test_input_no_duplicate_keys() -> void:
	var actions: Array[StringName] = [&"p1_left", &"p1_right", &"p1_jump", &"p1_action", &"p2_left", &"p2_right", &"p2_jump", &"p2_action", &"game_restart_checkpoint", &"game_pause"]
	var seen: Dictionary = {}
	for a in actions:
		for k in action_keys(a):
			assert_true(not seen.has(k), "phim %d chi thuoc 1 action (trung '%s'/'%s')" % [k, str(seen.get(k, "?")), str(a)])
			seen[k] = a


func test_events_signals() -> void:
	var scr: Script = load("res://autoloads/events.gd") as Script
	assert_true(scr != null, "events.gd load duoc")
	var want: Dictionary = {&"player_died": 2, &"checkpoint_activated": 3, &"player_form_changed": 2, &"player_entered_goal": 1, &"player_exited_goal": 1, &"level_completed": 3}
	var got: Dictionary = {}
	for s in scr.get_script_signal_list():
		got[str(s["name"])] = (s["args"] as Array).size()
	for sig_name in want.keys():
		assert_true(got.has(sig_name), "signal '%s' ton tai" % sig_name)
		if got.has(sig_name):
			assert_eq(got[sig_name], want[sig_name], "signal '%s' dung so arg" % sig_name)
	assert_eq(got.size(), want.size(), "khong thua/thieu signal")


func test_settings_cross_check() -> void:
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	assert_true(FileAccess.file_exists(main_scene), "main_scene tro file ton tai")
	var icon: String = str(ProjectSettings.get_setting("application/config/icon"))
	assert_true(FileAccess.file_exists(icon), "icon tro file ton tai")
	var inst: Node = (load(main_scene) as PackedScene).instantiate()
	assert_true(inst is Node2D, "main scene goc la Node2D")
	inst.free()


func test_palette_coherence() -> void:
	assert_true(Palette.COLOR_P1_CYAN != Palette.COLOR_P2_ORANGE, "P1 khac mau P2")
	var bg: Color = Palette.COLOR_BG_DARK
	assert_true((bg.r + bg.g + bg.b) / 3.0 < 0.15, "bg dark that su toi de neon noi")
	assert_eq(Palette.COLOR_NEUTRAL_WHITE, Color.WHITE, "neutral white chuan")
