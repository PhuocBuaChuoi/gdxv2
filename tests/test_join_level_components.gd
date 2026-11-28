extends "res://tests/gdx_test.gd"

## JOIN — Gắn component T4/T5/Bonus (GravityPortal, DashOrb, CoopBox,
## BalancedFloatPair) vào container Hazards/Portals/Mechanisms của level
## theo AUTHORING.md, và nối Events/AudioManager vào portal.


func _spawn(path: String) -> Node:
	var n: Node = (load(path) as PackedScene).instantiate()
	host_root.add_child(n)
	return n


func _despawn(n: Node) -> void:
	host_root.remove_child(n)
	n.free()


func _assert_wiring(lvl: Node, tag: String) -> void:
	var portal := lvl.get_node_or_null("Portals/GravityPortal")
	assert_true(portal != null, tag + " GravityPortal trong Portals")
	if portal != null:
		assert_eq(int((portal as Area2D).collision_layer), 64, tag + " portal layer Interactables")
		assert_eq(int((portal as Area2D).collision_mask), 6, tag + " portal mask P1|P2")
	var orb := lvl.get_node_or_null("Mechanisms/DashOrb")
	assert_true(orb != null, tag + " DashOrb trong Mechanisms")
	if orb != null:
		assert_eq(int((orb as Area2D).collision_layer), 64, tag + " orb layer Interactables")
	var box := lvl.get_node_or_null("Mechanisms/CoopBox")
	assert_true(box != null, tag + " CoopBox trong Mechanisms")
	if box != null:
		assert_eq(int((box as RigidBody2D).collision_layer), 128, tag + " box layer Pushable_Blocks")
	var pair := lvl.get_node_or_null("Mechanisms/FloatPair")
	assert_true(pair != null, tag + " FloatPair trong Mechanisms")
	if pair != null:
		var a := (pair as Node).get_node_or_null("BoxA") as RigidBody2D
		var b := (pair as Node).get_node_or_null("BoxB") as RigidBody2D
		assert_true(a != null and b != null, tag + " pair co 2 hop")
		if a != null and b != null:
			assert_near(a.gravity_scale, 0.0, 0.001, tag + " BoxA float (gravity_scale=0)")
			assert_near(b.gravity_scale, 0.0, 0.001, tag + " BoxB float (gravity_scale=0)")


func test_level_01_has_bonus_components() -> void:
	var lvl := _spawn("res://levels/level_01.tscn")
	_assert_wiring(lvl, "JOIN01")
	_despawn(lvl)


func test_base_level_template_has_bonus_components() -> void:
	var lvl := _spawn("res://levels/base_level.tscn")
	_assert_wiring(lvl, "JOIN02")
	_despawn(lvl)


func test_portal_fires_events_and_sfx() -> void:
	var seen := [-999]
	var cb := func(d: int) -> void:
		seen[0] = d
	Events.portal_activated.connect(cb)
	var portal: Node = (load("res://components/gravity_portal.tscn") as PackedScene).instantiate()
	var player: Node = (load("res://characters/player.tscn") as PackedScene).instantiate()
	host_root.add_child(portal)
	host_root.add_child(player)
	portal.call("apply_to", player)
	assert_eq(seen[0], -1, "JOIN03 portal phat portal_activated(-1) khi dao gravity")
	assert_true(bool(AudioManager.call("has_sfx", "portal")), "JOIN03 AudioManager co sfx portal")
	Events.portal_activated.disconnect(cb)
	_despawn(portal)
	_despawn(player)


func test_dual_exit_gate_wins_level() -> void:
	var lvl := _spawn("res://levels/level_01.tscn")
	lvl.call("reset_stats")
	lvl.set("level_time", 42.5)
	lvl.set("deaths", 2)
	var gate := lvl.get_node_or_null("Mechanisms/DualExitGate")
	assert_true(gate != null, "JOIN04 level_01 co DualExitGate (T7.05)")
	assert_near(float(gate.get("hold_time")), 0.5, 0.001, "JOIN04 hold 0.5s theo T6.10")
	var popup := lvl.get_node("LevelHUD/CompletePopup") as Control
	var p1: Node = lvl.get_node("Players/PlayerP1")
	var p2: Node = lvl.get_node("Players/PlayerP2")
	var seen := [0, -1, -1.0]
	var cb := func(i: int, d: int, t: float) -> void:
		seen[0] = i
		seen[1] = d
		seen[2] = t
	Events.level_completed.connect(cb)
	gate.call("_on_body_entered", p1)
	gate.call("_on_body_entered", p2)
	assert_true(bool(gate.call("both_inside")), "JOIN04 ca 2 player dang trong cong")
	gate.call("_physics_process", 0.3)
	assert_eq(seen[0], 0, "JOIN04 chua du 0.5s chua hoan thanh")
	gate.call("_physics_process", 0.3)
	assert_eq(seen[0], 0, "JOIN04 phat level_completed voi level_index=0")
	assert_eq(seen[1], 2, "JOIN04 truyen deaths tu controller")
	assert_near(seen[2], 42.5, 0.001, "JOIN04 truyen level_time tu controller")
	assert_true(bool(gate.call("is_done")), "JOIN04 khong hoan thanh 2 lan")
	assert_true(bool(p1.get("control_locked")) and bool(p2.get("control_locked")), "JOIN04 khoa input ca 2 sau thang")
	assert_true(popup.visible, "JOIN04 popup tu mo khi thang (listener T8.05)")
	var lm: Node = host_root.get_node("/root/LevelManager")
	assert_true((lm.get("best") as Dictionary).has("0"), "JOIN04 LevelManager luu ky luc man 1 (T7.04)")
	Events.level_completed.disconnect(cb)
	_despawn(lvl)


func test_gate_resets_when_player_leaves() -> void:
	var lvl := _spawn("res://levels/level_01.tscn")
	var gate := lvl.get_node("Mechanisms/DualExitGate")
	var p1: Node = lvl.get_node("Players/PlayerP1")
	var p2: Node = lvl.get_node("Players/PlayerP2")
	gate.call("_on_body_entered", p1)
	gate.call("_on_body_entered", p2)
	gate.call("_physics_process", 0.3)
	gate.call("_on_body_exited", p1)
	assert_true(not bool(gate.call("both_inside")), "JOIN05 P2 roi lai cong -> khong con ca 2")
	gate.call("_physics_process", 0.6)
	assert_true(not bool(gate.call("is_done")), "JOIN05 bo dem reset khi co nguoi ra")
	_despawn(lvl)
