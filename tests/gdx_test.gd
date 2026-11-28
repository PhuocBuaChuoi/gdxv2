class_name GdxTest
extends RefCounted

## Base class tối giản cho mọi test headless.
## Quy ước: class test đặt ở res://tests/test_*.gd, mỗi case là func test_*().

var checks_passed: int = 0
var checks_failed: int = 0
var failures: Array[String] = []


func _record(ok: bool, msg: String) -> void:
	if ok:
		checks_passed += 1
	else:
		checks_failed += 1
		failures.append(msg)
		printerr("  FAIL: ", msg)


func assert_true(cond: bool, msg: String) -> void:
	_record(cond, msg)


func assert_eq(got: Variant, want: Variant, msg: String) -> void:
	_record(got == want, "%s (got=%s want=%s)" % [msg, str(got), str(want)])


func assert_near(got: float, want: float, eps: float, msg: String) -> void:
	_record(absf(got - want) <= eps, "%s (got=%s want=%s eps=%s)" % [msg, str(got), str(want), str(eps)])


## Trả về danh sách physical_keycode của 1 input action ([] nếu action chưa tồn tại).
func action_keys(action: StringName) -> Array[int]:
	var out: Array[int] = []
	if not InputMap.has_action(action):
		return out
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			out.append((e as InputEventKey).physical_keycode)
	return out


func assert_action_keys(action: StringName, want: Array, msg: String) -> void:
	if not InputMap.has_action(action):
		_record(false, "%s — action '%s' MISSING" % [msg, action])
		return
	var got: Array = action_keys(action)
	var ok: bool = got.size() == want.size()
	if ok:
		for k in want:
			if not got.has(k):
				ok = false
				break
	_record(ok, "%s — action '%s' keys got=%s want=%s" % [msg, action, str(got), str(want)])
