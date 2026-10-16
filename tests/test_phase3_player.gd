extends "res://tests/gdx_test.gd"

## Phase 3 — kiểm theo implementation thực tế của characters/ (agent T3)
## + contract độc lập (layers/input runtime). Merge từ bản support và bản T3.
## T3.02 nodes and hazard separation are enforced by the structural/runtime tests.

const PLAYER_SCENE := "res://characters/player.tscn"


# ---------- Contract độc lập: xanh ngay cả khi player đổi implementation ----------

func test_t3_layer_contract() -> void:
	# T3.04 phụ thuộc mapping này — đổi tên/đánh số lại là vỡ player.
	var want: Dictionary = {1: "World_Terrain", 2: "Player_1", 3: "Player_2", 4: "Hazard_Neutral", 5: "Hazard_P1_Safe", 6: "Hazard_P2_Safe", 7: "Interactables", 8: "Pushable_Blocks"}
	for n in want.keys():
		assert_eq(ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % n), want[n], "T3 contract layer %d" % n)
	assert_eq((1 << 3) | (1 << 5), 40, "T3.04 mask detector P1 = Neutral(4)+P2Safe(6)")
	assert_eq((1 << 3) | (1 << 4), 24, "T3.04 mask detector P2 = Neutral(4)+P1Safe(5)")


func test_t3_input_runtime() -> void:
	# Mô phỏng phím thật headless — đúng actions mà T3.03 đọc.
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


# ---------- Structural: theo scene/code T3 hiện tại ----------

func test_player_scene_structure() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	assert_true(packed != null, "T3.01 player scene load duoc")
	var player: CharacterBody2D = packed.instantiate() as CharacterBody2D
	assert_true(player != null, "T3.01 root CharacterBody2D")
	assert_true(player.get_node_or_null("BodyCollision") is CollisionShape2D, "T3.02 BodyCollision")
	var body: CollisionShape2D = player.get_node_or_null("BodyCollision") as CollisionShape2D
	if body != null and body.shape is RectangleShape2D:
		assert_near((body.shape as RectangleShape2D).size.x, 44.0, 0.5, "T3.02 hitbox 44 (forgiving vs 48)")
	assert_true(player.get_node_or_null("VisualRoot") is Node2D, "T3.02 VisualRoot tach khoi collision")
	assert_true(player.get_node_or_null("VisualRoot/FillPolygon") is Polygon2D, "T3.02 FillPolygon")
	assert_true(player.get_node_or_null("VisualRoot/OutlineLine") is Line2D, "T3.02 OutlineLine vien neon")
	assert_true(player.get_node_or_null("MotionTrail") is Line2D, "T2.05 player tai su dung MotionTrail")
	assert_true(player.get_node_or_null("GroundSparks") is GPUParticles2D, "T2.06 player tai su dung GroundSparks")
	player.free()


func test_player_api_and_constants() -> void:
	var script: Script = load("res://characters/player.gd") as Script
	assert_true(script != null, "player.gd load duoc")
	var methods: Dictionary = {}
	for m in script.get_script_method_list():
		methods[str(m["name"])] = true
	for method_name in [&"get_move_axis", &"is_jump_pressed", &"is_jump_just_pressed", &"is_action_pressed", &"switch_form", &"set_gravity_direction"]:
		assert_true(methods.has(method_name), "player co ham %s" % method_name)
	assert_near(float(script.get_script_constant_map().get("COYOTE_TIME", -1.0)), 0.08, 0.0001, "T3.05 coyote 0.08")
	assert_near(float(script.get_script_constant_map().get("JUMP_BUFFER_TIME", -1.0)), 0.1, 0.0001, "T3.05 buffer 0.1")
	assert_near(float(script.get_script_constant_map().get("MOVE_SPEED", -1.0)), 420.0, 0.001, "T4.02 toc do 420")


