extends Node

## T7.04 — Quản lý danh sách màn chiến dịch (level_01..level_06) + màn custom (.gdx.json)
## nằm ở vị trí SAU 6 màn khởi đầu, cùng chế độ Playtest cho Level Editor.

const LEVEL_DIR := "res://levels"
const LEVEL_PREFIX := "level_"
const EDITOR_SCENE := "res://ui/level_editor.tscn"
const HUB_SCENE := "res://ui/custom_levels_hub.tscn"

var save_path: String = "user://save_data.cfg"
var levels: Array[String] = []
var campaign_total: int = 0
var custom_meta: Dictionary = {}
var current_index: int = -1
var unlocked: int = 1
var best: Dictionary = {}

# Playtest & Custom Editor handoff state
var is_playtest: bool = false
var playtest_data: Dictionary = {}
var playtest_source_path: String = ""
var pending_editor_data: Dictionary = {}
var pending_editor_path: String = ""


func _ready() -> void:
	rescan()
	load_progress()
	Events.level_completed.connect(_on_level_completed)


func _exit_tree() -> void:
	if Events.level_completed.is_connected(_on_level_completed):
		Events.level_completed.disconnect(_on_level_completed)


func _on_level_completed(level_index: int, deaths: int, time_taken: float) -> void:
	if is_playtest:
		return
	record_result(level_index, time_taken, deaths)


func rescan() -> void:
	levels.clear()
	custom_meta.clear()
	# 1. Quét 6 màn chiến dịch gốc (level_*.tscn) giữ cố định ở vị trí đầu 0..campaign_total-1
	var campaign_files: Array[String] = []
	var dir := DirAccess.open(LEVEL_DIR)
	if dir != null:
		dir.list_dir_begin()
		var f: String = dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.begins_with(LEVEL_PREFIX) and f.ends_with(".tscn"):
				campaign_files.append(LEVEL_DIR + "/" + f)
			f = dir.get_next()
		dir.list_dir_end()
		campaign_files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	for path in campaign_files:
		levels.append(path)
	campaign_total = campaign_files.size()

	# 2. Quét màn custom (.gdx.json) xếp ngay SAU 6 màn khởi đầu
	for entry in CustomLevelStore.list_levels():
		var cpath := str(entry.get("path", ""))
		if cpath == "":
			continue
		var idx := levels.size()
		levels.append(cpath)
		custom_meta[idx] = {
			"id": str(entry.get("id", "")),
			"name": str(entry.get("name", cpath.get_file().trim_suffix(".gdx.json"))),
			"path": cpath,
		}


func level_count() -> int:
	return levels.size()


func campaign_count() -> int:
	return campaign_total


func is_custom_index(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	return levels[index].ends_with(".gdx.json")


func custom_info_at(index: int) -> Dictionary:
	return custom_meta.get(index, {}) as Dictionary


func load_level(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	is_playtest = false
	var target := levels[index]
	if target.ends_with(".gdx.json"):
		var scene := CustomLevelBuilder.build_from_file(target, index, false)
		if scene == null:
			return false
		if not _swap_current_scene(scene):
			scene.free()
			return false
		current_index = index
		return true
	if get_tree().change_scene_to_file(target) != OK:
		return false
	current_index = index
	return true


func play_custom_data(data: Dictionary, source_path: String = "") -> bool:
	is_playtest = false
	var idx := -1
	if source_path != "":
		idx = levels.find(source_path)
	var scene := CustomLevelBuilder.build_scene(data, idx, source_path, false)
	if scene == null:
		return false
	if not _swap_current_scene(scene):
		scene.free()
		return false
	current_index = idx
	return true


func start_playtest(data: Dictionary, source_path: String = "") -> bool:
	is_playtest = true
	playtest_data = data.duplicate(true)
	playtest_source_path = source_path
	pending_editor_data = data.duplicate(true)
	pending_editor_path = source_path
	var scene := CustomLevelBuilder.build_scene(playtest_data, -1, source_path, true)
	if scene == null:
		is_playtest = false
		return false
	if not _swap_current_scene(scene):
		is_playtest = false
		scene.free()
		return false
	current_index = -1
	return true


func return_to_editor() -> bool:
	is_playtest = false
	get_tree().paused = false
	return get_tree().change_scene_to_file(EDITOR_SCENE) == OK


func open_editor(data: Dictionary = {}, source_path: String = "") -> bool:
	is_playtest = false
	pending_editor_data = data.duplicate(true)
	pending_editor_path = source_path
	get_tree().paused = false
	return get_tree().change_scene_to_file(EDITOR_SCENE) == OK


func consume_pending_editor_state() -> Dictionary:
	var out := {
		"data": pending_editor_data.duplicate(true),
		"path": pending_editor_path,
	}
	pending_editor_data = {}
	pending_editor_path = ""
	return out


func _swap_current_scene(new_scene: Node) -> bool:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return false
	tree.paused = false
	var old_scene := tree.current_scene
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	if old_scene != null and is_instance_valid(old_scene):
		old_scene.queue_free()
	return true


func load_next_level() -> bool:
	if is_playtest:
		return false
	return load_level(current_index + 1)


func reload_current_level() -> bool:
	if is_playtest and not playtest_data.is_empty():
		return start_playtest(playtest_data, playtest_source_path)
	return load_level(current_index)


## Ghi nhận kết quả màn: màn chiến dịch mở khóa màn kế; màn custom chỉ lưu kỷ lục riêng.
func record_result(index: int, time_taken: float, death_count: int) -> void:
	if index < 0:
		return
	if not is_custom_index(index):
		unlocked = mini(maxi(unlocked, index + 2), maxi(campaign_total, 1))
	var key := str(index)
	if is_custom_index(index):
		var meta := custom_info_at(index)
		var cid := str(meta.get("id", ""))
		if cid != "":
			key = "custom_" + cid
	if not best.has(key):
		best[key] = {"time": time_taken, "deaths": death_count}
	else:
		best[key]["time"] = minf(float(best[key]["time"]), time_taken)
		best[key]["deaths"] = mini(int(best[key]["deaths"]), death_count)
	save_progress()


func best_record_for(index: int) -> Dictionary:
	if is_custom_index(index):
		var meta := custom_info_at(index)
		var cid := str(meta.get("id", ""))
		if cid != "" and best.has("custom_" + cid):
			return best["custom_" + cid] as Dictionary
	if best.has(str(index)):
		return best[str(index)] as Dictionary
	return {}


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best", best)
	cfg.save(save_path)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	unlocked = int(cfg.get_value("progress", "unlocked", 1))
	unlocked = clampi(unlocked, 1, maxi(campaign_total if campaign_total > 0 else level_count(), 1))
	best = cfg.get_value("progress", "best", {}) as Dictionary
