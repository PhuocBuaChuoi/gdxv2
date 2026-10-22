extends "res://tests/gdx_test.gd"

## Phase 8 (T8.01–T8.06): menu, chọn màn, HUD, pause, popup, audio.
## Nguyên tắc: KHÔNG bấm nút nào đổi scene giữa suite (Play/Next/Card/Menu
## chỉ assert cấu trúc + nhánh an toàn với manager rỗng).


func _new_manager(empty: bool = false) -> Node:
	var mgr: Node = (load("res://autoloads/level_manager.gd") as Script).new()
	host_root.add_child(mgr)
	mgr.call("rescan")
	if empty:
		# Clear tại chỗ (giữ kiểu Array[String]): set([]) rỗng sẽ lỗi kiểu.
		(mgr.get("levels") as Array).clear()
	return mgr


func _despawn(n: Node) -> void:
	host_root.remove_child(n)
	n.free()


func test_main_menu_structure() -> void:
	var menu: Control = (load("res://ui/main_menu.tscn") as PackedScene).instantiate() as Control
	var mgr := _new_manager(true)
	mgr.set("levels", [])
	menu.set("manager", mgr)
	host_root.add_child(menu)
	for b in ["MenuBox/PlayBtn", "MenuBox/SelectBtn", "MenuBox/SettingsBtn", "MenuBox/QuitBtn"]:
		assert_true(menu.get_node_or_null(b) is Button, "T8.01 co nut " + b)
	assert_true(not (menu.get_node("SettingsPanel") as Control).visible, "T8.01 panel cai dat mac dinh an")
	menu.call("_on_settings_pressed")
	assert_true((menu.get_node("SettingsPanel") as Control).visible, "T8.01 bat panel cai dat")
	assert_true(not bool(menu.call("_on_play_pressed")), "T8.01 Play voi manager rong that bai an toan (khong doi scene)")
	assert_eq(int(mgr.get("current_index")), -1, "T8.01 khong doi scene khi that bai")
	_despawn(menu)
	_despawn(mgr)


func test_play_index_clamps_stale_save() -> void:
	var menu: Control = (load("res://ui/main_menu.tscn") as PackedScene).instantiate() as Control
	var mgr := _new_manager()
	menu.set("manager", mgr)
	host_root.add_child(menu)
	var count: int = int(mgr.call("level_count"))
	assert_true(count > 0, "T8.01 manager co man de test clamp")
	mgr.set("unlocked", 999)
	assert_eq(int(menu.call("_play_index", mgr)), count - 1, "T8.01 save cu mo khoa vuot -> kep man cuoi")
	mgr.set("unlocked", 0)
	assert_eq(int(menu.call("_play_index", mgr)), 0, "T8.01 unlocked 0 -> khong am")
	(mgr.get("levels") as Array).clear()
	assert_eq(int(menu.call("_play_index", mgr)), -1, "T8.01 manager rong -> -1")
	_despawn(menu)
	_despawn(mgr)


func test_level_select_cards() -> void:
	var sel: Control = (load("res://ui/level_select.tscn") as PackedScene).instantiate() as Control
	var mgr := _new_manager()
	mgr.set("unlocked", 1)
	sel.set("manager", mgr)
	host_root.add_child(sel)
	var cards: Array = (sel.get_node("CardsBox") as VBoxContainer).get_children()
	assert_true(cards.size() >= 1, "T8.02 sinh the theo LevelManager (level_01 ton tai)")
	assert_true(not (cards[0] as Button).disabled, "T8.02 man mo khoa bam duoc")
	assert_true((cards[0] as Button).text.begins_with("Màn 1"), "T8.02 the dung ten")
	_despawn(sel)
	_despawn(mgr)


