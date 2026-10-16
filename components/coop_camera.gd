class_name CoopCamera
extends Camera2D

## T5.05/T5.06 — camera follows midpoint and zooms to keep both players visible.
@export var min_zoom: float = 0.65
@export var max_zoom: float = 1.1
@export var zoom_distance_near: float = 220.0
@export var zoom_distance_far: float = 900.0
@export var max_player_distance: float = 820.0
var player_one: Node2D
var player_two: Node2D
var distance_warning_visible: bool = false
var distance_warning_direction: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO
var _shake_time: float = 0.0
var _shake_amplitude: float = 0.0
@onready var distance_warning: Polygon2D = $DistanceWarning

func set_players(p1: Node2D, p2: Node2D) -> void:
	player_one = p1
	player_two = p2

func set_terrain_limits(terrain: TileMapLayer) -> void:
	if terrain == null or terrain.get_used_rect().size == Vector2i.ZERO:
		return
	var used := terrain.get_used_rect()
	var top_left := terrain.to_global(terrain.map_to_local(used.position))
	var bottom_right := terrain.to_global(terrain.map_to_local(used.position + used.size))
	limit_left = floori(top_left.x)
	limit_top = floori(top_left.y)
	limit_right = ceili(bottom_right.x)
	limit_bottom = ceili(bottom_right.y)

func set_vertical_limits(top_y: float, bottom_y: float) -> void:
	limit_top = floori(top_y)
	limit_bottom = ceili(bottom_y)


func shake(amplitude: float = 8.0, duration: float = 0.2) -> void:
	_shake_amplitude = maxf(_shake_amplitude, amplitude)
	_shake_time = maxf(_shake_time, duration)

func _process(delta: float) -> void:
	if not is_instance_valid(player_one) or not is_instance_valid(player_two):
		return
	var midpoint := (player_one.global_position + player_two.global_position) * 0.5
	global_position = global_position.lerp(midpoint, minf(10.0 * delta, 1.0))
	var distance := player_one.global_position.distance_to(player_two.global_position)
	var t := clampf(inverse_lerp(zoom_distance_near, zoom_distance_far, distance), 0.0, 1.0)
	var desired := lerpf(max_zoom, min_zoom, t)
	zoom = zoom.lerp(Vector2.ONE * desired, minf(8.0 * delta, 1.0))
	distance_warning_visible = distance > max_player_distance
	distance_warning_direction = (player_two.global_position - player_one.global_position).normalized()
	if distance_warning != null:
		distance_warning.visible = distance_warning_visible
		if distance_warning_visible:
			distance_warning.rotation = distance_warning_direction.angle()
	if _shake_time > 0.0:
		_shake_time -= delta
		shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amplitude
		_shake_amplitude = lerpf(_shake_amplitude, 0.0, minf(delta * 12.0, 1.0))
	else:
		shake_offset = Vector2.ZERO
	offset = shake_offset
