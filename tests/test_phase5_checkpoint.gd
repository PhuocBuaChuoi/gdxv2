extends "res://tests/gdx_test.gd"

const PlayerScene := preload("res://characters/player.tscn")
const RestoreScene := preload("res://components/restore_point.tscn")
const CoordinatorScript := preload("res://components/respawn_coordinator.gd")
const CameraScene := preload("res://components/coop_camera.tscn")

func _players() -> Array:
	var p1 := PlayerScene.instantiate() as GdxPlayer
	var p2 := PlayerScene.instantiate() as GdxPlayer
	p1.player_id = 1
	p2.player_id = 2
	host_root.add_child(p1)
	host_root.add_child(p2)
	return [p1, p2]

func _cleanup(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()

func test_snapshot_captures_form_gravity_and_spawn() -> void:
	var players := _players()
	var p1: GdxPlayer = players[0]
	var p2: GdxPlayer = players[1]
	p1.global_position = Vector2(10, 20)
	p2.global_position = Vector2(30, 40)
	p1.switch_form(&"SHIP")
	p2.switch_form(&"UFO")
	p1.set_gravity_direction(-1)
	var snap := CheckpointSnapshot.from_players(p1, p2)
	assert_eq(snap.spawn_pos_p1, Vector2(10, 20), "T5.02 snapshot stores P1 position")
	assert_eq(snap.spawn_pos_p2, Vector2(30, 40), "T5.02 snapshot stores P2 position")
	assert_eq(snap.form_p1, &"SHIP", "T5.02 snapshot stores P1 form")
	assert_eq(snap.form_p2, &"UFO", "T5.02 snapshot stores P2 form")
	assert_eq(snap.gravity_p1, -1, "T5.02 snapshot stores P1 gravity")
	assert_eq(snap.gravity_p2, 1, "T5.02 snapshot stores P2 gravity")
	_cleanup(players)

func test_respawn_synchronizes_after_delay() -> void:
	var players := _players()
	var p1: GdxPlayer = players[0]
	var p2: GdxPlayer = players[1]
	p1.global_position = Vector2(100, 110)
	p2.global_position = Vector2(200, 210)
	p1.switch_form(&"SHIP")
	p2.switch_form(&"UFO")
	p1.set_gravity_direction(-1)
	var coordinator := CoordinatorScript.new() as RespawnCoordinator
	host_root.add_child(coordinator)
	coordinator.register_players(p1, p2)
	assert_true(coordinator.checkpoint != null, "T5.04 registration captures initial checkpoint")
	p1.global_position = Vector2(800, 900)
	p2.global_position = Vector2(900, 1000)
	p1.switch_form(&"CUBE")
	p2.switch_form(&"CUBE")
	var reset_count := [0]
	coordinator.level_reset_to_checkpoint.connect(func(_snapshot): reset_count[0] += 1)
	assert_true(coordinator.request_respawn(1), "T5.04 death starts respawn")
	assert_eq(coordinator.attempt_count, 1, "T5.04 increments attempt count")
	assert_true(p1.control_locked and p2.control_locked, "T5.04 locks both controls during respawn")
	assert_true(not p1.is_physics_processing() and not p2.is_physics_processing(), "T5.04 pauses player physics during respawn")
	assert_true(not p1.visual_root.visible and not p2.visual_root.visible, "T5.04 hides both visuals during respawn")
	assert_true(not coordinator.request_respawn(2), "T5.04 ignores duplicate death during delay")
	coordinator._process(0.34)
	assert_eq(p1.global_position, Vector2(800, 900), "T5.04 delay has not elapsed at 0.34s")
	coordinator._process(0.01)
	assert_eq(p1.global_position, Vector2(100, 110), "T5.04 restores P1 spawn")
	assert_eq(p2.global_position, Vector2(200, 210), "T5.04 restores P2 spawn")
	assert_eq(p1.form, &"SHIP", "T5.04 restores P1 form")
	assert_eq(p2.form, &"UFO", "T5.04 restores P2 form")
	assert_eq(p1.gravity_direction, -1, "T5.04 restores P1 gravity")
	assert_true(not p1.control_locked and not p2.control_locked, "T5.04 unlocks both controls")
	assert_true(p1.is_physics_processing() and p2.is_physics_processing(), "T5.04 resumes player physics after respawn")
	assert_true(p1.visual_root.visible and p2.visual_root.visible, "T5.04 shows both visuals")
	assert_eq(reset_count[0], 1, "T5.04 emits level_reset_to_checkpoint")
	_cleanup([coordinator, p1, p2])

func test_restore_point_order_require_both_and_spawn_event() -> void:
	var parent := Node2D.new()
	host_root.add_child(parent)
	var old := RestoreScene.instantiate() as RestorePoint
	old.checkpoint_order = 1
	parent.add_child(old)
	assert_true(old.activate(1), "T5.01 first checkpoint activates")
	var stale := RestoreScene.instantiate() as RestorePoint
	stale.checkpoint_order = 0
	parent.add_child(stale)
	assert_true(not stale.activate(1), "T5.03 older checkpoint cannot reactivate after newer")
	var both := RestoreScene.instantiate() as RestorePoint
	both.checkpoint_order = 2
	both.require_both_players = true
	parent.add_child(both)
	var s1 := both.get_node("SpawnP1") as Marker2D
	var s2 := both.get_node("SpawnP2") as Marker2D
	s1.position = Vector2(-40, 12)
	s2.position = Vector2(40, 12)
	var event_data := [0, Vector2.ZERO, Vector2.ZERO]
	var callback := func(order: int, pos1: Vector2, pos2: Vector2):
		event_data[0] = order
		event_data[1] = pos1
		event_data[2] = pos2
	Events.checkpoint_activated.connect(callback)
	assert_true(not both.activate(1), "T5.03 require-both waits for P2")
	assert_true(both.activate(2), "T5.03 require-both activates on second player")
	assert_true(not both.activate(1), "T5.03 active checkpoint ignores duplicate activation")
	assert_true(both.get_node_or_null("ActivationParticles") is GPUParticles2D, "T5.03 activation emits particles")
	assert_eq(event_data[0], 2, "T5.03 event carries checkpoint order")
	assert_eq(event_data[1], s1.global_position, "T5.03 event carries P1 spawn")
	assert_eq(event_data[2], s2.global_position, "T5.03 event carries P2 spawn")
	Events.checkpoint_activated.disconnect(callback)
	_cleanup([parent])

# reset_activation() rơi vào giữa tween kích hoạt (rotation +TAU, scale 1.2) phải
# dừng tween và trả node về tư thế nghỉ, nếu không crystal bị xoay/phóng mãi mãi
# sau khi hồi sinh.
func test_restore_point_reset_mid_tween_restores_resting_transform() -> void:
	var parent := Node2D.new()
	host_root.add_child(parent)
	var cp := RestoreScene.instantiate() as RestorePoint
	parent.add_child(cp)
	assert_true(cp.activate(1), "T5.01 setup: checkpoint kich hoat")
	# Đúng trạng thái giữa tween: xoay dở và phóng to dở.
	cp.rotation = 1.37
	cp.scale = Vector2(1.18, 1.18)
	cp.reset_activation()
	assert_near(cp.rotation, 0.0, 0.0001, "T5.01 reset giua tween tra rotation ve 0")
	assert_eq(cp.scale, Vector2.ONE, "T5.01 reset giua tween tra scale ve 1")
	_cleanup([parent])

func test_coop_camera_midpoint_and_zoom() -> void:
	var p1 := Node2D.new()
	var p2 := Node2D.new()
	var camera := CameraScene.instantiate() as CoopCamera
	host_root.add_child(p1)
	host_root.add_child(p2)
	host_root.add_child(camera)
	camera.set_players(p1, p2)
	p1.global_position = Vector2(0, 0)
	p2.global_position = Vector2(200, 0)
	camera._process(1.0)
	assert_eq(camera.global_position, Vector2(100, 0), "T5.05 camera follows player midpoint")
	assert_near(camera.zoom.x, camera.max_zoom, 0.001, "T5.06 camera stays zoomed in nearby")
	p2.global_position = Vector2(1000, 0)
	camera._process(1.0)
	assert_eq(camera.global_position, Vector2(500, 0), "T5.05 camera updates midpoint")
	assert_near(camera.zoom.x, camera.min_zoom, 0.001, "T5.06 camera zooms out for separation")
	assert_true(camera.distance_warning_visible, "T5.06 warns when players exceed soft distance")
	assert_true(camera.distance_warning_direction.x > 0.0, "T5.06 warning points toward teammate")
	var terrain := TileMapLayer.new()
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(32, 32)
	atlas.create_tile(Vector2i.ZERO)
	tileset.add_source(atlas, 0)
	terrain.tile_set = tileset
	host_root.add_child(terrain)
	terrain.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
	camera.set_terrain_limits(terrain)
	assert_true(camera.limit_right > camera.limit_left and camera.limit_bottom > camera.limit_top, "T5.05 camera limits follow terrain bounds")
	camera.shake(8.0, 0.2)
	camera._process(0.016)
	assert_true(camera.offset.length() > 0.0, "T5.04 camera shake is applied")
	_cleanup([terrain, camera, p1, p2])

func test_base_level_wires_phase5_nodes() -> void:
	var level := (load("res://levels/base_level.tscn") as PackedScene).instantiate()
	host_root.add_child(level)
	assert_true(level.get_node_or_null("Players/PlayerP1") is GdxPlayer, "T5.07 base level has P1")
	assert_true(level.get_node_or_null("Players/PlayerP2") is GdxPlayer, "T5.07 base level has P2")
	assert_true(level.get_node_or_null("RespawnCoordinator") is RespawnCoordinator, "T5.07 base level has coordinator")
	var coordinator := level.get_node("RespawnCoordinator") as RespawnCoordinator
	assert_true(coordinator.checkpoint != null, "T5.07 base level captures initial checkpoint")
	var camera := level.get_node("CoopCamera") as CoopCamera
	assert_true(camera.player_one != null and camera.player_two != null, "T5.07 camera receives both players")
	assert_true(level.get_node_or_null("Checkpoints/RestorePointStart") is RestorePoint, "T5.07 base level wires restore point")
	assert_true(level.get_node_or_null("LevelHUD/AttemptLabel") is Label, "T5.04 base level wires attempt HUD")
	assert_true((level.get_node("RespawnCoordinator") as RespawnCoordinator).level_reset_to_checkpoint.is_connected(Callable(level, "_on_level_reset_to_checkpoint")), "T5.04 reset signal reaches level controller")
	var restore := level.get_node("Checkpoints/RestorePointStart") as RestorePoint
	var p1 := level.get_node("Players/PlayerP1") as GdxPlayer
	restore._on_body_entered(p1)
	assert_eq((level.get_node("RespawnCoordinator") as RespawnCoordinator).checkpoint.checkpoint_order, 0, "T5.01 body entry updates coordinator snapshot")
	_cleanup([level])

func test_invalid_death_id_is_rejected() -> void:
	var players := _players()
	var coordinator := CoordinatorScript.new() as RespawnCoordinator
	host_root.add_child(coordinator)
	coordinator.register_players(players[0], players[1])
	assert_true(not coordinator.request_respawn(3), "T5.04 invalid death id rejected")
	assert_eq(coordinator.attempt_count, 0, "T5.04 invalid death does not increment attempts")
	_cleanup([coordinator, players[0], players[1]])

func test_hazard_signal_starts_coop_respawn() -> void:
	var players := _players()
	var coordinator := CoordinatorScript.new() as RespawnCoordinator
	host_root.add_child(coordinator)
	coordinator.register_players(players[0], players[1])
	var hazard := Area2D.new()
	host_root.add_child(hazard)
	players[0]._on_hazard_area_entered(hazard)
	assert_eq(coordinator.attempt_count, 1, "T5.04 hazard signal increments attempt")
	assert_true(players[0].control_locked and players[1].control_locked, "T5.04 hazard signal locks both players")
	players[0]._on_hazard_area_entered(hazard)
	assert_eq(coordinator.attempt_count, 1, "T5.04 duplicate hazard does not start a second respawn")
	_cleanup([hazard, coordinator, players[0], players[1]])

func test_coordinator_rejects_duplicate_or_older_checkpoint_order() -> void:
	var players := _players()
	var coordinator := CoordinatorScript.new() as RespawnCoordinator
	host_root.add_child(coordinator)
	coordinator.register_players(players[0], players[1])
	assert_true(coordinator.activate_checkpoint(3, Vector2(30, 0), Vector2(60, 0)), "T5.03 coordinator accepts newer order")
	assert_true(not coordinator.activate_checkpoint(3, Vector2(300, 0), Vector2(600, 0)), "T5.03 duplicate order cannot overwrite snapshot")
	assert_true(not coordinator.activate_checkpoint(2, Vector2(200, 0), Vector2(400, 0)), "T5.03 older order cannot overwrite snapshot")
	assert_eq(coordinator.checkpoint.spawn_pos_p1, Vector2(30, 0), "T5.03 newer snapshot remains authoritative")
	var replacement := CheckpointSnapshot.from_players_at(players[0], players[1], Vector2(90, 0), Vector2(120, 0))
	replacement.checkpoint_order = 3
	assert_true(not coordinator.set_checkpoint(replacement), "T5.03 set_checkpoint rejects duplicate order")
	assert_eq(coordinator.checkpoint.spawn_pos_p1, Vector2(30, 0), "T5.03 set_checkpoint preserves authoritative snapshot")
	_cleanup([coordinator, players[0], players[1]])
