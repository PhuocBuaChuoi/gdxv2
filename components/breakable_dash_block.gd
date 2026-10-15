class_name BreakableDashBlock
extends StaticBody2D

## T6.08 — Khối Tường Nứt: bình thường là tường cứng chặn cả 2 người chơi.
## Người chơi ở Dạng Dash đang lướt (`is_dashing`) tông vào → vỡ tung + mở đường.

signal shattered()

@onready var _detector: Area2D = $DashDetector


func _ready() -> void:
	_detector.body_entered.connect(_on_body_entered)


func is_dashing_body(body: Node2D) -> bool:
	var form_v: Variant = body.get("form")
	if str(form_v) != "DASH":
		return false
	var st: Variant = body.get("current_state")
	if st == null or not (st is Object):
		return false
	return bool((st as Object).get("is_dashing"))


func _on_body_entered(body: Node2D) -> void:
	if not is_dashing_body(body):
		return
	_shatter()


func _shatter() -> void:
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
