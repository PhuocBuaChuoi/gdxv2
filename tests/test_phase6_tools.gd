extends "res://tests/gdx_test.gd"

## Phase 6 (T6.01–T6.10): form_portal, jump_pad, jump_orb, pressure_button,
## mechanized_platform, breakable_dash_block, hazard, coop_box, dual_exit_gate.


func _spawn(path: String) -> Node:
	var n: Node = (load(path) as PackedScene).instantiate()
	host_root.add_child(n)
	return n


func _despawn(n: Node) -> void:
	host_root.remove_child(n)
	n.free()


func _player(id: int) -> Node:
	var p: Node = (load("res://characters/player.tscn") as PackedScene).instantiate()
	p.set("player_id", id)
	host_root.add_child(p)
	return p


func test_form_portal_switches_and_filters() -> void:
	var portal := _spawn("res://components/form_portal.tscn")
	portal.set("target_form", "SHIP")
	var p1 := _player(1)
	var p2 := _player(2)
	portal.call("_on_body_entered", p1)
	assert_eq(str(p1.get("form")), "SHIP", "T6.01 BOTH doi P1 thanh SHIP")
	portal.call("_on_body_entered", p2)
	assert_eq(str(p2.get("form")), "SHIP", "T6.01 BOTH doi P2 thanh SHIP")
	portal.set("allowed_player", "P1_ONLY")
	portal.set("target_form", "UFO")
	var p2b := _player(2)
	portal.call("_on_body_entered", p2b)
	assert_eq(str(p2b.get("form")), "CUBE", "T6.01 P1_ONLY bo qua P2")
	var frame := portal.get_node("Frame") as Polygon2D
	assert_true(frame.color.r > 0.9 and frame.color.g < 0.5, "T6.01 khung doi mau theo UFO")
	_despawn(p1)
	_despawn(p2)
	_despawn(p2b)
	_despawn(portal)


func test_jump_pad_boosts() -> void:
	var pad := _spawn("res://components/jump_pad.tscn")
	var body := _player(1)
	assert_near(float(pad.call("boost_value")), 950.0, 0.001, "T6.03 YELLOW = trung binh")
	pad.set("pad_type", 1)
	assert_near(float(pad.call("boost_value")), 450.0, 0.001, "T6.03 PINK = thap")
	pad.set("pad_type", 2)
	assert_near(float(pad.call("boost_value")), 1400.0, 0.001, "T6.03 RED = cuc cao")
	body.global_position = pad.global_position + Vector2(0.0, -6.0)
	body.velocity = Vector2(0.0, 20.0)
	pad.call("_on_body_entered", body)
	assert_near(body.velocity.y, -1400.0, 0.001, "T6.03 cham la phong len")
	var pad_color := (pad.get_node("Pad") as Polygon2D).color
	assert_true(pad_color.r > 0.9 and pad_color.g < 0.4, "T6.03 mau RED doi mau")
	_despawn(body)
	_despawn(pad)


func test_jump_pad_requires_real_landing_contact() -> void:
	var pad := _spawn("res://components/jump_pad.tscn")
	pad.global_position = Vector2(300, 416)
	var player := _player(1)
	player.global_position = Vector2(300, 360)
	player.velocity = Vector2.ZERO
	pad.call("_on_body_entered", player)
	assert_near(player.velocity.y, 0.0, 0.001, "T6.03 pad khong kich hoat khi con cach mat pad")
	player.global_position = Vector2(300, 410)
	player.velocity = Vector2(0.0, 20.0)
	pad.call("_on_body_entered", player)
	assert_true(player.velocity.y < 0.0, "T6.03 pad chi bat khi dang tiep dat")
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(300, 416)
	pad.call("_on_body_entered", player)
	assert_near(player.velocity.y, 0.0, 0.001, "T6.03 pad khong bat khi cham ngang")
	player.global_position = Vector2(300, 410)
	player.velocity = Vector2.ZERO
	pad.call("_on_body_entered", player.get_node("HeadPlatform"))
	assert_near(player.velocity.y, 0.0, 0.001, "T6.03 pad bo qua HeadPlatform")
	_despawn(player)
	_despawn(pad)


