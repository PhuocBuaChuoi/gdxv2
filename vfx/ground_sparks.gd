extends GPUParticles2D

## T2.06 — Tia lửa trượt dưới chân khi Cube chạy trên đất.
## Giai đoạn 3 sẽ instance node này vào player và gọi set_active(is_on_floor).

const Shapes = preload("res://scripts/procedural_shapes.gd")


func _ready() -> void:
	if texture == null:
		texture = Shapes.square_texture(6)


func set_active(on: bool) -> void:
	emitting = on
