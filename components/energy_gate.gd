class_name EnergyGate
extends StaticBody2D

## Cửa năng lượng cao kín cả làn chơi (mặc định 2x3 ô = 96x144 px).
##
## Trước đây các "cửa" trong màn dùng MechanizedPlatform 96x24: player cao 44px
## chỉ cần nhảy 36px là vượt qua, nên mọi puzzle nút bấm đều bị skip. Cửa này
## không thể nhảy qua (cao 144px > tầm nhảy 120px), mở bằng cách "tan biến" khi
## linked_triggers bật — không cần khoang chứa để trượt vào.

signal opened
signal closed

@export var gate_size: Vector2i = Vector2i(2, 3):
	set(value):
		gate_size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_rebuild()
## Cùng API với MechanizedPlatform để level/test dùng chung.
@export var linked_triggers: Array[NodePath] = []
@export var require_all: bool = true
@export var open_time: float = 0.18

var is_open: bool = false

var _collision: CollisionShape2D
var _panel: Polygon2D
var _border: Line2D
var _scan_lines: Array[Line2D] = []
var _time: float = 0.0
var _tween: Tween


func _ready() -> void:
	add_to_group("checkpoint_resettable")
	add_to_group("energy_gate")
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_panel = get_node_or_null("Panel") as Polygon2D
	_border = get_node_or_null("Border") as Line2D
	_rebuild()
	_apply_open(_triggers_active(), true)


func gate_pixel_size() -> Vector2:
	return Vector2(float(gate_size.x) * 48.0, float(gate_size.y) * 48.0)


func _rebuild() -> void:
	var size := gate_pixel_size()
	var half := size * 0.5
	if _collision != null:
		if _collision.shape is RectangleShape2D:
			if not _collision.shape.resource_local_to_scene:
				_collision.shape = _collision.shape.duplicate()
			(_collision.shape as RectangleShape2D).size = size
	if _panel != null:
		_panel.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y),
		])
	if _border != null:
		_border.points = PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y),
			Vector2(-half.x, -half.y),
		])
	for line in _scan_lines:
		if is_instance_valid(line):
			line.queue_free()
	_scan_lines.clear()
	var holder := get_node_or_null("ScanLines")
	if holder == null:
		return
	for i in range(gate_size.y * 2):
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.25, 0.95, 1.0, 0.30)
		var y := -half.y + (float(i) + 0.5) * (size.y / float(gate_size.y * 2))
		line.points = PackedVector2Array([Vector2(-half.x + 6.0, y), Vector2(half.x - 6.0, y)])
		holder.add_child(line)
		_scan_lines.append(line)


func _physics_process(delta: float) -> void:
	_time += delta
	var active := _triggers_active()
	if active != is_open:
		_apply_open(active)
	if _border != null:
		var pulse: float = 0.55 + 0.45 * sin(_time * 4.0)
		_border.default_color = Color(0.25, 0.95, 1.0, pulse if not is_open else 0.15)
	for i in range(_scan_lines.size()):
		var line := _scan_lines[i]
		if not is_instance_valid(line):
			continue
		var base_alpha: float = 0.12 if is_open else 0.30
		line.default_color.a = base_alpha * (0.6 + 0.4 * sin(_time * 3.0 + float(i)))


func _apply_open(value: bool, instant: bool = false) -> void:
	is_open = value
	if _collision != null:
		_collision.set_deferred("disabled", value)
	if _panel != null:
		_panel.visible = not value
	for line in _scan_lines:
		if is_instance_valid(line):
			line.visible = not value
	if _border != null:
		_border.visible = true
		_border.default_color.a = 0.15 if value else 0.9
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if instant:
		modulate.a = 0.25 if value else 1.0
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.25 if value else 1.0, open_time)
	AudioManager.play_sfx("door")
	if value:
		opened.emit()
	else:
		closed.emit()


## Respawn/checkpoint: cửa phải đóng lại như lúc lưu checkpoint.
func reset_to_checkpoint(_snapshot: CheckpointSnapshot = null) -> void:
	_apply_open(false, true)


func _triggers_active() -> bool:
	if linked_triggers.is_empty():
		return false
	var count := 0
	for p in linked_triggers:
		var n := get_node_or_null(p)
		if n != null and bool(n.get("is_on")):
			count += 1
	return count == linked_triggers.size() if require_all else count > 0
