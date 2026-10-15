extends Node

## T7.04 — Quản lý danh sách màn, chuyển màn, lưu tiến độ (ConfigFile).
## Tự quét res://levels/level_*.tscn nên thêm màn mới không cần đăng ký tay.
## Không gọi load_* trong test (đổi scene giữa suite sẽ vỡ run).

const LEVEL_DIR := "res://levels"
const LEVEL_PREFIX := "level_"

var save_path: String = "user://save_data.cfg"
var levels: Array[String] = []
var current_index: int = -1
var unlocked: int = 1
var best: Dictionary = {}


func _ready() -> void:
	rescan()
	load_progress()


func rescan() -> void:
	levels.clear()
	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.begins_with(LEVEL_PREFIX) and f.ends_with(".tscn"):
			levels.append(LEVEL_DIR + "/" + f)
		f = dir.get_next()
	dir.list_dir_end()
	levels.sort()


func level_count() -> int:
	return levels.size()


func load_level(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	if get_tree().change_scene_to_file(levels[index]) != OK:
		return false
	current_index = index
	return true


func load_next_level() -> bool:
	return load_level(current_index + 1)


func reload_current_level() -> bool:
	return load_level(current_index)


## Ghi nhận kết quả màn: mở khóa màn kế + giữ kỷ lục tốt nhất.
func record_result(index: int, time_taken: float, death_count: int) -> void:
	unlocked = mini(maxi(unlocked, index + 2), maxi(level_count(), 1))
	var key := str(index)
	if not best.has(key):
		best[key] = {"time": time_taken, "deaths": death_count}
	else:
		best[key]["time"] = minf(float(best[key]["time"]), time_taken)
		best[key]["deaths"] = mini(int(best[key]["deaths"]), death_count)
	save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best", best)
	cfg.save(save_path)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	unlocked = int(cfg.get_value("progress", "unlocked", 1))
	best = cfg.get_value("progress", "best", {}) as Dictionary
