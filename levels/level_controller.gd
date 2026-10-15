extends Node2D

## T7.03 — LevelRoot: timer, deaths, spawn, form khởi đầu, chọn nền theo màn.
## Hợp nhất: logic spawn/players/camera (agent T4/T5) + background (agent levels).
## Quy ước: màn vẽ tay KHÔNG xóa các node Players/RespawnCoordinator/CoopCamera
## vì _ready phụ thuộc chúng (xem levels/AUTHORING.md).

@export var level_index: int = 0
@export var start_form_p1: StringName = &"CUBE"
@export var start_form_p2: StringName = &"CUBE"
@export_enum("FOREST", "BRIGHT") var background: String = "FOREST"

## Terrain vẽ bằng text ('#' đặc, '=' viền, '-' 1 chiều, '.' trang trí).
## Review diff dễ, không cần mở editor. Xem levels/AUTHORING.md.
@export var ascii_map: PackedStringArray = []

const ASCII_TILES := {"#": Vector2i(0, 0), "=": Vector2i(1, 0), "-": Vector2i(2, 0), ".": Vector2i(3, 0)}

var level_time: float = 0.0
var deaths: int = 0
var running: bool = false

@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var player_one: GdxPlayer = $Players/PlayerP1
@onready var player_two: GdxPlayer = $Players/PlayerP2
@onready var respawn_coordinator: RespawnCoordinator = $RespawnCoordinator
@onready var coop_camera: CoopCamera = $CoopCamera
@onready var attempt_label: Label = $LevelHUD/AttemptLabel
@onready var terrain_layer: TileMapLayer = $TerrainLayer


func _ready() -> void:
	running = true
	paint_terrain()
	_position_players()
	player_one.switch_form(start_form_p1)
	player_two.switch_form(start_form_p2)
	respawn_coordinator.register_players(player_one, player_two)
	respawn_coordinator.level_reset_to_checkpoint.connect(_on_level_reset_to_checkpoint)
	respawn_coordinator.attempt_changed.connect(_on_attempt_changed)
	coop_camera.set_players(player_one, player_two)
	coop_camera.set_terrain_limits(terrain_layer)
	_on_attempt_changed(respawn_coordinator.attempt_count)
	_apply_background()


func _position_players() -> void:
	player_one.global_position = spawn_p1.global_position
	player_two.global_position = spawn_p2.global_position


func _process(delta: float) -> void:
	if running:
		level_time += delta
	if Input.is_action_just_pressed("game_restart_checkpoint"):
		respawn_coordinator.request_respawn(1)

func _on_attempt_changed(value: int) -> void:
	if attempt_label != null:
		attempt_label.text = "Attempt #%d" % value

func _on_level_reset_to_checkpoint(snapshot: CheckpointSnapshot) -> void:
	for node in get_tree().get_nodes_in_group("checkpoint_resettable"):
		if node.has_method("reset_to_checkpoint"):
			node.reset_to_checkpoint(snapshot)


func add_death() -> void:
	deaths += 1


func reset_stats() -> void:
	level_time = 0.0
	deaths = 0


## Vị trí spawn theo id (tọa độ world).
func get_spawn(player_id: int) -> Vector2:
	if player_id == 2:
		return spawn_p2.global_position
	return spawn_p1.global_position


## Vẽ ascii_map lên TerrainLayer (gọi trong _ready, gọi lại được khi cần).
func paint_terrain() -> void:
	if ascii_map.is_empty():
		return
	var layer := get_node_or_null("TerrainLayer") as TileMapLayer
	if layer == null:
		return
	for y in range(ascii_map.size()):
		var row: String = ascii_map[y]
		for x in range(row.length()):
			var atlas: Vector2i = ASCII_TILES.get(row.substr(x, 1), Vector2i(-1, -1))
			if atlas.x >= 0:
				layer.set_cell(Vector2i(x, y), 0, atlas)


func get_player_positions() -> Dictionary:
	return {"p1": player_one.global_position if player_one != null else Vector2.ZERO,
		"p2": player_two.global_position if player_two != null else Vector2.ZERO}


## Đổi nền theo màn (mặc định FOREST = hành vi cũ, không ảnh hưởng màn hiện tại).
func _apply_background() -> void:
	var bg: Node = get_node_or_null("StageBackground")
	if bg != null and bg.has_method("apply_background"):
		bg.set("background", background)
		bg.call("apply_background")
