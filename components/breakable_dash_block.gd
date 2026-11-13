class_name BreakableDashBlock
extends StaticBody2D

## T6.08 — Khối Tường Nứt: bình thường là tường cứng chặn cả 2 người chơi.
## Người chơi ở Dạng Dash đang lướt (`is_dashing`) tông vào → vỡ tung + mở đường.

signal shattered()

## Kich thuoc khoi theo don vi o luoi 48px (mac dinh 1x3 o = 48x144 px)
@export var block_size: Vector2i = Vector2i(1, 3):
	set(value):
		block_size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_rebuild_geometry()

@onready var _detector: Area2D = $DashDetector
var _shattered: bool = false


func _ready() -> void:
	_detector.body_entered.connect(_on_body_entered)
	_rebuild_geometry()


func snap_to_grid(grid_size: float = 48.0) -> void:
	position = (position / grid_size).round() * grid_size


func _rebuild_geometry() -> void:
	var total_w := float(block_size.x) * 48.0
	var total_h := float(block_size.y) * 48.0
	var half_w := total_w * 0.5
	var half_h := total_h * 0.5
	
	var col_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null and col_shape.shape is RectangleShape2D:
		if not col_shape.shape.resource_local_to_scene:
			col_shape.shape = col_shape.shape.duplicate()
		(col_shape.shape as RectangleShape2D).size = Vector2(total_w, total_h)
	
	var wall := get_node_or_null("Wall") as Polygon2D
	if wall != null:
		wall.polygon = PackedVector2Array([
			Vector2(-half_w, -half_h),
			Vector2(half_w, -half_h),
			Vector2(half_w, half_h),
			Vector2(-half_w, half_h)
		])
	
	var detector := get_node_or_null("DashDetector") as Area2D
	var det_shape := detector.get_node_or_null("CollisionShape2D") as CollisionShape2D if detector else null
	if det_shape != null and det_shape.shape is RectangleShape2D:
		if not det_shape.shape.resource_local_to_scene:
			det_shape.shape = det_shape.shape.duplicate()
		(det_shape.shape as RectangleShape2D).size = Vector2(total_w + 12.0, total_h + 12.0)


func is_dashing_body(body: Node2D) -> bool:
	var form_v: Variant = body.get("form")
	if str(form_v) != "DASH":
		return false
	var st: Variant = body.get("current_state")
	if st == null or not (st is Object):
		return false
	return bool((st as Object).get("is_dashing"))


func _on_body_entered(body: Node2D) -> void:
	if _shattered or not is_dashing_body(body):
		return
	_shatter()


func _shatter() -> void:
	if _shattered:
		return
	_shattered = true
	shattered.emit()
	_spawn_sparks()
	AudioManager.play_sfx("death")
	queue_free()


func _spawn_sparks() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var p := GPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.45
	parent.add_child(p)
	p.global_position = global_position
	var timer := (parent.get_tree() as SceneTree).create_timer(1.5)
	timer.timeout.connect(p.queue_free)
