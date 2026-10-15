extends Node2D

## T7.03 — LevelRoot logic v1: bấm giờ, đếm deaths, spawn markers, form khởi đầu.
## Chưa cần player: T4/T5 sẽ nối thêm đặt player vào spawn, snapshot checkpoint,
## dual-gate. Mọi hàm đều an toàn khi gọi trực tiếp (kể cả ngoài cây scene).

@export var level_index: int = 0
@export var start_form_p1: StringName = &"CUBE"
@export var start_form_p2: StringName = &"CUBE"

var level_time: float = 0.0
var deaths: int = 0
var running: bool = false

@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var player_one: GdxPlayer = $Players/PlayerP1
@onready var player_two: GdxPlayer = $Players/PlayerP2
@onready var respawn_coordinator: RespawnCoordinator = $RespawnCoordinator
@onready var coop_camera: CoopCamera = $CoopCamera


func _ready() -> void:
	running = true
	player_one.global_position = spawn_p1.global_position
	player_two.global_position = spawn_p2.global_position
	player_one.switch_form(start_form_p1)
	player_two.switch_form(start_form_p2)
	respawn_coordinator.register_players(player_one, player_two)
	coop_camera.set_players(player_one, player_two)


func _process(delta: float) -> void:
	if running:
		level_time += delta


func add_death() -> void:
	deaths += 1


func reset_stats() -> void:
	level_time = 0.0
	deaths = 0


## Vị trí spawn theo id (dùng khi T4/T5 đặt player vào màn).
func get_spawn(player_id: int) -> Vector2:
	if player_id == 2:
		return spawn_p2.position
	return spawn_p1.position
