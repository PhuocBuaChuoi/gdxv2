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
	var abs_dir := ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(abs_dir):
		return found
	var dir := DirAccess.open(abs_dir)
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
		return _scan_dir(dir_override)
	var files: Array[String] = []
	var seen_ids := {}
	for path in _scan_dir(RES_CUSTOM_DIR) + _scan_dir(USER_CUSTOM_DIR):
		var data := load_file(path)
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
	var use_path := abs_path if FileAccess.file_exists(abs_path) else path
	if not FileAccess.file_exists(use_path):
		return {}
	return parse_json_data(FileAccess.get_file_as_string(use_path))


static func parse_json_data(raw: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return {}
	var d := (parsed as Dictionary).duplicate(true)
	if not d.has("ascii_map") or not (d["ascii_map"] is Array):
		return {}
	if not d.has("format"):
		d["format"] = "gdxv2-level"
	if not d.has("version"):
		d["version"] = 1
	if not d.has("id") or str(d["id"]) == "":
		d["id"] = "custom_%d" % int(Time.get_unix_time_from_system())
	if not d.has("name") or str(d["name"]) == "":
		d["name"] = "Custom Stage"
	if not d.has("background"):
		d["background"] = "FOREST"
	if not d.has("dim"):
		d["dim"] = 0.55
	if not d.has("start_form_p1"):
		d["start_form_p1"] = "CUBE"
	if not d.has("start_form_p2"):
		d["start_form_p2"] = "CUBE"
	if not d.has("objects") or not (d["objects"] is Array):
		d["objects"] = []
	return d


static func save_level(data: Dictionary, existing_path: String = "", dir_override: String = "") -> String:
	var clean := data.duplicate(true)
	clean["format"] = "gdxv2-level"
	clean["version"] = 1
	if str(clean.get("id", "")) == "":
		clean["id"] = "custom_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000]
	var target_dir := active_save_dir(dir_override)
	var out_path := existing_path
	if out_path == "" or not out_path.ends_with(EXT):
		var base := slugify(str(clean.get("name", "custom_stage")))
		out_path = target_dir.path_join("%s%s" % [base, EXT])
		var n := 2
		while FileAccess.file_exists(ProjectSettings.globalize_path(out_path)):
			var existing := load_file(out_path)
			if str(existing.get("id", "")) == str(clean["id"]):
				break
			out_path = target_dir.path_join("%s_%d%s" % [base, n, EXT])
			n += 1
	var abs_out := ProjectSettings.globalize_path(out_path)
	var parent_dir := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_dir):
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var f := FileAccess.open(abs_out, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(export_json_string(clean))
	f.close()
	return out_path


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
	var saved_path := save_level(data, "", dir_override)
	if saved_path == "":
		return {"ok": false, "path": "", "data": {}, "error": "write_failed"}
	return {"ok": true, "path": saved_path, "data": data, "error": ""}


static func import_from_file(src_path: String, dir_override: String = "") -> Dictionary:
	var clean_src := src_path.strip_edges().trim_prefix("\"").trim_suffix("\"")
	var abs_src := ProjectSettings.globalize_path(clean_src)
	var use_path := abs_src if FileAccess.file_exists(abs_src) else clean_src
	if not FileAccess.file_exists(use_path):
		return {"ok": false, "path": "", "data": {}, "error": "not_found"}
	return import_json_string(FileAccess.get_file_as_string(use_path), dir_override)
