extends "res://tests/gdx_test.gd"

## Giám sát tự động registry chống dẫm chân (.agents/ownership.json):
## - File phải parse được, đúng schema tối thiểu.
## - KHÔNG có 2 claim status=active nào overlap phạm vi paths.


func test_ownership_json_valid() -> void:
	var path: String = "res://.agents/ownership.json"
	assert_true(FileAccess.file_exists(path), "ownership.json ton tai")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(data is Dictionary, "ownership.json parse duoc thanh Dictionary")
	if not (data is Dictionary):
		return
	assert_true((data as Dictionary).has("claims"), "ownership.json co key 'claims'")
	var claims: Variant = (data as Dictionary).get("claims", [])
	assert_true(claims is Array, "claims la Array")
	if claims is Array:
		for c in (claims as Array):
			assert_true(c is Dictionary and (c as Dictionary).has("id") and (c as Dictionary).has("paths") and (c as Dictionary).has("status"), "moi claim co id/paths/status (got=%s)" % str(c))


func test_no_overlapping_active_claims() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.agents/ownership.json"))
	if not (data is Dictionary):
		assert_true(false, "ownership.json khong parse duoc — xem test_ownership_json_valid")
		return
	var active: Array = []
	for c in (data as Dictionary).get("claims", []):
		if c is Dictionary and str((c as Dictionary).get("status", "")) == "active":
			active.append(c)
	for i in range(active.size()):
		for j in range(i + 1, active.size()):
			var overlap: String = _overlap(active[i] as Dictionary, active[j] as Dictionary)
			assert_true(overlap == "", "trung claim active: %s vs %s @ %s" % [str((active[i] as Dictionary).get("id")), str((active[j] as Dictionary).get("id")), overlap])


## Overlap = bằng nhau, hoặc 1 path là tiền tố thư mục của path kia.
func _overlap(a: Dictionary, b: Dictionary) -> String:
	var pa: Array = a.get("paths", [])
	var pb: Array = b.get("paths", [])
	for x in pa:
		for y in pb:
			var sx: String = str(x).trim_suffix("/")
			var sy: String = str(y).trim_suffix("/")
			if sx == sy or sx.begins_with(sy + "/") or sy.begins_with(sx + "/"):
				return sx + " <> " + sy
	return ""
