extends "res://tests/gdx_test.gd"

## Phase 6 còn thiếu (T6.01/03/04/06/07/08): form_portal, jump_pad,
## jump_orb, pressure_button, mechanized_platform, breakable_dash_block.


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
	var body := CharacterBody2D.new()
	host_root.add_child(body)
	assert_near(float(pad.call("boost_value")), 950.0, 0.001, "T6.03 YELLOW = trung binh")
	pad.set("pad_type", 1)
	assert_near(float(pad.call("boost_value")), 450.0, 0.001, "T6.03 PINK = thap")
	pad.set("pad_type", 2)
	assert_near(float(pad.call("boost_value")), 1400.0, 0.001, "T6.03 RED = cuc cao")
	pad.call("_on_body_entered", body)
	assert_near(body.velocity.y, -1400.0, 0.001, "T6.03 cham la phong len")
	var pad_color := (pad.get_node("Pad") as Polygon2D).color
	assert_true(pad_color.r > 0.9 and pad_color.g < 0.4, "T6.03 mau RED doi mau")
	host_root.remove_child(body)
	body.free()
	_despawn(pad)


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
	assert_true(block.is_queued_for_deletion(), "T6.08 khoi bi xoa sau khi pha")
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
	]:
		assert_true(lvl.get_node_or_null(p) != null, "template co " + p)
	var plat := lvl.get_node_or_null("Mechanisms/MechanizedPlatform") as MechanizedPlatform
	assert_true(plat != null and plat.linked_triggers.size() == 1, "T6.07 template noi 1 nut")
	_despawn(lvl)


func test_neon_interaction_visuals() -> void:
	for scene_path in ["res://components/jump_pad.tscn", "res://components/jump_orb.tscn", "res://components/gravity_portal.tscn", "res://components/form_portal.tscn"]:
		var node := _spawn(scene_path)
		assert_true(node.get_node_or_null("Glow") != null or node.get_node_or_null("GlowRing") != null, "%s co glow neon" % scene_path.get_file())
		var before := node.get_node_or_null("Glow") as Node2D
		if before == null:
			before = node.get_node_or_null("GlowRing") as Node2D
		var scale_before := before.scale.x if before != null else 1.0
		if node.has_method("_process"):
			node.call("_process", 0.12)
		else:
			node.call("_physics_process", 0.12)
		assert_true(before == null or not is_equal_approx(before.scale.x, scale_before), "%s pulse glow" % scene_path.get_file())
		_despawn(node)
