extends "res://tests/gdx_test.gd"

## Vai trò BỔ TRỢ Phase 3 (T3.01–T3.06) — agent khác đang làm characters/.
## File này KHÔNG đụng characters/, chỉ đọc để kiểm tra.
##
## 2 lớp check:
##  A. Contract xanh NGAY (layer bits, input runtime) — bảo vệ giả định T3.
##  B. Structural — tự SKIP khi player.tscn chưa land, tự bật khi T3 xong.

const PLAYER_SCENE := "res://characters/player.tscn"


func _player_available() -> bool:
	return FileAccess.file_exists(PLAYER_SCENE)


func test_t3_presence_note() -> void:
	if _player_available():
		assert_true(true, "T3 player.tscn da land — structural checks dang chay")
	else:
		print("SKIP structural: player.tscn chua co — chi chay contract")
		assert_true(true, "contract-only mode (T3 dang lam, khong fail gate)")


func test_t3_layer_contract() -> void:
	# T3.04 phụ thuộc mapping này — đổi tên/đánh số lại là vỡ player.
	var want: Dictionary = {1: "World_Terrain", 2: "Player_1", 3: "Player_2", 4: "Hazard_Neutral", 5: "Hazard_P1_Safe", 6: "Hazard_P2_Safe", 7: "Interactables", 8: "Pushable_Blocks"}
	for n in want.keys():
		assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % n), want[n], "T3 contract layer %d" % n)
	assert_eq((1 << 3) | (1 << 5), 40, "T3.04 mask P1 = Neutral(4)+P2Safe(6) = 40")
	assert_eq((1 << 3) | (1 << 4), 24, "T3.04 mask P2 = Neutral(4)+P1Safe(5) = 24")


func test_t3_input_runtime() -> void:
	# Mô phỏng phím thật headless — đúng actions mà T3.03 sẽ đọc.
	Input.action_release("p1_left")
	Input.action_release("p1_right")
	Input.action_release("p1_jump")
	Input.action_press("p1_left")
	assert_true(Input.is_action_pressed("p1_left"), "press p1_left an")
	assert_near(Input.get_axis("p1_left", "p1_right"), -1.0, 0.001, "axis P1 trai = -1")
	Input.action_press("p1_right")
	assert_near(Input.get_axis("p1_left", "p1_right"), 0.0, 0.001, "an 2 phim axis = 0")
	Input.action_release("p1_left")
	Input.action_release("p1_right")
	Input.action_press("p1_jump")
	assert_true(Input.is_action_pressed("p1_jump"), "giu W nhan nhay")
	Input.action_release("p1_jump")
	Input.action_press("p2_jump")
	assert_true(Input.is_action_pressed("p2_jump"), "Up Arrow nhan nhay P2")
	Input.action_release("p2_jump")
	Input.action_press("game_restart_checkpoint")
	assert_true(Input.is_action_pressed("game_restart_checkpoint"), "R reset duoc")
	Input.action_release("game_restart_checkpoint")


func _spawn(pid: int) -> CharacterBody2D:
	var inst: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	inst.set("player_id", pid)
	host_root.add_child(inst)
	return inst as CharacterBody2D


func _despawn(p: Node) -> void:
	host_root.remove_child(p)
	p.free()


func _has_prop(p: Object, prop_name: String) -> bool:
	for pi in p.get_property_list():
		if str(pi["name"]) == prop_name:
			return true
	return false


func test_t3_scene_structure() -> void:
	if not _player_available():
		return
	var p: CharacterBody2D = _spawn(1)
	assert_true(p is CharacterBody2D, "T3.01 goc CharacterBody2D")
	var body: CollisionShape2D = p.get_node_or_null("BodyCollision") as CollisionShape2D
	assert_true(body != null and body.shape is RectangleShape2D, "T3.02 BodyCollision Rectangle")
	if body != null and body.shape is RectangleShape2D:
		var rect: RectangleShape2D = body.shape as RectangleShape2D
		assert_near(rect.size.x, 44.0, 2.0, "T3.02 hitbox rong ~44 (48 tru 2px moi ben)")
		assert_near(rect.size.y, 44.0, 2.0, "T3.02 hitbox cao ~44")
	assert_true(p.get_node_or_null("HazardDetector") is Area2D, "T3.02 HazardDetector Area2D")
	assert_true(p.get_node_or_null("HeadPlatform") != null, "T3.02 HeadPlatform")
	var vis: Node = p.get_node_or_null("VisualRoot")
	assert_true(vis != null, "T3.02 VisualRoot tach khoi collision")
	if vis != null:
		for n in ["CubeVisual", "ShipVisual", "UfoVisual", "DashVisual"]:
			assert_true(vis.get_node_or_null(n) != null, "T3.02 co nhanh " + n)
	assert_true(p.get_node_or_null("StateMachine") != null, "T3.02 StateMachine quan ly dang")
	_despawn(p)


func test_t3_collision_config() -> void:
	if not _player_available():
		return
	var p1: CharacterBody2D = _spawn(1)
	var p2: CharacterBody2D = _spawn(2)
	assert_eq(p1.collision_layer, 2, "T3.04 P1 o layer 2")
	assert_eq(p2.collision_layer, 4, "T3.04 P2 o layer 3 (bit value 4)")
	var h1: Area2D = p1.get_node_or_null("HazardDetector") as Area2D
	var h2: Area2D = p2.get_node_or_null("HazardDetector") as Area2D
	assert_true(h1 != null and h2 != null, "T3.04 ca 2 P co HazardDetector")
	if h1 != null:
		assert_eq(h1.collision_mask, 40, "T3.04 P1 bat Neutral+P2Safe, bo qua P1Safe")
	if h2 != null:
		assert_eq(h2.collision_mask, 24, "T3.04 P2 bat Neutral+P1Safe, bo qua P2Safe")
	_despawn(p1)
	_despawn(p2)


func test_t3_input_api() -> void:
	if not _player_available():
		return
	var p: CharacterBody2D = _spawn(1)
	for m in ["get_move_axis", "is_jump_pressed", "is_jump_just_pressed", "is_action_pressed"]:
		assert_true(p.has_method(m), "T3.03 player co " + m + "()")
	Input.action_release("p1_left")
	Input.action_release("p1_right")
	Input.action_press("p1_right")
	assert_near(float(p.call("get_move_axis")), 1.0, 0.001, "T3.03 P1 axis phai = +1")
	Input.action_release("p1_right")
	Input.action_press("p1_jump")
	assert_true(bool(p.call("is_jump_pressed")), "T3.03 P1 giu W = nhay")
	Input.action_release("p1_jump")
	Input.action_press("p1_action")
	assert_true(bool(p.call("is_action_pressed")), "T3.03 P1 phim S = action")
	Input.action_release("p1_action")
	_despawn(p)


func test_t3_gravity_defaults() -> void:
	if not _player_available():
		return
	var p: CharacterBody2D = _spawn(1)
	if not _has_prop(p, "gravity_direction"):
		print("SKIP gravity_direction chua co (T3.06 dang lam)")
		_despawn(p)
		return
	assert_eq(int(p.get("gravity_direction")), 1, "T3.06 mac dinh trong luc xuong")
	assert_eq(p.up_direction, Vector2(0, -1), "T3.06 up_direction mac dinh")
	_despawn(p)
