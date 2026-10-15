extends SceneTree

## Test runner headless — KHÔNG attach vào scene nào.
## Chạy: godot --headless --path . -s res://tests/test_runner.gd
## (hoặc powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1)
## Exit code 0 = toàn bộ xanh, 1 = có fail.
##
## Lưu ý: file này TỰ LOẠI mình khỏi discovery (tên + guard "extends SceneTree"),
## vì khởi tạo 1 SceneTree lồng nhau sẽ gây đệ quy vô hạn.


func _process(_delta: float) -> bool:
	# Chạy 1 lần duy nhất ở frame đầu, rồi thoát.
	# (quit() trong _init gây "Stack underflow" — bug engine đã biết.)
	var total_fail: int = _run_suite()
	quit(1 if total_fail > 0 else 0)
	return true


func _run_suite() -> int:
	var files: Array[String] = _discover()
	files.sort()
	var total_pass: int = 0
	var total_fail: int = 0
	if files.is_empty():
		printerr("NO TEST FILES FOUND in res://tests/")
		return 1
	var preflight_fail: int = _preflight_shapes_contract()
	if preflight_fail > 0:
		return preflight_fail
	for path in files:
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			printerr("LOAD FAIL: ", path)
			total_fail += 1
			continue
		var t: Object = script.new()
		# Duck-typing thay vì `is GdxTest`: chạy được ngay cả khi
		# global class cache (.godot/) chưa được editor build.
		if not (t.has_method("assert_action_keys") and t.has_method("action_keys")):
			printerr("LOAD FAIL (invalid test contract): ", path)
			total_fail += 1
			continue
		t.set("host_root", root)
		print("== ", path)
		for m in t.get_method_list():
			var mname: String = str(m["name"])
			if mname.begins_with("test_"):
				t.call(mname)
		total_pass += int(t.get("checks_passed"))
		total_fail += int(t.get("checks_failed"))
		for f in t.get("failures"):
			printerr("  [", path, "] ", str(f))
	print("RESULT: pass=", total_pass, " fail=", total_fail)
	if total_fail > 0:
		printerr("TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	return total_fail


func _preflight_shapes_contract() -> int:
	var shapes_script: Script = load("res://scripts/procedural_shapes.gd") as Script
	if shapes_script == null:
		printerr("PREFLIGHT FAIL: procedural_shapes.gd did not load")
		return 1
	var required: Array[StringName] = [&"square_chamfered", &"ship_shape", &"ufo_disc", &"dash_arrow", &"spike_triangle", &"circle_points", &"make_visual", &"square_texture"]
	for method_name in required:
		if not shapes_script.has_method(method_name):
			printerr("PREFLIGHT FAIL: procedural_shapes.gd missing method ", method_name)
			return 1
	return 0


func _discover() -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open("res://tests")
	if dir == null:
		return out
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		if _is_test_file(dir, f):
			out.append("res://tests/" + f)
		f = dir.get_next()
	dir.list_dir_end()
	return out


func _is_test_file(dir: DirAccess, f: String) -> bool:
	if dir.current_is_dir():
		return false
	if not (f.begins_with("test_") and f.ends_with(".gd")):
		return false
	if f == "test_runner.gd":
		return false
	# Guard chống đệ quy: không bao giờ nạp script là SceneTree/MainLoop.
	var src: String = FileAccess.get_file_as_string("res://tests/" + f)
	if src.contains("extends SceneTree") or src.contains("extends MainLoop"):
		return false
	return true
