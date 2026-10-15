extends Node2D

## T2.04 — Hiệu ứng nổ kiểu GD: 30 mảnh vuông văng + vòng xung kích.
## Gọi DeathExplosion.play(mau) tại vị trí chết; tự giải phóng sau 0.4s.

const Shapes = preload("res://scripts/procedural_shapes.gd")

@onready var burst: GPUParticles2D = $BurstParticles
@onready var shockwave: Line2D = $Shockwave


func _ready() -> void:
	play(Color.WHITE)


func play(color: Color = Color.WHITE) -> void:
	burst.texture = Shapes.square_texture(8)
	burst.modulate = color
	shockwave.points = Shapes.circle_points(10.0, 24)
	shockwave.default_color = color
	burst.restart()
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(shockwave, "scale", Vector2.ONE * 7.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(shockwave, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(queue_free)
