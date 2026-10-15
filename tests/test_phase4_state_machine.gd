extends "res://tests/gdx_test.gd"

func test_state_factories() -> void:
	var packed := load("res://characters/player.tscn") as PackedScene
	var player := packed.instantiate() as GdxPlayer
	host_root.add_child(player)
	var machine := StateMachine.new()
	assert_true(machine.get_cube_state(player, null) is CubeState, "CubeState factory")
	assert_true(machine.get_ship_state(player, null) is ShipState, "ShipState factory")
	assert_true(machine.get_ufo_state(player, null) is UfoState, "UfoState factory")
	assert_true(machine.get_dash_state(player, null) is DashState, "DashState factory")
	host_root.remove_child(player)
	player.free()

func test_ship_tether_contract() -> void:
	var packed := load("res://characters/player.tscn") as PackedScene
	var player := packed.instantiate() as GdxPlayer
	host_root.add_child(player)
	player.switch_form(&"SHIP")
	var beam: Area2D = (player.current_state as ShipState).get_tether_beam()
	assert_true(beam != null, "Ship creates TetherBeam")
	assert_true(beam.get_node_or_null("TetherLine") is Line2D, "TetherBeam has visual line")
	var shape := beam.get_node_or_null("TetherShape") as CollisionShape2D
	assert_true(shape != null and shape.shape is RectangleShape2D, "TetherBeam has rectangle sensor")
	if shape != null and shape.shape is RectangleShape2D:
		assert_eq((shape.shape as RectangleShape2D).size, Vector2(140, 8), "TetherBeam range 140")
	host_root.remove_child(player)
	player.free()

func test_dash_contract() -> void:
	var packed := load("res://characters/player.tscn") as PackedScene
	var player := packed.instantiate() as GdxPlayer
	host_root.add_child(player)
	player.switch_form(&"DASH")
	var dash := player.current_state as DashState
	dash.activate_dash(1)
	assert_true(dash.is_dashing, "Dash activates")
	assert_eq(player.velocity.x, 950.0, "Dash speed 950")
	assert_eq(player.velocity.y, 0.0, "Dash locks vertical velocity")
	dash.physics_update(0.3)
	assert_true(not dash.is_dashing, "Dash expires after 0.22s")
	host_root.remove_child(player)
	player.free()

func test_head_platform_is_physical_one_way() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	host_root.add_child(player)
	var platform := player.get_node("HeadPlatform") as AnimatableBody2D
	var shape := player.get_node_or_null("HeadPlatform/CollisionShape2D") as CollisionShape2D
	assert_true(platform != null, "T4.03 head platform is physical AnimatableBody2D")
	assert_true(shape != null and shape.one_way_collision, "T4.03 head platform is one-way")
	assert_eq(platform.collision_layer, 2, "T4.03 P1 head platform exposes P1 layer")
	assert_eq(platform.collision_mask, 4, "T4.03 P1 head platform receives P2")
	host_root.remove_child(player)
	player.free()

func test_ship_tether_action_and_force() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	var target := CharacterBody2D.new()
	host_root.add_child(player)
	host_root.add_child(target)
	player.switch_form(&"SHIP")
	player._update_form_visibility()
	var ship := player.current_state as ShipState
	var beam := ship.get_tether_beam()
	assert_true(beam.collision_mask & 128 != 0, "T4.05 tether detects Pushable_Blocks")
	assert_true(beam.position.distance_to(Vector2(0, 28)) < 1.0, "T4.05 tether sits below ship belly")
	assert_eq((beam.get_node_or_null("TetherLine") as Line2D).points.size(), 2, "T4.05 tether line has endpoints")
	assert_true(not (beam.get_node_or_null("TetherLine") as Line2D).visible, "T4.05 tether is gated off without action")
	Input.action_press("p1_action")
	ship._update_tether(1.0 / 120.0)
	Input.action_release("p1_action")
	assert_true((beam.get_node_or_null("TetherLine") as Line2D).visible, "T4.05 action enables tether line")
	target.velocity = Vector2.ZERO
	ship.apply_tether_force(target, 0.1)
	assert_true(target.velocity.y < 0.0, "T4.05 tether applies upward force to CharacterBody2D")
	host_root.remove_child(target)
	host_root.remove_child(player)
	target.free()
	player.free()

func test_ship_horizontal_thrust_and_gravity_orientation() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	host_root.add_child(player)
	player.switch_form(&"SHIP")
	Input.action_press("p1_right")
	player.current_state.physics_update(0.1)
	Input.action_release("p1_right")
	assert_true(player.velocity.x > 0.0, "T4.04 ship responds horizontally")
	player.set_gravity_direction(-1)
	player.velocity.y = 0.0
	player.current_state.physics_update(0.1)
	assert_true(player.velocity.y > 0.0, "T4.04 inverted ship fall direction")
	var platform := player.get_node("HeadPlatform") as AnimatableBody2D
	player.visual_root.rotation = 0.4
	player.current_state.physics_update(0.01)
	assert_near(platform.global_rotation, 0.0, 0.001, "T4.04 carrier stays globally horizontal")
	host_root.remove_child(player)
	player.free()

