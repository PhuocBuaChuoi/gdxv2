class_name FloatingBox
extends RigidBody2D

## Bonus — khối năng lượng có thể được giữ lơ lửng bởi BalancedFloatPair.
@export var pairable: bool = true

func set_floating(enabled: bool) -> void:
	gravity_scale = 0.0 if enabled else 1.0
