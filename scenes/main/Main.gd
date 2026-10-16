extends Node2D

func _ready() -> void:
	# Main.tscn is the direct-play entry point for Level 1. Keep the manager
	# aligned with the scene so completion Retry/Next actions work as expected.
	var manager := get_node_or_null("/root/LevelManager")
	if manager != null:
		var levels: Array = manager.get("levels") as Array
		var level_index := levels.find("res://levels/level_01.tscn")
		if level_index >= 0:
			manager.set("current_index", level_index)
	print("gdxv2 — Game started!")