func test_player_instances_configure_layers() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	var p1: CharacterBody2D = packed.instantiate() as CharacterBody2D
	p1.set("player_id", 1)
	host_root.add_child(p1)
	assert_eq(p1.collision_layer, 2, "T3.04 P1 o layer 2")
	assert_eq(p1.collision_mask, 129, "P1 body World_Terrain + Pushable_Blocks (T6.09)")
	assert_eq((p1.get_node("HazardDetector") as Area2D).collision_mask, 40, "P1 detector Neutral + P2Safe")
	Input.action_press("p1_right")
	assert_near(float(p1.call("get_move_axis")), 1.0, 0.001, "T3.03 P1 axis phai = +1")
	Input.action_release("p1_right")
	Input.action_press("p1_jump")
	assert_true(bool(p1.call("is_jump_pressed")), "T3.03 P1 giu W = nhay")
	Input.action_release("p1_jump")
	host_root.remove_child(p1)
	p1.free()
	var p2: CharacterBody2D = packed.instantiate() as CharacterBody2D
	p2.set("player_id", 2)
	host_root.add_child(p2)
	assert_eq(p2.collision_layer, 4, "T3.04 P2 o layer 3 (bit value 4)")
	assert_eq(p2.collision_mask, 129, "P2 body World_Terrain + Pushable_Blocks (T6.09)")
	assert_eq((p2.get_node("HazardDetector") as Area2D).collision_mask, 24, "P2 detector Neutral + P1Safe")
	Input.action_press("p2_jump")
	assert_true(bool(p2.call("is_jump_pressed")), "T3.03 P2 Up = nhay")
	Input.action_release("p2_jump")
	host_root.remove_child(p2)
	p2.free()


func test_coyote_jump_physics() -> void:
	var packed: PackedScene = load(PLAYER_SCENE) as PackedScene
	var player: GdxPlayer = packed.instantiate() as GdxPlayer
	host_root.add_child(player)
	player._coyote_timer = 0.04
	Input.action_press("p1_jump")
	player._physics_process(1.0 / 120.0)
	Input.action_release("p1_jump")
	assert_true(player.velocity.y < 0.0, "coyote jump applies upward velocity")
	host_root.remove_child(player)
	player.free()


func test_neon_visual_faces_move_direction() -> void:
	var p: CharacterBody2D = (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	p.set("player_id", 1)
	host_root.add_child(p)
	p.set("last_facing_dir", -1)
	p.call("_update_skin_animation")
	assert_true((p.get_node("VisualRoot") as Node2D).scale.x < 0.0, "neon lat trai khi di trai")
	p.set("last_facing_dir", 1)
	p.call("_update_skin_animation")
	assert_true((p.get_node("VisualRoot") as Node2D).scale.x > 0.0, "neon ve phai khi di phai")
	host_root.remove_child(p)
	p.free()


func test_cube_jump_needs_floor_or_coyote() -> void:
	# Hoi quy double-jump: buffer set trong cung frame KHONG duoc kich nhay
	# khi dang bay (truoc day moi phat nhan tren khong deu nhay).
	var p: CharacterBody2D = (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	p.set("player_id", 1)
	host_root.add_child(p)
	p.set("_coyote_timer", 0.0)
	p.velocity = Vector2.ZERO
	Input.action_press("p1_jump")
	p._physics_process(1.0 / 120.0)
	Input.action_release("p1_jump")
	assert_true(p.velocity.y > -100.0, "tren khong + het coyote: KHONG nhay (y=%s)" % str(p.velocity.y))
	p.set("_coyote_timer", 0.05)
	p.velocity = Vector2.ZERO
	Input.action_press("p1_jump")
	p._physics_process(1.0 / 120.0)
	Input.action_release("p1_jump")
	assert_true(p.velocity.y < -500.0, "coyote: nhay binh thuong (y=%s)" % str(p.velocity.y))
	host_root.remove_child(p)
	p.free()
