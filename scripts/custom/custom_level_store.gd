class_name CustomLevelStore
extends RefCounted

## Portable `.gdx.json` storage inside `res://levels/custom/` (copyable/portable across machines),
## with automatic fallback to `user://custom_levels/` if `res://` is read-only in exported builds.

const RES_CUSTOM_DIR := "res://levels/custom"
const USER_CUSTOM_DIR := "user://custom_levels"
const EXT := ".gdx.json"


static func _ensure_dir(dir_path: String) -> bool:
	var abs_path := ProjectSettings.globalize_path(dir_path)
	if DirAccess.dir_exists_absolute(abs_path):
		return true
	return DirAccess.make_dir_recursive_absolute(abs_path) == OK


static func _can_write_dir(dir_path: String) -> bool:
	if not _ensure_dir(dir_path):
		return false
	var probe := dir_path.path_join(".write_probe.tmp")
	var abs_probe := ProjectSettings.globalize_path(probe)
	var f := FileAccess.open(abs_probe, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string("ok")
	f.close()
	DirAccess.remove_absolute(abs_probe)
	return true


static func active_save_dir(dir_override: String = "") -> String:
	if dir_override != "":
		_ensure_dir(dir_override)
		return dir_override
	if _can_write_dir(RES_CUSTOM_DIR):
		return RES_CUSTOM_DIR
	_ensure_dir(USER_CUSTOM_DIR)
	return USER_CUSTOM_DIR


static func get_portable_dir_abs(dir_override: String = "") -> String:
	return ProjectSettings.globalize_path(active_save_dir(dir_override))


static func open_custom_folder(dir_override: String = "") -> void:
	OS.shell_open(get_portable_dir_abs(dir_override))


static func slugify(text: String) -> String:
	var lower := text.strip_edges().to_lower()
	var out := ""
	var prev_dash := false
	for i in range(lower.length()):
		var ch := lower.unicode_at(i)
		var is_alnum := (ch >= 97 and ch <= 122) or (ch >= 48 and ch <= 57)
		if is_alnum:
			out += char(ch)
			prev_dash = false
		elif not prev_dash and out != "":
			out += "_"
			prev_dash = true
	out = out.trim_suffix("_")
	if out == "":
		out = "custom_level"
	return out


static func _scan_dir(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		var abs_dir := ProjectSettings.globalize_path(dir_path)
		if DirAccess.dir_exists_absolute(abs_dir):
			dir = DirAccess.open(abs_dir)
	if dir == null:
		return found
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(EXT):
			found.append(dir_path.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()
	found.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return found


static func list_level_files(dir_override: String = "") -> Array[String]:
	if dir_override != "":
		var out_override: Array[String] = []
		for path in _scan_dir(dir_override):
			var data := load_file(path)
			if data.is_empty():
				continue
			out_override.append(path)
		return out_override
	var files: Array[String] = []
	var seen_ids := {}
	for path in _scan_dir(USER_CUSTOM_DIR) + _scan_dir(RES_CUSTOM_DIR):
		var data := load_file(path)
		if data.is_empty():
			continue
		var lid := str(data.get("id", path.get_file()))
		if seen_ids.has(lid):
			continue
		seen_ids[lid] = true
		files.append(path)
	return files


static func list_levels(dir_override: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for path in list_level_files(dir_override):
		var data := load_file(path)
		if data.is_empty():
			continue
		out.append({
			"path": path,
			"data": data,
			"name": str(data.get("name", path.get_file().trim_suffix(EXT))),
			"id": str(data.get("id", "")),
			"is_portable_res": path.begins_with(RES_CUSTOM_DIR),
		})
	return out


static func load_file(path: String) -> Dictionary:
	var abs_path := ProjectSettings.globalize_path(path)
	var use_path := path if FileAccess.file_exists(path) else abs_path
	if not FileAccess.file_exists(use_path):
		return {}
	return parse_json_data(FileAccess.get_file_as_string(use_path))


static func _is_valid_num(v: Variant) -> bool:
	if v is int:
		return true
	if v is float:
		return not (is_nan(v as float) or is_inf(v as float))
	return false


static func _sanitize_str(v: Variant, fallback: String) -> String:
	if v == null or not (v is String):
		return fallback
	var s := (v as String).strip_edges()
	return fallback if s == "" else (v as String)


static func _sanitize_vec2_arr(v: Variant, fallback: Array[float]) -> Array[float]:
	if v is Array:
		var arr := v as Array
		if arr.size() >= 2 and _is_valid_num(arr[0]) and _is_valid_num(arr[1]):
			return [float(arr[0]), float(arr[1])]
	return fallback.duplicate()


static func parse_json_data(raw: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return {}
	var d := (parsed as Dictionary).duplicate(true)
	var raw_map_v: Variant = d.get("ascii_map", null)
	if not (raw_map_v is Array):
		return {}
	var raw_map := raw_map_v as Array
	if raw_map.is_empty():
		return {}
	var clean_map: Array[String] = []
	var max_cols := 0
	for row_v in raw_map:
		var row_s := (row_v as String) if (row_v is String) else ""
		clean_map.append(row_s)
		max_cols = maxi(max_cols, row_s.length())
	if max_cols <= 0:
		return {}
	d["ascii_map"] = clean_map

	d["format"] = _sanitize_str(d.get("format", null), "gdxv2-level")
	var ver_v: Variant = d.get("version", null)
	d["version"] = int(ver_v) if _is_valid_num(ver_v) else 1

	var raw_id: Variant = d.get("id", null)
	var id_str := ""
	if raw_id is String:
		id_str = (raw_id as String).strip_edges()
	elif raw_id is int:
		id_str = str(raw_id)
	if id_str == "":
		id_str = "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	d["id"] = id_str

	d["name"] = _sanitize_str(d.get("name", null), "Custom Stage")
	d["author"] = _sanitize_str(d.get("author", null), "Player")

	var bg := _sanitize_str(d.get("background", null), "FOREST").to_upper()
	d["background"] = bg if bg in ["FOREST", "BRIGHT"] else "FOREST"

	var dim_v: Variant = d.get("dim", null)
	d["dim"] = clampf(float(dim_v), 0.0, 1.0) if _is_valid_num(dim_v) else 0.55

	var valid_forms := ["CUBE", "SHIP", "UFO", "DASH"]
	var sf1 := _sanitize_str(d.get("start_form_p1", null), "CUBE").to_upper()
	d["start_form_p1"] = sf1 if sf1 in valid_forms else "CUBE"
	var sf2 := _sanitize_str(d.get("start_form_p2", null), "CUBE").to_upper()
	d["start_form_p2"] = sf2 if sf2 in valid_forms else "CUBE"

	var cols_v: Variant = d.get("grid_cols", null)
	d["grid_cols"] = int(cols_v) if (_is_valid_num(cols_v) and int(cols_v) > 0) else max_cols
	var rows_v: Variant = d.get("grid_rows", null)
	d["grid_rows"] = int(rows_v) if (_is_valid_num(rows_v) and int(rows_v) > 0) else clean_map.size()

	d["spawn_p1"] = _sanitize_vec2_arr(d.get("spawn_p1", null), [144.0, 384.0])
	d["spawn_p2"] = _sanitize_vec2_arr(d.get("spawn_p2", null), [216.0, 384.0])

	var clean_objs: Array[Dictionary] = []
	var raw_objs: Variant = d.get("objects", null)
	if raw_objs is Array:
		for item in (raw_objs as Array):
			if not (item is Dictionary):
				continue
			var obj := (item as Dictionary).duplicate(true)
			var obj_type := _sanitize_str(obj.get("type", null), "")
			obj["type"] = obj_type
			obj["uid"] = _sanitize_str(obj.get("uid", null), "")
			obj["pos"] = _sanitize_vec2_arr(obj.get("pos", null), [0.0, 0.0])
			var props_v: Variant = obj.get("props", null)
			obj["props"] = (props_v as Dictionary).duplicate(true) if (props_v is Dictionary) else {}
			var default_container := str(CustomLevelCatalog.TYPE_TO_CONTAINER.get(obj_type, "Mechanisms"))
			obj["container"] = _sanitize_str(obj.get("container", null), default_container)
			clean_objs.append(obj)
	d["objects"] = clean_objs
	return d


static func _unique_path_in_dir(target_dir: String, clean: Dictionary) -> String:
	var base := slugify(str(clean.get("name", "custom_stage")))
	var out_path := target_dir.path_join("%s%s" % [base, EXT])
	var n := 2
	while FileAccess.file_exists(out_path) or FileAccess.file_exists(ProjectSettings.globalize_path(out_path)):
		var existing := load_file(out_path)
		if not existing.is_empty() and str(existing.get("id", "")) == str(clean["id"]):
			break
		out_path = target_dir.path_join("%s_%d%s" % [base, n, EXT])
		n += 1
	return out_path


static func _write_json_to_path(out_path: String, clean: Dictionary) -> bool:
	var abs_out := ProjectSettings.globalize_path(out_path)
	var parent_dir := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_dir):
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var f := FileAccess.open(abs_out, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(export_json_string(clean))
	f.close()
	return true


static func save_level(data: Dictionary, existing_path: String = "", dir_override: String = "") -> String:
	var clean := data.duplicate(true)
	clean["format"] = "gdxv2-level"
	clean["version"] = 1
	if clean.get("id", null) == null or str(clean.get("id", "")).strip_edges() == "":
		clean["id"] = "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var target_dir := active_save_dir(dir_override)
	var out_path := existing_path
	if dir_override == "" and out_path.begins_with(RES_CUSTOM_DIR) and not _can_write_dir(RES_CUSTOM_DIR):
		_ensure_dir(USER_CUSTOM_DIR)
		out_path = _unique_path_in_dir(USER_CUSTOM_DIR, clean)
	if out_path == "" or not out_path.ends_with(EXT):
		out_path = _unique_path_in_dir(target_dir, clean)
	if _write_json_to_path(out_path, clean):
		return out_path
	if dir_override == "" and not out_path.begins_with(USER_CUSTOM_DIR):
		_ensure_dir(USER_CUSTOM_DIR)
		var fallback_path := _unique_path_in_dir(USER_CUSTOM_DIR, clean)
		if _write_json_to_path(fallback_path, clean):
			return fallback_path
	return ""


static func delete_file(path: String) -> bool:
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return false
	return DirAccess.remove_absolute(abs_path) == OK


static func duplicate_file(path: String, dir_override: String = "") -> String:
	var src := load_file(path)
	if src.is_empty():
		return ""
	src["id"] = "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	src["name"] = "%s (Copy)" % str(src.get("name", "Custom"))
	return save_level(src, "", dir_override)


static func export_json_string(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


static func import_json_string(raw: String, dir_override: String = "") -> Dictionary:
	var data := parse_json_data(raw)
	if data.is_empty():
		return {"ok": false, "path": "", "data": {}, "error": "invalid_json"}
	var existing_ids := {}
	for entry in list_levels(dir_override):
		var eid := str(entry.get("id", ""))
		if eid != "":
			existing_ids[eid] = true
	var cid := str(data.get("id", ""))
	if cid == "" or existing_ids.has(cid):
		var fresh_id := "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
		while existing_ids.has(fresh_id):
			fresh_id = "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]
		data["id"] = fresh_id
	var saved_path := save_level(data, "", dir_override)
	if saved_path == "":
		return {"ok": false, "path": "", "data": {}, "error": "write_failed"}
	return {"ok": true, "path": saved_path, "data": data, "error": ""}


static func import_from_file(src_path: String, dir_override: String = "") -> Dictionary:
	var clean_src := src_path.strip_edges().trim_prefix("\"").trim_suffix("\"")
	var abs_src := ProjectSettings.globalize_path(clean_src)
	var use_path := clean_src if FileAccess.file_exists(clean_src) else abs_src
	if not FileAccess.file_exists(use_path):
		return {"ok": false, "path": "", "data": {}, "error": "not_found"}
	return import_json_string(FileAccess.get_file_as_string(use_path), dir_override)
