class_name RespawnCoordinator
extends Node

## T5.04 — one death respawns both players from the latest snapshot.
signal level_reset_to_checkpoint(snapshot: CheckpointSnapshot)
signal attempt_changed(attempt_count: int)
## Tín hiệu cục bộ (mỗi level một coordinator) để level_controller đếm deaths
## mà không bị rò qua signal bus toàn cục giữa các màn/test.
signal death_counted(player_id: int)

@export var respawn_delay: float = 0.35
var player_one: GdxPlayer
var player_two: GdxPlayer
var checkpoint: CheckpointSnapshot
var attempt_count: int = 0
var latest_checkpoint_order: int = -1
var _respawn_timer: float = -1.0
var _death_explosion_scene: PackedScene = preload("res://vfx/death_explosion.tscn")
var camera: CoopCamera

func register_players(p1: GdxPlayer, p2: GdxPlayer) -> void:
	_disconnect_player_death(player_one)
	_disconnect_player_death(player_two)
	player_one = p1
	player_two = p2
	_connect_player_death(player_one)
	_connect_player_death(player_two)
	if checkpoint == null:
		capture_checkpoint()
	if camera == null:
		camera = get_parent().get_node_or_null("CoopCamera") as CoopCamera

func _ready() -> void:
	if not Events.checkpoint_activated.is_connected(_on_checkpoint_activated):
		Events.checkpoint_activated.connect(_on_checkpoint_activated)

func _exit_tree() -> void:
	_disconnect_player_death(player_one)
	_disconnect_player_death(player_two)
	if Events.checkpoint_activated.is_connected(_on_checkpoint_activated):
		Events.checkpoint_activated.disconnect(_on_checkpoint_activated)


func _connect_player_death(player: GdxPlayer) -> void:
	if player != null and not player.death_requested.is_connected(_on_player_death_requested):
		player.death_requested.connect(_on_player_death_requested)


func _disconnect_player_death(player: GdxPlayer) -> void:
	if player != null and is_instance_valid(player) and player.death_requested.is_connected(_on_player_death_requested):
		player.death_requested.disconnect(_on_player_death_requested)


func _on_player_death_requested(death_player_id: int, _death_pos: Vector2) -> void:
	AudioManager.play_sfx("death")
	request_respawn(death_player_id)

func set_checkpoint(snapshot: CheckpointSnapshot, order: int = -1) -> bool:
	if snapshot == null:
		return false
	var incoming_order := order if order >= 0 else snapshot.checkpoint_order
	if checkpoint != null and incoming_order >= 0 and incoming_order <= latest_checkpoint_order:
		return false
	checkpoint = snapshot
	if incoming_order >= 0:
		latest_checkpoint_order = incoming_order
	return true

func activate_checkpoint(order: int, spawn_p1: Vector2, spawn_p2: Vector2) -> bool:
	if player_one == null or player_two == null or order <= latest_checkpoint_order:
		return false
	checkpoint = CheckpointSnapshot.from_players_at(player_one, player_two, spawn_p1, spawn_p2)
	checkpoint.checkpoint_order = order
	latest_checkpoint_order = order
	return true

func _on_checkpoint_activated(order: int, spawn_p1: Vector2, spawn_p2: Vector2) -> void:
	activate_checkpoint(order, spawn_p1, spawn_p2)

func capture_checkpoint() -> bool:
	if player_one == null or player_two == null:
		return false
	checkpoint = CheckpointSnapshot.from_players(player_one, player_two)
	return true

func is_respawning() -> bool:
	return _respawn_timer >= 0.0


func request_respawn(death_player_id: int) -> bool:
	if death_player_id not in [1, 2] or checkpoint == null or player_one == null or player_two == null or _respawn_timer >= 0.0:
		return false
	attempt_count += 1
	attempt_changed.emit(attempt_count)
	var dead: GdxPlayer = player_one if death_player_id == 1 else player_two
	var explosion := _death_explosion_scene.instantiate() as Node2D
	if explosion != null:
		explosion.global_position = dead.global_position
		add_child(explosion)
	for player in [player_one, player_two]:
		player.set_control_locked(true)
		player.set_physics_process(false)
	player_one.visual_root.visible = false
	player_two.visual_root.visible = false
	_respawn_timer = respawn_delay
	if camera != null:
		camera.shake(8.0, 0.2)
	Events.player_died.emit(death_player_id, dead.global_position)
	death_counted.emit(death_player_id)
	return true

func _process(delta: float) -> void:
	if _respawn_timer < 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_respawn_timer = -1.0
		_perform_respawn()

func _perform_respawn() -> void:
	if checkpoint == null:
		return
	player_one.global_position = checkpoint.spawn_pos_p1
	player_two.global_position = checkpoint.spawn_pos_p2
	player_one.velocity = Vector2.ZERO
	player_two.velocity = Vector2.ZERO
	player_one.set_gravity_direction(checkpoint.gravity_p1)
	player_two.set_gravity_direction(checkpoint.gravity_p2)
	player_one.switch_form(checkpoint.form_p1)
	player_two.switch_form(checkpoint.form_p2)
	player_one.visual_root.visible = true
	player_two.visual_root.visible = true
	player_one.set_control_locked(false)
	player_two.set_control_locked(false)
	player_one.set_physics_process(true)
	player_two.set_physics_process(true)
	player_one.reset_death_state()
	player_two.reset_death_state()
	level_reset_to_checkpoint.emit(checkpoint)
