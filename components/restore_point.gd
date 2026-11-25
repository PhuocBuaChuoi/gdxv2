class_name RestorePoint
extends Area2D

## T5.01/T5.03 — ordered co-op checkpoint with activation feedback.
signal activated(checkpoint: RestorePoint, player_id: int)

const TEX_INACTIVE = preload("res://assets/sprites/restore_point_anim.png")
const TEX_ACTIVE = preload("res://assets/sprites/restore_point_active_anim.png")

@export var checkpoint_order: int = 0
@export var require_both_players: bool = false
var is_active: bool = false
var _touched_players: Dictionary = {}
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("restore_points")
	body_entered.connect(_on_body_entered)
	SpriteAnim.setup_sheet(get_node_or_null("CrystalSprite") as Sprite2D, TEX_INACTIVE, 4)


func _process(delta: float) -> void:
	_anim_time += delta
	SpriteAnim.step_sheet(get_node_or_null("CrystalSprite") as Sprite2D, _anim_time, 6.0, 4)

func _on_body_entered(body: Node2D) -> void:
	if body is GdxPlayer:
		activate((body as GdxPlayer).player_id)

func activate(player_id: int) -> bool:
	if player_id not in [1, 2] or is_active:
		return false
	if checkpoint_order < _highest_active_order():
		return false
	_touched_players[player_id] = true
	if require_both_players and not (_touched_players.has(1) and _touched_players.has(2)):
		return false
	is_active = true
	var diamond := get_node_or_null("Diamond") as Polygon2D
	if diamond != null:
		diamond.color = Color(0.15, 0.9, 0.35, 0.95)
	var inner_glow := get_node_or_null("InnerGlow") as Polygon2D
	if inner_glow != null:
		inner_glow.color = Color(0.2, 1.0, 0.4, 0.8)
	var spr := get_node_or_null("CrystalSprite") as Sprite2D
	if spr != null:
		spr.texture = TEX_ACTIVE
	var particles := get_node_or_null("ActivationParticles") as GPUParticles2D
	if particles != null:
		particles.one_shot = true
		particles.amount = 14
		particles.restart()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "rotation", rotation + TAU, 0.35)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.12)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.12)
	_spawn_activation_particles()
	AudioManager.play_sfx("checkpoint")
	activated.emit(self, player_id)
	Events.checkpoint_activated.emit(checkpoint_order, _spawn_position(1), _spawn_position(2))
	return true

func _highest_active_order() -> int:
	var highest := -1
	for node in get_tree().get_nodes_in_group("restore_points"):
		if node is RestorePoint and (node as RestorePoint).is_active:
			highest = maxi(highest, (node as RestorePoint).checkpoint_order)
	return highest

func _spawn_position(player_id: int) -> Vector2:
	var marker_name := "SpawnP1" if player_id == 1 else "SpawnP2"
	var marker := get_node_or_null(marker_name) as Node2D
	return marker.global_position if marker != null else global_position

func reset_activation() -> void:
	is_active = false
	_touched_players.clear()
	var particles := get_node_or_null("ActivationParticles") as GPUParticles2D
	if particles != null:
		particles.emitting = false
	var diamond := get_node_or_null("Diamond") as Polygon2D
	if diamond != null:
		diamond.color = Color(0.06, 0.15, 0.25, 0.9)
	var inner_glow := get_node_or_null("InnerGlow") as Polygon2D
	if inner_glow != null:
		inner_glow.color = Color(0.2, 0.85, 1, 0.6)
	var spr := get_node_or_null("CrystalSprite") as Sprite2D
	if spr != null:
		spr.texture = TEX_INACTIVE

func _spawn_activation_particles() -> void:
	var existing := get_node_or_null("ActivationParticles") as GPUParticles2D
	if existing != null:
		existing.emitting = true
		return
	var particles := GPUParticles2D.new()
	particles.name = "ActivationParticles"
	particles.amount = 18
	particles.lifetime = 0.45
	particles.one_shot = true
	particles.explosiveness = 1.0
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 6.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 45.0
	material.initial_velocity_max = 90.0
	material.gravity = Vector3(0, 80, 0)
	material.color = Color(0.25, 1.0, 0.4, 1.0)
	particles.process_material = material
	add_child(particles)
	particles.emitting = true