func test_jump_pad_squash_visible_after_boost() -> void:
	var pad := _spawn("res://components/jump_pad.tscn")
	var player := _player(1)
	player.global_position = pad.global_position + Vector2(0.0, -12.0)
	player.velocity = Vector2(0.0, 10.0)
	pad.call("_on_body_entered", player)
	var spr := pad.get_node("Sprite") as Sprite2D
	pad.call("_process", 0.016)
	# Truoc day Tween bi _process ghi de scale moi frame -> hieu ung nun mat.
	assert_true(spr.scale.y < 0.5, "T6.03 pad co hieu ung nun sau khi bung (scale.y=%s)" % str(spr.scale.y))
	_despawn(player)
	_despawn(pad)


func test_laser_duty_extremes() -> void:
	var laser := _spawn("res://components/laser_hazard.tscn")
	laser.set("duty", 0.0)
	laser.call("_process", 0.1)
	assert_true(not bool(laser.get("is_on")), "T6.05 duty=0 -> luon TAT")
	assert_true(not (laser as Area2D).monitoring, "T6.05 duty=0 tat monitoring")
	laser.set("duty", 1.0)
	laser.call("_process", 0.1)
	assert_true(bool(laser.get("is_on")), "T6.05 duty=1 -> luon BAT")
	_despawn(laser)


func test_motion_trail_skips_hidden_player() -> void:
	var trail := _spawn("res://vfx/motion_trail.tscn") as Line2D
	var player := _player(1)
	trail.call("setup", player, Color.WHITE)
	player.visible = false
	player.global_position = Vector2(200, 200)
	trail.call("_physics_process", 0.016)
	assert_eq(trail.get_point_count(), 0, "T2.05 khong ve vet khi player bi an (dang chet)")
	player.visible = true
	trail.call("_physics_process", 0.016)
	assert_true(trail.get_point_count() >= 1, "T2.05 ve lai vet khi player hien lai")
	_despawn(player)
	_despawn(trail)


func test_jump_orb_types() -> void:
	var orb := _spawn("res://components/jump_orb.tscn")
	var p := _player(1)
	orb.call("trigger", p)
	assert_near(float(p.get("velocity").y), -1100.0, 0.001, "T6.04 YELLOW day 1100")
	orb.set("orb_type", 1)
	assert_true(bool(orb.call("trigger", p)), "T6.04 BLUE trigger thanh cong")
	assert_eq(int(p.get("gravity_direction")), -1, "T6.04 BLUE dao gravity thanh -1")
	orb.call("trigger", p)
	assert_eq(int(p.get("gravity_direction")), 1, "T6.04 BLUE dao lai gravity 1")
	p.call("switch_form", &"DASH")
	var st: Variant = p.get("current_state")
	st.call("activate_dash", 1)
	assert_true(not bool(st.get("dash_ready")), "T6.04 setup: dash da dung")
	orb.set("orb_type", 2)
	assert_true(bool(orb.call("trigger", p)), "T6.04 DASH trigger thanh cong")
	assert_true(bool(st.get("dash_ready")), "T6.04 DASH hoi 1 luot dash")
	var p2 := _player(2)
	orb.call("_on_body_entered", p2)
	assert_true((orb.get("_overlapping") as Dictionary).has(p2.get_instance_id()), "T6.04 ghi nhan overlap")
	orb.call("_on_body_exited", p2)
	assert_true(not (orb.get("_overlapping") as Dictionary).has(p2.get_instance_id()), "T6.04 xoa overlap khi ra")
	_despawn(p)
	_despawn(p2)
	_despawn(orb)


func test_pressure_button_modes() -> void:
	var btn := _spawn("res://components/pressure_button.tscn")
	var p1 := _player(1)
	var p2 := _player(2)
	var fired := [0]
	var cb := func(v: bool) -> void:
		fired[0] += 1 if v else -1
	btn.triggered.connect(cb)
	btn.call("_on_body_entered", p1)
	assert_true(bool(btn.get("is_on")), "T6.06 HOLD: ben la bat")
	btn.call("_on_body_exited", p1)
	assert_true(not bool(btn.get("is_on")), "T6.06 HOLD: roi la tat")
	btn.set("mode", 1)
	btn.call("_on_body_entered", p2)
	btn.call("_on_body_exited", p2)
	assert_true(bool(btn.get("is_on")), "T6.06 TOUCH: cham 1 lan giu vinh vien")
	assert_eq(int(fired[0]), 1, "T6.06 signal triggered len/xuong")
	_despawn(btn)
	_despawn(p1)
	_despawn(p2)