func test_cube_jump_squash_is_applied() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	host_root.add_child(player)
	player._coyote_timer = 0.1
	Input.action_press("p1_jump")
	player.current_state.update_visuals(1.0 / 120.0)
	Input.action_release("p1_jump")
	assert_eq(player.visual_root.scale, Vector2(1.3, 0.7), "T4.02 cube applies jump squash before tween")
	host_root.remove_child(player)
	player.free()

func test_dash_consumes_and_recharges() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	host_root.add_child(player)
	player.switch_form(&"DASH")
	var dash := player.current_state as DashState
	dash.activate_dash(-1)
	assert_true(not dash.dash_ready, "T4.07 dash consumes readiness")
	dash.physics_update(0.3)
	assert_true(not dash.is_dashing, "T4.07 dash ends after duration")
	dash.recharge_dash()
	assert_true(dash.dash_ready, "T4.07 dash recharges")
	assert_true((player.visual_root.get_node("DashIndicator") as Polygon2D).color != Color(0.15, 0.15, 0.2, 1), "T4.07 dash indicator restores")
	dash.activate_dash(1)
	player._physics_process(1.0 / 120.0)
	assert_near(player.velocity.y, 0.0, 0.001, "T4.07 active dash locks gravity in player physics")
	host_root.remove_child(player)
	player.free()

func test_ufo_hop_wave_and_form_visibility() -> void:
	var gravity_player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	gravity_player.player_id = 2
	host_root.add_child(gravity_player)
	gravity_player.switch_form(&"UFO")
	gravity_player.velocity.y = 0.0
	gravity_player.current_state.physics_update(0.1)
	assert_true(gravity_player.velocity.y > -UfoState.HOP_SPEED, "T4.06 UFO gravity modifies vertical speed got=%s form=%s gravity=%s" % [str(gravity_player.velocity.y), str(gravity_player.form), str(gravity_player.gravity_direction)])
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	player.player_id = 2
	host_root.add_child(player)
	player.switch_form(&"UFO")
	player._update_form_visibility()
	assert_true(player.get_node("VisualRoot/FormVisuals/UfoVisual").visible, "T4.08 UFO visual branch visible")
	assert_true(not player.get_node("VisualRoot/FormVisuals/CubeVisual").visible, "T4.08 Cube visual branch hidden")
	assert_true((player.get_node("VisualRoot/FillPolygon") as Polygon2D).polygon.size() > 0, "T4.08 UFO has rendered polygon geometry")
	Input.action_press("p2_jump")
	player.current_state.physics_update(1.0 / 120.0)
	Input.action_release("p2_jump")
	assert_true(player.visual_root.get_node_or_null("UfoHopWave") != null, "T4.06 UFO hop creates wave")
	host_root.remove_child(gravity_player)
	host_root.remove_child(player)
	gravity_player.free()
	player.free()

func test_carrier_fallback_and_dash_orb() -> void:
	var player := (load("res://characters/player.tscn") as PackedScene).instantiate() as GdxPlayer
	host_root.add_child(player)
	var platform := player.get_node_or_null("HeadPlatform") as Node
	if platform != null:
		player.remove_child(platform)
		platform.free()
	var fallback := (player.current_state as CubeState).get_head_platform()
	assert_true(fallback is AnimatableBody2D, "T4.03 fallback remains physical carrier")
	var shape := fallback.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_true(shape != null, "T4.03 fallback creates collision shape children=%s" % str(fallback.get_children()))
	if shape != null:
		assert_true(shape.one_way_collision, "T4.03 fallback remains one-way")
	var rider := CharacterBody2D.new()
	host_root.add_child(rider)
	fallback.carrier_velocity = Vector2(120, 0)
	fallback.transfer_velocity(rider)
	assert_eq(rider.velocity.x, 120.0, "T4.03 carrier transfers horizontal velocity")
	player.switch_form(&"DASH")
	var orb := (load("res://components/dash_orb.tscn") as PackedScene).instantiate() as DashOrb
	host_root.add_child(orb)
	var dash := player.current_state as DashState
	dash.activate_dash(1)
	assert_true(not dash.dash_ready, "T4.07 orb setup consumes dash")
	assert_true(orb.recharge(player), "T4.07 DashOrb recharges Dash")
	assert_true(dash.dash_ready, "T4.07 DashOrb restores readiness")
	host_root.remove_child(orb)
	host_root.remove_child(rider)
	host_root.remove_child(player)
	orb.free()
	rider.free()
	player.free()
