class_name MechanizedPlatform
extends AnimatableBody2D

## T6.07 — Bệ đỡ di động: AnimatableBody2D trượt mượt tới `move_offset`
## khi bất kỳ (hoặc toàn bộ, `require_all`) linked_triggers đang bật.
## Kéo thả nối dây ngay trên Inspector — không code riêng cho từng màn.

@export var linked_triggers: Array[NodePath] = []
@export var move_offset: Vector2 = Vector2(0, -96)
@export var speed: float = 140.0
@export var require_all: bool = false

var _home: Vector2


func _ready() -> void:
	_home = global_position


func _physics_process(delta: float) -> void:
	if speed <= 0.0:
		return
	var target := _home + move_offset if _triggers_active() else _home
	global_position = global_position.move_toward(target, speed * delta)


func _triggers_active() -> bool:
	if linked_triggers.is_empty():
		return false
	var count := 0
	for p in linked_triggers:
		var n := get_node_or_null(p)
		if n != null and bool(n.get("is_on")):
			count += 1
	return count == linked_triggers.size() if require_all else count > 0
