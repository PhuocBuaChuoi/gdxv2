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


func test_claims_schema() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.agents/ownership.json"))
	if not (data is Dictionary):
		assert_true(false, "ownership.json khong parse duoc")
		return
	assert_eq(int((data as Dictionary).get("version", 0)), 1, "registry version 1")
	var rx := RegEx.new()
	rx.compile("^\\d{4}-\\d{2}-\\d{2}$")
	for c in (data as Dictionary).get("claims", []):
		if not (c is Dictionary):
			continue
		var d: Dictionary = c
		var cid: String = str(d.get("id", "?"))
		if str(d.get("status", "")) == "active":
			assert_true(str(d.get("owner", "")) != "", "claim '%s' co owner" % cid)
			assert_true(str(d.get("branch", "")) != "", "claim '%s' co branch" % cid)
			assert_true((d.get("paths", []) as Array).size() > 0, "claim '%s' co paths" % cid)
		assert_true(rx.search(str(d.get("updated", ""))) != null, "claim '%s' updated dung YYYY-MM-DD" % cid)
		var seen: Dictionary = {}
		for p in (d.get("paths", []) as Array):
			assert_true(str(p) != "", "claim '%s' khong co path rong" % cid)
			assert_true(not seen.has(str(p)), "claim '%s' khong lap path '%s'" % [cid, str(p)])
			seen[str(p)] = true


func test_done_claim_paths_exist() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.agents/ownership.json"))
	if not (data is Dictionary):
		assert_true(false, "ownership.json khong parse duoc")
		return
	for c in (data as Dictionary).get("claims", []):
		if c is Dictionary and str((c as Dictionary).get("status", "")) == "done":
			for p in ((c as Dictionary).get("paths", []) as Array):
				assert_true(_claim_path_exists(str(p)), "claim done '%s': path ton tai (%s)" % [str((c as Dictionary).get("id")), str(p)])


func _claim_path_exists(p: String) -> bool:
	var base: String = "res://" + p.trim_suffix("/")
	return DirAccess.dir_exists_absolute(base) or FileAccess.file_exists(base)


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