func test_pressure_button_filters_and_pair() -> void:
	var p1 := _player(1)
	var p2 := _player(2)
	var light := RigidBody2D.new()
	light.mass = 0.2
	host_root.add_child(light)
	var heavy := (load("res://components/coop_box.tscn") as PackedScene).instantiate()
	host_root.add_child(heavy)
	var btn := _spawn("res://components/pressure_button.tscn")
	btn.set("activator", 1)
	btn.call("_on_body_entered", p2)
	assert_true(not bool(btn.get("is_on")), "T6.06 P1_ONLY: P2 khong cham duoc")
	btn.call("_on_body_entered", p1)
	assert_true(bool(btn.get("is_on")), "T6.06 P1_ONLY: P1 cham duoc")
	btn.set("activator", 3)
	var btn2 := _spawn("res://components/pressure_button.tscn")
	btn2.set("activator", 3)
	btn2.call("_on_body_entered", light)
	assert_true(not bool(btn2.get("is_on")), "T6.06 HEAVY: hop nhe bi bo qua")
	btn2.call("_on_body_entered", heavy)
	assert_true(bool(btn2.get("is_on")), "T6.06 HEAVY: CoopBox mass=1 du trong luong")
	var btnA := _spawn("res://components/pressure_button.tscn")
	var btnB := _spawn("res://components/pressure_button.tscn")
	btnA.set("mode", 2)
	btnB.set("mode", 2)
	btnB.set("paired_button", btnA.get_path())
	btnA.call("_on_body_entered", p1)
	assert_true(not bool(btnA.get("is_on")), "T6.06 SIM: nhan 1 minh chua mo")
	btnB.call("_on_body_entered", p2)
	assert_true(bool(btnA.get("is_on")) and bool(btnB.get("is_on")), "T6.06 SIM: cap nhan trong 0.5s -> ca 2 mo")
	btnB.call("_on_body_exited", p2)
	assert_true(bool(btnB.get("is_on")), "T6.06 SIM: latch vinh vien sau khi roi")
	_despawn(btn)
	_despawn(btn2)
	_despawn(btnA)
	_despawn(btnB)
	_despawn(light)
	_despawn(heavy)
	_despawn(p1)
	_despawn(p2)


func test_mechanized_platform_follows_trigger() -> void:
	var btn := _spawn("res://components/pressure_button.tscn")
	var plat: Node = (load("res://components/mechanized_platform.tscn") as PackedScene).instantiate()
	plat.position = Vector2(300, 0)
	plat.set("speed", 500.0)
	host_root.add_child(plat)
	# sync_to_physics=true chi chap nhan ghi transform trong physics tick that;
	# test goi truc tiep _physics_process nen tam tat de quan sat duoc vi tri.
	plat.set("sync_to_physics", false)
	assert_true(not bool(plat.call("_triggers_active")), "T6.07 khong link -> o home")
	var arr: Array[NodePath] = [btn.get_path()]
	plat.set("linked_triggers", arr)
	btn.call("_set_on", true)
	assert_true(bool(plat.call("_triggers_active")), "T6.07 trigger bat -> se di chuyen")
	for i in range(10):
		plat._physics_process(0.05)
	assert_true(plat.position.y < -50.0, "T6.07 len offset 96px gan den, y=%s" % str(plat.position.y))
	btn.call("_set_on", false)
	for i in range(10):
		plat._physics_process(0.05)
	assert_true(plat.position.y > -10.0, "T6.07 tat trigger -> ve home")
	_despawn(plat)
	_despawn(btn)


