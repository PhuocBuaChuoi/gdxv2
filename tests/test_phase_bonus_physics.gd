extends "res://tests/gdx_test.gd"

func test_gravity_portal_scene_and_player() -> void:
	var packed := load("res://components/gravity_portal.tscn") as PackedScene
	assert_true(packed != null, "GravityPortal scene load")
	var portal := packed.instantiate() as GravityPortal
	var player_scene := load("res://characters/player.tscn") as PackedScene
	var player := player_scene.instantiate() as GdxPlayer
	host_root.add_child(portal)
	host_root.add_child(player)
	portal.target_direction = -1
	portal.apply_to(player)
	assert_eq(player.gravity_direction, -1, "portal inverts player gravity")
	assert_eq(player.up_direction, Vector2.DOWN, "portal updates up_direction")
	portal.target_direction = 1
	portal.apply_to(player)
	assert_eq(player.gravity_direction, 1, "portal restores normal gravity")
	host_root.remove_child(portal)
	host_root.remove_child(player)
	portal.free()
	player.free()

func test_gravity_portal_rigidbody() -> void:
	var portal := (load("res://components/gravity_portal.tscn") as PackedScene).instantiate() as GravityPortal
	var body := RigidBody2D.new()
	body.gravity_scale = 1.0
	host_root.add_child(portal)
	host_root.add_child(body)
	portal.target_direction = -1
	portal.apply_to(body)
	assert_eq(body.gravity_scale, -1.0, "portal inverts rigidbody gravity")
	portal.target_direction = 1
	portal.apply_to(body)
	assert_eq(body.gravity_scale, 1.0, "portal restores rigidbody gravity")
	host_root.remove_child(portal)
	host_root.remove_child(body)
	portal.free()
	body.free()

func test_balanced_float_pair() -> void:
	var pair := (load("res://components/balanced_float_pair.tscn") as PackedScene).instantiate() as BalancedFloatPair
	host_root.add_child(pair)
	var a := pair.get_node("BoxA") as RigidBody2D
	var b := pair.get_node("BoxB") as RigidBody2D
	assert_true(a is FloatingBox and b is FloatingBox, "pair uses FloatingBox bodies")
	assert_eq(a.collision_layer, 128, "box A uses Pushable_Blocks layer")
	assert_eq(b.collision_layer, 128, "box B uses Pushable_Blocks layer")
	assert_eq(a.gravity_scale, 0.0, "pair disables gravity for box A")
	assert_eq(b.gravity_scale, 0.0, "pair disables gravity for box B")
	assert_eq(pair.horizontal_separation, 96.0, "pair separation contract")
	host_root.remove_child(pair)
	pair.free()
