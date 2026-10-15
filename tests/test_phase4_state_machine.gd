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