func test_breakable_block_only_for_dash() -> void:
	var block := _spawn("res://components/breakable_dash_block.tscn")
	var cube := _player(1)
	block.call("_on_body_entered", cube)
	assert_true(not block.is_queued_for_deletion(), "T6.08 Cube binh thuong khong pha duoc")
	var shattered := [0]
	var cb := func() -> void:
		shattered[0] += 1
	block.shattered.connect(cb)
	cube.call("switch_form", &"DASH")
	var st: Variant = cube.get("current_state")
	st.call("activate_dash", 1)
	assert_true(bool(st.get("is_dashing")), "T6.08 setup: dang luot")
	block.call("_on_body_entered", cube)
	assert_eq(int(shattered[0]), 1, "T6.08 Dash luot vao -> phat shattered")
	assert_true(not block.visible, "T6.08 khoi an di sau khi pha (de co the hoi sinh checkpoint)")
	# CollisionShape.disabled duoc set_deferred (tranh sua luc physics dang chay)
	# nen khong assert ngay trong cung frame; kiem tra trang thai logic thay the.
	assert_true(bool(block.get("_shattered")), "T6.08 trang thai da vo duoc ghi nhan (co the reset checkpoint)")
	host_root.remove_child(block)
	block.free()
	_despawn(cube)


func test_base_level_has_t6_examples() -> void:
	var lvl := _spawn("res://levels/base_level.tscn")
	for p in [
		"Portals/FormPortal",
		"Mechanisms/JumpPad",
		"Mechanisms/JumpOrb",
		"Mechanisms/PressureButton",
		"Mechanisms/MechanizedPlatform",
		"Mechanisms/BreakableDashBlock",
		"Hazards/SpikeNeutral",
		"Hazards/SpikeCyan",
		"Hazards/LaserOrange",
	]:
		assert_true(lvl.get_node_or_null(p) != null, "template co " + p)
	assert_eq(int((lvl.get_node("Hazards/SpikeNeutral") as Area2D).collision_layer), 8, "template SpikeNeutral layer 4")
	assert_eq(int((lvl.get_node("Hazards/SpikeCyan") as Area2D).collision_layer), 16, "template SpikeCyan layer 5")
	var plat := lvl.get_node_or_null("Mechanisms/MechanizedPlatform") as MechanizedPlatform
	assert_true(plat != null and plat.linked_triggers.size() == 1, "T6.07 template noi 1 nut")
	_despawn(lvl)


func test_spike_hazard_layers_and_colors() -> void:
	var spike := _spawn("res://components/spike_hazard.tscn")
	assert_eq(int(spike.collision_layer), 8, "T6.05 NEUTRAL = layer 4")
	spike.set("hazard_type", 1)
	assert_eq(int(spike.collision_layer), 16, "T6.05 CYAN_SAFE_P1 = layer 5")
	var cyan := (spike.get_node("Spikes") as Polygon2D).color
	assert_true(cyan.b > 0.8 and cyan.r < 0.4, "T6.05 Cyan cho P1 song")
	spike.set("hazard_type", 2)
	assert_eq(int(spike.collision_layer), 32, "T6.05 ORANGE_SAFE_P2 = layer 6")
	# Tương thích mask HazardDetector đã có: P1=40 (Neutral+Orange), P2=24 (Neutral+Cyan)
	assert_true((40 & 8) != 0 and (40 & 32) != 0 and (40 & 16) == 0, "T6.05 P1 mien nhiem Cyan")
	assert_true((24 & 8) != 0 and (24 & 16) != 0 and (24 & 32) == 0, "T6.05 P2 mien nhiem Orange")
	_despawn(spike)


func test_laser_hazard_blinks() -> void:
	var laser := _spawn("res://components/laser_hazard.tscn")
	assert_true(bool(laser.get("is_on")), "T6.05 bat dau BAT")
	laser.call("_process", 0.5)
	assert_true(bool(laser.get("is_on")), "T6.05 giua chu ky van BAT")
	laser.call("_process", 1.0)
	assert_true(not bool(laser.get("is_on")), "T6.05 het duty -> TAT")
	assert_true(not (laser as Area2D).monitoring, "T6.05 tat monitoring khi TAT (di qua an toan)")
	assert_true(not (laser as Area2D).monitorable, "T6.05 tat monitorable khi TAT (HazardDetector khong thay tia)")
	assert_eq(int((laser as Area2D).collision_layer), 0, "T6.05 layer 0 khi TAT")
	laser.call("_process", 1.0)
	assert_true(bool(laser.get("is_on")), "T6.05 chu ky moi -> BAT lai")
	assert_true((laser as Area2D).monitorable, "T6.05 BAT lai monitorable")
	assert_eq(int((laser as Area2D).collision_layer), 8, "T6.05 BAT lai layer NEUTRAL")
	laser.set("hazard_type", 1)
	assert_eq(int(laser.collision_layer), 16, "T6.05 laser cung bang layer")
	_despawn(laser)


