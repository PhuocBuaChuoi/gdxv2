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

const ASCII_SOLID := "#="
const ASCII_ONEWAY := "-"
const ASCII_DECO := "."

var level_time: float = 0.0
var deaths: int = 0
var running: bool = false

@export var ceiling_y: float = -48.0
@export var floor_kill_y: float = 720.0
@export var enforce_vertical_bounds: bool = true

@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var player_one: GdxPlayer = $Players/PlayerP1
@onready var player_two: GdxPlayer = $Players/PlayerP2
@onready var respawn_coordinator: RespawnCoordinator = $RespawnCoordinator
@onready var coop_camera: CoopCamera = $CoopCamera
@onready var attempt_label: Label = $LevelHUD/AttemptLabel
@onready var terrain_layer: TileMapLayer = $TerrainLayer


var _screenshot_frames: int = 0
var _screenshot_path: String = ""


func _ready() -> void:
	_check_cli_screenshot()
	running = true
	paint_terrain()
	_setup_bounds()
	_position_players()
	player_one.switch_form(start_form_p1)
	player_two.switch_form(start_form_p2)
	respawn_coordinator.register_players(player_one, player_two)
	respawn_coordinator.level_reset_to_checkpoint.connect(_on_level_reset_to_checkpoint)
	respawn_coordinator.attempt_changed.connect(_on_attempt_changed)
	coop_camera.set_players(player_one, player_two)
	coop_camera.set_terrain_limits(terrain_layer)
	if enforce_vertical_bounds and coop_camera.has_method("set_vertical_limits"):
		coop_camera.set_vertical_limits(ceiling_y, floor_kill_y)
	_on_attempt_changed(respawn_coordinator.attempt_count)
	_apply_background()


func _check_cli_screenshot() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--screenshot" and i + 1 < args.size():
			_screenshot_path = args[i + 1]
			break


func _setup_bounds() -> void:
	if terrain_layer != null and terrain_layer.get_used_rect().size != Vector2i.ZERO:
		var used := terrain_layer.get_used_rect()
		var top_left := terrain_layer.to_global(terrain_layer.map_to_local(used.position))
		var bottom_right := terrain_layer.to_global(terrain_layer.map_to_local(used.position + used.size))
		ceiling_y = minf(ceiling_y, top_left.y - 48.0)
		floor_kill_y = maxf(floor_kill_y, bottom_right.y + 120.0)
	if enforce_vertical_bounds:
		if player_one != null and player_one.has_method("set_bounds"):
			player_one.set_bounds(ceiling_y, floor_kill_y)
		if player_two != null and player_two.has_method("set_bounds"):
			player_two.set_bounds(ceiling_y, floor_kill_y)



func _position_players() -> void:
	player_one.global_position = spawn_p1.global_position
	player_two.global_position = spawn_p2.global_position


func _process(delta: float) -> void:
	if running:
		level_time += delta
	if Input.is_action_just_pressed("game_restart_checkpoint"):
		respawn_coordinator.request_respawn(1)
	if _screenshot_path != "":
		_screenshot_frames += 1
		if _screenshot_frames >= 6:
			var vp := get_viewport()
			if vp != null:
				var img := vp.get_texture().get_image()
				if img != null:
					var abs_path := ProjectSettings.globalize_path(_screenshot_path)
					var dir := abs_path.get_base_dir()
					if not DirAccess.dir_exists_absolute(dir):
						DirAccess.make_dir_recursive_absolute(dir)
					var err := img.save_png(abs_path)
					print("[Screenshot] Captured to: %s (err=%d)" % [abs_path, err])
			get_tree().quit(0)

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
	layer.clear()
	for y in range(ascii_map.size()):
		var row: String = ascii_map[y]
		for x in range(row.length()):
			var ch: String = row.substr(x, 1)
			if ASCII_SOLID.contains(ch):
				layer.set_cell(Vector2i(x, y), 0, solid_variant_at(x, y))
			elif ch == ASCII_ONEWAY:
				layer.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
			elif ch == ASCII_DECO:
				layer.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))


## Chon bien the solid theo hang xom: bit N=1, E=2, S=4, W=8 la huong lo ra
## ngoai (khong co hang xom solid). Nho do vien neon chay lien mach, khong luoi.
func solid_variant_at(x: int, y: int) -> Vector2i:
	var mask := 0
	if not _is_solid_at(x, y - 1):
		mask |= 1
	if not _is_solid_at(x + 1, y):
		mask |= 2
	if not _is_solid_at(x, y + 1):
		mask |= 4
	if not _is_solid_at(x - 1, y):
		mask |= 8
	if mask == 0:
		return Vector2i(0, 0)
	return Vector2i(mask % 4, 1 + (mask >> 2))


func _is_solid_at(x: int, y: int) -> bool:
	if y < 0 or y >= ascii_map.size():
		return false
	var row: String = ascii_map[y]
	if x < 0 or x >= row.length():
		return false
	return ASCII_SOLID.contains(row.substr(x, 1))


func get_player_positions() -> Dictionary:
	return {"p1": player_one.global_position if player_one != null else Vector2.ZERO,
		"p2": player_two.global_position if player_two != null else Vector2.ZERO}


## Đổi nền theo màn (mặc định FOREST = hành vi cũ, không ảnh hưởng màn hiện tại).
func _apply_background() -> void:
	var bg: Node = get_node_or_null("StageBackground")
	if bg != null and bg.has_method("apply_background"):
		bg.set("background", background)
		bg.call("apply_background")