func test_hud_wiring() -> void:
	var lvl: Node = (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var hud: Control = lvl.get_node_or_null("LevelHUD/HUD") as Control
	assert_true(hud != null, "T8.03 base co HUD instance")
	var attempt: Label = lvl.get_node_or_null("LevelHUD/HUD/TopLeft/AttemptLabel") as Label
	var forms: Label = lvl.get_node_or_null("LevelHUD/HUD/TopRight/FormsLabel") as Label
	var time_l: Label = lvl.get_node_or_null("LevelHUD/HUD/TopRight/TimeLabel") as Label
	assert_true(attempt != null and forms != null and time_l != null, "T8.03 du 3 nhan HUD")
	assert_eq(attempt.text, "Attempt 0", "T8.03 HUD dong bo attempt ban dau")
	assert_true(not (lvl.get_node("LevelHUD/AttemptLabel") as Label).visible, "T8.03 label legacy an de tranh chong HUD")
	Events.player_form_changed.emit(1, &"SHIP")
	assert_eq(forms.text, "P1: SHIP   P2: CUBE", "T8.03 doi dang P1 qua Events")
	var coord: Node = lvl.get_node_or_null("RespawnCoordinator")
	assert_true(coord != null, "T8.03 base co RespawnCoordinator")
	coord.emit_signal("attempt_changed", 3)
	assert_eq(attempt.text, "Attempt 3", "T8.03 Attempt theo coordinator")
	lvl.call("reset_stats")
	lvl.call("_process", 0.5)
	hud.call("_process", 0.0)
	assert_eq(time_l.text, "00:00.50", "T8.03 dong ho theo controller")
	_despawn(lvl)


func test_completion_popup_listens_to_level_event() -> void:
	var lvl: Node = (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(lvl)
	var popup := lvl.get_node("LevelHUD/CompletePopup") as Control
	assert_true(not popup.visible, "T8.05 popup an truoc khi hoan thanh")
	Events.level_completed.emit(0, 1, 12.5)
	assert_true(popup.visible, "T8.05 popup tu mo khi nhan level_completed")
	assert_true((popup.get_node("PanelBox/TimeLabel") as Label).text.contains("00:12"), "T8.05 popup nhan dung thoi gian")
	_despawn(lvl)


func test_pause_menu_finds_nested_coordinator() -> void:
	var level := (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(level)
	var pause := (load("res://ui/pause_menu.tscn") as PackedScene).instantiate() as Control
	level.add_child(pause)
	assert_true(pause.call("_coordinator") == level.get_node("RespawnCoordinator"), "T8.04 pause tim coordinator long qua Main/BaseLevel")
	level.remove_child(pause)
	pause.free()
	_despawn(level)


func test_pause_toggle() -> void:
	host_root.get_tree().paused = false
	var menu: Control = (load("res://ui/pause_menu.tscn") as PackedScene).instantiate() as Control
	host_root.add_child(menu)
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "T8.04 ALWAYS (WHEN_PAUSED khong bat duoc pause)")
	assert_true(not menu.visible, "T8.04 mac dinh an")
	var ev := InputEventAction.new()
	ev.action = &"game_pause"
	ev.pressed = true
	menu._unhandled_input(ev)
	assert_true(host_root.get_tree().paused and menu.visible, "T8.04 Esc dung game + hien menu")
	menu._unhandled_input(ev)
	assert_true(not host_root.get_tree().paused and not menu.visible, "T8.04 Esc tiep resume")
	menu.call("_on_checkpoint_pressed")
	assert_true(not host_root.get_tree().paused, "T8.04 checkpoint khong treo pause (manager rong -> no-op an toan)")
	_despawn(menu)
	host_root.get_tree().paused = false


func test_complete_popup() -> void:
	var pop: Control = (load("res://ui/level_complete_popup.tscn") as PackedScene).instantiate() as Control
	var mgr := _new_manager(true)
	mgr.set("levels", [])
	pop.set("manager", mgr)
	host_root.add_child(pop)
	assert_true(not pop.visible, "T8.05 mac dinh an")
	assert_eq(int(pop.call("show_result", 95.5, 2)), 3, "T8.05 chet 2 -> 3 sao")
	assert_true(pop.visible, "T8.05 hien bang ket qua")
	assert_true((pop.get_node("PanelBox/TimeLabel") as Label).text.contains("01:35"), "T8.05 hien gio 95.5s")
	assert_eq(int(pop.call("show_result", 10.0, 5)), 2, "T8.05 chet 5 -> 2 sao")
	assert_eq(int(pop.call("show_result", 10.0, 9)), 1, "T8.05 chet 9 -> 1 sao")
	assert_true(not bool(pop.call("_on_next_pressed")), "T8.05 Next voi manager rong an toan")
	assert_true(not bool(pop.call("_on_retry_pressed")), "T8.05 Retry voi manager rong an toan")
	_despawn(pop)
	_despawn(mgr)


func test_audio_manager() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/AudioManager"), "*res://autoloads/audio_manager.gd", "T8.06 autoload dang ky")
	var am: Node = (load("res://autoloads/audio_manager.gd") as Script).new()
	host_root.add_child(am)
	var names: Array = am.call("sfx_names")
	for s in ["click", "jump", "checkpoint", "death", "portal", "win"]:
		assert_true(names.has(s), "T8.06 co sfx " + s)
		var stream: AudioStreamWAV = am.get("_sfx")[s]
		assert_true(stream.data.size() > 100, "T8.06 %s co du lieu" % s)
		assert_eq(stream.mix_rate, 22050, "T8.06 mix rate chuan")
		assert_true(bool(am.call("play_sfx", s)), "T8.06 phat %s khong crash" % s)
	assert_true(not bool(am.call("play_sfx", "khong-co")), "T8.06 ten la tra false")
	am.call("set_volume", -12.0)
	assert_near(float(am.get("volume_db")), -12.0, 0.001, "T8.06 chinh am luong")
	am.call("set_volume", 99.0)
	assert_near(float(am.get("volume_db")), 0.0, 0.001, "T8.06 volume kep tran")
	_despawn(am)