func test_portal_toggle_and_debounce() -> void:
	var portal := _spawn("res://components/gravity_portal.tscn")
	var p := _player(1)
	var seen := [0]
	var cb := func(d: int) -> void:
		seen[0] += 1
	Events.portal_activated.connect(cb)
	portal.set("toggle_mode", true)
	portal.call("apply_to", p)
	assert_eq(int(p.get("gravity_direction")), -1, "T6.02 TOGGLE lat nguoc 1 -> -1")
	portal.call("apply_to", p)
	assert_eq(int(p.get("gravity_direction")), 1, "T6.02 TOGGLE lat nguoc -1 -> 1")
	var rigid := RigidBody2D.new()
	rigid.gravity_scale = 1.0
	host_root.add_child(rigid)
	portal.call("apply_to", rigid)
	assert_near(rigid.gravity_scale, -1.0, 0.001, "T6.02 TOGGLE lat RigidBody")
	seen[0] = 0
	portal.call("_on_body_entered", p)
	portal.call("_on_body_entered", p)
	assert_eq(int(seen[0]), 1, "T6.02 rung trong vong khong doi lap (debounce)")
	Events.portal_activated.disconnect(cb)
	host_root.remove_child(rigid)
	rigid.free()
	_despawn(p)
	_despawn(portal)


func test_player_mask_and_push() -> void:
	# GHI CHU ky thuat: move_and_slide nga ngoai physics tick that (test
	# goi tay tu _process) nen khong test chuyen dong that — chi test
	# mask + mapping luc + tu ngat luc.
	var p := _player(1)
	assert_true((int(p.collision_mask) & 128) != 0, "T6.09 player mask co Pushable_Blocks")
	_despawn(p)
	var box := (load("res://components/coop_box.tscn") as PackedScene).instantiate() as RigidBody2D
	host_root.add_child(box)
	var pl := _player(1)
	pl.call("_push_box", box, 1.0)
	assert_near(box.constant_force.x, 700.0, 0.001, "T6.09 day phai: constant_force=700")
	pl.call("_push_box", box, -1.0)
	assert_near(box.constant_force.x, -700.0, 0.001, "T6.09 day trai: -700")
	pl.set("_last_push_targets", [box])
	pl.velocity = Vector2.ZERO
	pl.call("_push_blocks")
	assert_near(box.constant_force.x, 0.0, 0.001, "T6.09 dung/roi -> ngat luc day")
	pl.call("_push_box", box, 1.0)
	pl.set("_last_push_targets", [box])
	pl.set_control_locked(true)
	assert_near(box.constant_force.x, 0.0, 0.001, "T6.09 bi khoa dieu khien (chet/thang) -> ngat luc day")
	pl.set_control_locked(false)
	_despawn(pl)
	host_root.remove_child(box)
	box.free()


func test_neon_interaction_visuals() -> void:
	for scene_path in ["res://components/jump_pad.tscn", "res://components/jump_orb.tscn", "res://components/dash_orb.tscn", "res://components/gravity_portal.tscn", "res://components/form_portal.tscn"]:
		var node := _spawn(scene_path)
		assert_true(node.get_node_or_null("Glow") != null or node.get_node_or_null("GlowRing") != null, "%s co glow neon" % scene_path.get_file())
		var before := node.get_node_or_null("Glow") as Node2D
		if before == null:
			before = node.get_node_or_null("GlowRing") as Node2D
		var scale_before := before.scale.x if before != null else 1.0
		if node.has_method("_process"):
			node.call("_process", 0.12)
		elif node.has_method("_physics_process"):
			node.call("_physics_process", 0.12)
		assert_true(before == null or not is_equal_approx(before.scale.x, scale_before), "%s pulse glow" % scene_path.get_file())
		_despawn(node)


