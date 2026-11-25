extends Node

## E2E driver — chạy qua MCP run_project (game thật, physics frame thật):
## teleport lần lượt qua mọi component của e2e_gallery, chờ frame thật để
## Area phát hiện tự nhiên, in E2E-PASS/FAIL, quit(0 = xanh / 1 = đỏ).

var failures: Array = []
var g: Node
var p1: Node
var p2: Node
var coord: Node
var gate: Node
var popup: Control


func _ready() -> void:
	_run()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame


func _go(p: Node, x: float, y: float, settle: int = 3) -> void:
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	await _frames(settle)


func _check(cond: bool, tag: String) -> void:
	if cond:
		print("E2E-PASS ", tag)
	else:
		failures.append(tag)
		printerr("E2E-FAIL ", tag)


func _run() -> void:
	await get_tree().process_frame
	g = load("res://levels/e2e_gallery.tscn").instantiate()
	get_tree().root.add_child(g)
	p1 = g.get_node("Players/PlayerP1")
	p2 = g.get_node("Players/PlayerP2")
	coord = g.get_node("RespawnCoordinator")
	gate = g.get_node("Mechanisms/DualExitGate")
	popup = g.get_node("LevelHUD/CompletePopup")
	await _frames(5)
	_check(p1.global_position.distance_to(Vector2(120, 448)) < 8.0, "spawn P1 dung marker")
	_check(p2.global_position.distance_to(Vector2(200, 448)) < 8.0, "spawn P2 dung marker")

	# 1. Form portal (roi ve CUBE de cac buoc sau on dinh)
	await _go(p1, 400, 432)
	_check(str(p1.get("form")) == "SHIP", "form_portal doi P1 -> SHIP")
	p1.call("switch_form", &"CUBE")

	# 2. Jump pad (gd=1 bung LEN; pad chi kich khi ha canh vao)
	await _go(p1, 1000, 452)
	_check(p1.velocity.y < -100.0, "jump_pad ha canh bung len (gd=1)")

	# 3. Gravity portal TOGGLE: 1 -> -1 -> (cho debounce) -> 1
	await _go(p1, 700, 432)
	_check(int(p1.get("gravity_direction")) == -1, "gravity_portal TOGGLE 1 -> -1")
	await get_tree().create_timer(0.6).timeout
	await _go(p1, 700, 432)
	_check(int(p1.get("gravity_direction")) == 1, "di lai portal TOGGLE ve 1")

	# 5. Jump orb YELLOW tren khong + nhan moi
	p1.global_position = Vector2(1300, 372)
	p1.velocity = Vector2.ZERO
	await _frames(12)
	Input.action_press("p1_jump")
	await get_tree().physics_frame
	Input.action_release("p1_jump")
	await _frames(2)
	_check(p1.velocity.y < -900.0, "jump_orb YELLOW + nhan moi -> -1100 (y=%s)" % str(p1.velocity.y))

	# 6. Button + platform di chuyen roi ve
	var plat := g.get_node("Mechanisms/BridgePlatform")
	var btn := g.get_node("Mechanisms/BridgeButton")
	var home_y: float = plat.global_position.y
	await _go(p1, 1600, 470)
	_check(bool(btn.get("is_on")), "pressure_button HOLD bat khi dung len")
	await _frames(120)
	_check(plat.global_position.y < home_y - 80.0, "mechanized_platform di len offset (y=%s)" % str(plat.global_position.y))
	await _go(p1, 120, 448)
	await _frames(120)
	_check(absf(plat.global_position.y - home_y) < 8.0, "platform ve home khi nha nut")

	# 6b. Cube-on-cube: P2 dung tren dau P1 (layer 9 HeadPlatforms)
	await _go(p1, 300, 448)
	await _go(p2, 300, 356)
	await _frames(90)
	var stack_dy: float = p1.global_position.y - p2.global_position.y
	_check(stack_dy > 20.0 and stack_dy < 70.0, "P2 dung tren dau P1 (dy=%s)" % str(stack_dy))

	# 7. Dash block: Dash dang luot tong vao -> vo
	p1.call("switch_form", &"DASH")
	var st: Variant = p1.get("current_state")
	st.call("activate_dash", 1)
	var block := g.get_node("Mechanisms/DashWall")
	p1.global_position = Vector2(1850, 408)
	p1.velocity = Vector2.ZERO
	await _frames(3)
	# Tuong vo khong con queue_free() (phai moc lai sau respawn): kiem tra da vo =
	# an + tat collision, khong phai node bi xoa.
	var block_col := block.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(not bool(block.get("visible")) and bool(block.get("_shattered")) and (block_col == null or block_col.disabled), "breakable_dash_block vo khi Dash luot vao")

	# 8. DashOrb hoi dash qua Area that
	st.set("is_dashing", false)
	st.call("activate_dash", 1)
	await _go(p1, 2020, 422)
	_check(bool(st.get("dash_ready")), "dash_orb hoi 1 luot Dash qua tiep xuc")

	# 8b. Ship tether nang CoopBox (T6.09: tau o tren, giu phim action)
	p1.call("switch_form", &"SHIP")
	var box := g.get_node("Mechanisms/CoopBox") as RigidBody2D
	var box_y0: float = box.global_position.y
	p1.global_position = Vector2(2130, 415)
	p1.velocity = Vector2.ZERO
	await _frames(5)
	Input.action_press("p1_action")
	await _frames(90)
	Input.action_release("p1_action")
	_check(box.global_position.y < box_y0 - 20.0, "ship tether nang khoi len (y=%s)" % str(box.global_position.y))

	# 9. Checkpoint kich hoat
	var cp := g.get_node("Checkpoints/CheckpointMid")
	await _go(p1, 1450, 452)
	_check(bool(cp.get("is_active")), "restore_point kich hoat khi cham")

	# 10. Gai NEUTRAL giet P2 -> ca 2 hoi sinh o snapshot
	await _go(p2, 2580, 474)
	await _frames(100)
	_check(int(coord.get("attempt_count")) >= 1, "chet tang attempt")
	var snap: Variant = coord.get("checkpoint")
	_check(snap != null, "co snapshot checkpoint")
	if snap != null:
		# Hoi sinh dung snapshot roi roi tu do xuong san -> dung sai rong
		_check(absf(p1.global_position.x - snap.spawn_pos_p1.x) < 4.0 and p1.global_position.y >= snap.spawn_pos_p1.y - 2.0 and p1.global_position.y <= snap.spawn_pos_p1.y + 40.0, "P1 hoi sinh dung snapshot (p=%s)" % str(p1.global_position))
		_check(absf(p2.global_position.x - snap.spawn_pos_p2.x) < 4.0 and p2.global_position.y >= snap.spawn_pos_p2.y - 2.0 and p2.global_position.y <= snap.spawn_pos_p2.y + 40.0, "P2 hoi sinh dung snapshot (p=%s)" % str(p2.global_position))

	# 11. Cong dich doi -> popup + luu tien do (chuan hoa dang/gravity truoc)
	p1.call("switch_form", &"CUBE")
	p2.call("switch_form", &"CUBE")
	p1.call("set_gravity_direction", 1)
	p2.call("set_gravity_direction", 1)
	p1.global_position = Vector2(2950, 425)
	p1.velocity = Vector2.ZERO
	p2.global_position = Vector2(2950, 425)
	p2.velocity = Vector2.ZERO
	await _frames(100)
	_check(popup.visible, "dual_exit_gate mo popup hoan thanh")
	var lm: Node = get_node("/root/LevelManager")
	_check((lm.get("best") as Dictionary).has("98"), "LevelManager luu ky luc man 98")
	_check(bool(p1.get("control_locked")) and bool(p2.get("control_locked")), "khoa input sau thang")
	_check(FileAccess.file_exists("user://save_data.cfg"), "save_data.cfg duoc ghi")

	print("E2E-DONE fail=", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
