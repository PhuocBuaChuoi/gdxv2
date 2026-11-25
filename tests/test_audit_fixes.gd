extends "res://tests/gdx_test.gd"

## Regression suite cho các lỗi P0/P1 phát hiện trong audit codebase.
## Mỗi test khóa MỘT hành vi cụ thể đã được sửa (không chỉ cấu trúc node).

const PlayerScene := preload("res://characters/player.tscn")
const LevelScene := preload("res://levels/base_level.tscn")
const GravityPortalScene := preload("res://components/gravity_portal.tscn")
const PressureButtonScene := preload("res://components/pressure_button.tscn")
const PlatformScene := preload("res://components/mechanized_platform.tscn")
const BreakableScene := preload("res://components/breakable_dash_block.tscn")


func _cleanup(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()


func _player() -> GdxPlayer:
	var p := PlayerScene.instantiate() as GdxPlayer
	host_root.add_child(p)
	return p


func test_gravity_portal_uses_real_direction_values() -> void:
	var p := _player()
	var portal := GravityPortalScene.instantiate() as GravityPortal
	host_root.add_child(portal)
	portal.target_direction = -1
	portal.apply_to(p)
	assert_eq(p.gravity_direction, -1, "AUDIT01 Inverted (-1) dao trong luc that")
	portal.target_direction = 1
	portal.apply_to(p)
	assert_eq(p.gravity_direction, 1, "AUDIT01 Normal (+1) tra trong luc ve duong")
	portal.direction_mode = 1 # TOGGLE
	portal.apply_to(p)
	assert_eq(p.gravity_direction, -1, "AUDIT01 TOGGLE dao chieu hien tai")
	portal.reset_body(p)
	portal.reset_body(p) # phai khong crash va xoa ca debounce
	_cleanup([portal, p])


func test_deaths_increments_on_real_respawn() -> void:
	var lvl := LevelScene.instantiate()
	host_root.add_child(lvl)
	var coordinator: RespawnCoordinator = lvl.get_node("RespawnCoordinator") as RespawnCoordinator
	assert_eq(int(lvl.get("deaths")), 0, "AUDIT02 deaths bat dau bang 0")
	assert_true(coordinator.request_respawn(1), "AUDIT02 respawn duoc yeu cau")
	assert_eq(int(lvl.get("deaths")), 1, "AUDIT02 chet that tang deaths (khong chi goi add_death)")
	_cleanup([lvl])


func test_checkpoint_reset_restores_mechanisms() -> void:
	var btn := PressureButtonScene.instantiate() as PressureButton
	var plat := PlatformScene.instantiate() as MechanizedPlatform
	var wall := BreakableScene.instantiate() as BreakableDashBlock
	host_root.add_child(btn)
	host_root.add_child(plat)
	host_root.add_child(wall)
	assert_true(btn.is_in_group("checkpoint_resettable"), "AUDIT03 button dang ky reset group")
	assert_true(plat.is_in_group("checkpoint_resettable"), "AUDIT03 platform dang ky reset group")
	assert_true(wall.is_in_group("checkpoint_resettable"), "AUDIT03 tuong dang ky reset group")

	btn.set("_latched", true)
	btn.call("_set_on", true)
	btn.reset_to_checkpoint()
	assert_true(not btn.is_on and not btn.is_latched(), "AUDIT03 reset button xoa latch")

	plat.global_position = plat._home + Vector2(0, -96)
	plat.reset_to_checkpoint()
	assert_eq(plat.global_position, plat._home, "AUDIT03 reset platform ve vi tri ban dau")

	var p := _player()
	p.switch_form(&"DASH")
	(p.current_state as DashState).activate_dash(1)
	wall.call("_on_body_entered", p)
	assert_true(not wall.visible, "AUDIT03 setup: tuong da vo")
	wall.reset_to_checkpoint()
	assert_true(wall.visible, "AUDIT03 reset tuong phat hien lai")
	var col := wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_true(col != null and not col.disabled, "AUDIT03 reset tuong bat lai va cham")
	_cleanup([wall, plat, btn, p])


func test_dash_charge_does_not_reset_on_form_switch() -> void:
	var p := _player()
	p.switch_form(&"DASH")
	var dash := p.current_state as DashState
	assert_true(dash.dash_ready, "AUDIT04 dash san sang luc vao form")
	dash.activate_dash(1)
	assert_true(not p.dash_charge_available, "AUDIT04 dash tieu thu luot o player")
	p.switch_form(&"CUBE")
	p.switch_form(&"DASH")
	assert_true(not (p.current_state as DashState).dash_ready, "AUDIT04 doi form khong cho dash free")
	(p.current_state as DashState).recharge_dash()
	assert_true(p.dash_charge_available, "AUDIT04 recharge luu lai o player")
	_cleanup([p])


func test_visual_and_vfx_follow_spec() -> void:
	var p := _player()
	assert_eq(CubeState.ROTATION_SPEED, 420.0, "AUDIT05 toc do xoay Cube dung 420 do/giay")
	var platform := p.get_node("HeadPlatform") as AnimatableBody2D
	assert_true(platform.sync_to_physics, "AUDIT05 head platform de engine tu carry rider")
	assert_true(p.motion_trail.top_level, "AUDIT05 MotionTrail nam o goc level")
	assert_eq(p.motion_trail.get("_target"), p, "AUDIT05 MotionTrail da setup target")
	assert_eq(p._get_color_for_form(), GdxPalette.COLOR_FORM_CUBE, "AUDIT05 mau Cube lay tu palette")
	p.switch_form(&"DASH")
	assert_eq(p._get_color_for_form(), GdxPalette.COLOR_FORM_DASH, "AUDIT05 mau Dash lay tu palette")
	assert_true(p.visual_controller.has_method("show_transformation_effect"), "AUDIT05 hieu ung bien hinh co delegate")
	_cleanup([p])