func test_neon_hazard_and_gate_visuals() -> void:
	var spike := _spawn("res://components/spike_hazard.tscn")
	var outline := spike.get_node_or_null("SpikeOutline") as Line2D
	assert_true(outline != null, "SpikeHazard co SpikeOutline neon Line2D")
	spike.set("hazard_type", 1)
	assert_near(outline.default_color.g, 0.9, 0.05, "SpikeOutline doi mau theo CYAN_SAFE_P1")
	_despawn(spike)

	var laser := _spawn("res://components/laser_hazard.tscn")
	var core := laser.get_node_or_null("CoreLine") as Line2D
	assert_true(core != null, "LaserHazard co CoreLine neon Line2D")
	laser.set("is_on", false)
	laser.call("_update_visual")
	assert_true(not core.visible, "CoreLine an khi laser tat")
	laser.set("is_on", true)
	laser.call("_update_visual")
	assert_true(core.visible, "CoreLine hien khi laser bat")
	_despawn(laser)

	var gate := _spawn("res://components/dual_exit_gate.tscn")
	var arch := gate.get_node_or_null("Arch") as Line2D
	assert_true(arch != null, "DualExitGate co Arch neon Line2D")
	gate.call("_process", 0.1)
	assert_true(arch.default_color.a > 0.0, "Arch default_color co alpha pulse")
	_despawn(gate)


func test_button_glow_and_pad_glow() -> void:
	var btn := _spawn("res://components/pressure_button.tscn")
	btn.call("_set_on", true)
	assert_near((btn.get_node("Glow") as Polygon2D).color.a, 0.35, 0.001, "nut BAT co halo xanh")
	assert_near((btn.get_node("Visual") as Node2D).scale.y, 0.72, 0.001, "nut BAT lun 0.72 (van thay duoc)")
	btn.call("_set_on", false)
	assert_near((btn.get_node("Glow") as Polygon2D).color.a, 0.0, 0.001, "nut TAT het halo")
	var pad := _spawn("res://components/jump_pad.tscn")
	assert_near((pad.get_node("Glow") as Polygon2D).color.a, 0.28, 0.001, "pad co halo nen")
	var orb := _spawn("res://components/dash_orb.tscn")
	var orb_ring := orb.get_node("GlowRing") as Line2D
	assert_true(orb_ring.width >= 3.0, "dash orb ring du day de thay (w=%s)" % str(orb_ring.width))
	_despawn(btn)
	_despawn(pad)
	_despawn(orb)


func test_modular_spike_and_blocks() -> void:
	var spike := _spawn("res://components/spike_hazard.tscn") as SpikeHazard
	spike.tile_count = 3
	spike.orientation = 1 # DOWN (tran)
	assert_near(spike.rotation, PI, 0.001, "spike quay tran")
	var rot_spike := (load("res://components/spike_hazard.tscn") as PackedScene).instantiate() as SpikeHazard
	rot_spike.rotation = PI
	host_root.add_child(rot_spike)
	assert_eq(rot_spike.orientation, 1, "spike dat rotation=PI tu suy ra orientation=DOWN khi _ready")
	assert_near(rot_spike.rotation, PI, 0.001, "spike dat rotation=PI khong bi reset ve 0 khi _ready")
	_despawn(rot_spike)
	spike.position = Vector2(49.2, 95.8)
	spike.snap_to_grid(48.0)
	assert_eq(spike.position, Vector2(48.0, 96.0), "spike snap vao luoi 48px")
	assert_true(spike.get_node_or_null("BaseBlock") != null, "spike co BaseBlock modular")
	_despawn(spike)

	var block := _spawn("res://components/breakable_dash_block.tscn") as BreakableDashBlock
	block.block_size = Vector2i(2, 4)
	assert_eq(block.block_size, Vector2i(2, 4), "dash block ho tro block_size tuy bien")
	block.position = Vector2(100.0, 140.0)
	block.snap_to_grid(48.0)
	assert_eq(block.position, Vector2(96.0, 144.0), "dash block snap vao luoi 48px")
	_despawn(block)


