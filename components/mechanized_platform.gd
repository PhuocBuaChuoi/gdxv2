class_name MechanizedPlatform
extends AnimatableBody2D

## T6.07 — Bệ đỡ di động: AnimatableBody2D trượt mượt tới `move_offset`
## khi bất kỳ (hoặc toàn bộ, `require_all`) linked_triggers đang bật.
## Kéo thả nối dây ngay trên Inspector — không code riêng cho từng màn.

const PLAT_SHEET := preload("res://assets/sprites/mechanized_platform_anim.png")

@export var linked_triggers: Array[NodePath] = []
@export var move_offset: Vector2 = Vector2(0, -96)
@export var speed: float = 140.0
@export var require_all: bool = false

var _home: Vector2
var _last_active: bool = false
var _anim_time: float = 0.0


func _ready() -> void:
	_home = global_position
	_last_active = _triggers_active()
	add_to_group("checkpoint_resettable")
	SpriteAnim.setup_sheet(get_node_or_null("PlatformSprite") as Sprite2D, PLAT_SHEET, 4)


func _process(delta: float) -> void:
	_anim_time += delta * (2.2 if _last_active else 1.0)
	var spr := get_node_or_null("PlatformSprite") as Sprite2D
	if spr != null:
		SpriteAnim.step_sheet(spr, _anim_time, 5.0, 4)
		spr.modulate = Color(1.05, 1.15, 1.2, 1.0) if _last_active else Color(0.9, 0.95, 1.0, 1.0)


## T5.04.5 — respawn đưa bệ về vị trí ban đầu ngay cả khi trigger còn bật.
func reset_to_checkpoint(_snapshot: CheckpointSnapshot = null) -> void:
	global_position = _home


func _physics_process(delta: float) -> void:
	if speed <= 0.0:
		return
	var active := _triggers_active()
	if active != _last_active:
		_last_active = active
		AudioManager.play_sfx("door") # T8.06: tiếng cửa/bệ mở
	var target := _home + move_offset if active else _home
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
