class_name CustomLevelBuilder
extends RefCounted

## Builds a playable LevelRoot (Node2D) scene from portable `.gdx.json` level data.

const BASE_LEVEL_SCENE := preload("res://levels/base_level.tscn")


static func build_from_file(path: String, level_index: int = 0, is_playtest: bool = false) -> Node2D:
	var data := CustomLevelStore.load_file(path)
	if data.is_empty():
		return null
	return build_scene(data, level_index, path, is_playtest)


static func build_scene(data: Dictionary, level_index: int = 0, source_path: String = "", is_playtest: bool = false) -> Node2D:
	var root := BASE_LEVEL_SCENE.instantiate() as Node2D
	if root == null:
		return null

	for cname in ["Hazards", "Portals", "Mechanisms", "Checkpoints"]:
		var container := root.get_node_or_null(cname)
		if container != null:
			for child in container.get_children():
				container.remove_child(child)
				child.free()

	var deco_container := root.get_node_or_null("Decorations") as Node2D
	if deco_container == null:
		deco_container = Node2D.new()
		deco_container.name = "Decorations"
		root.add_child(deco_container)
		var hazards := root.get_node_or_null("Hazards")
		if hazards != null:
			root.move_child(deco_container, hazards.get_index())

	root.set("level_index", level_index)
	root.set("background", str(data.get("background", "FOREST")))
	root.set("start_form_p1", StringName(str(data.get("start_form_p1", "CUBE"))))
	root.set("start_form_p2", StringName(str(data.get("start_form_p2", "CUBE"))))

	var bg := root.get_node_or_null("StageBackground")
	if bg != null:
		bg.set("dim", float(data.get("dim", 0.55)))

	var rows := PackedStringArray()
	for r in (data.get("ascii_map", []) as Array):
		rows.append(str(r))
	root.set("ascii_map", rows)

	var p1_arr := data.get("spawn_p1", [144.0, 384.0]) as Array
	var p2_arr := data.get("spawn_p2", [216.0, 384.0]) as Array
	var sp1 := root.get_node_or_null("SpawnP1") as Marker2D
	var sp2 := root.get_node_or_null("SpawnP2") as Marker2D
	if sp1 != null and p1_arr.size() >= 2:
		sp1.position = Vector2(float(p1_arr[0]), float(p1_arr[1]))
	if sp2 != null and p2_arr.size() >= 2:
		sp2.position = Vector2(float(p2_arr[0]), float(p2_arr[1]))

	root.set_meta("is_custom_level", true)
	root.set_meta("is_playtest", is_playtest)
	root.set_meta("custom_level_id", str(data.get("id", "")))
	root.set_meta("custom_level_name", str(data.get("name", "Custom Stage")))
	root.set_meta("custom_level_path", source_path)

	var uid_map: Dictionary = {}
	var pending_links: Array[Dictionary] = []

	for item in (data.get("objects", []) as Array):
		if not (item is Dictionary):
			continue
		var obj := item as Dictionary
		var obj_type := str(obj.get("type", ""))
		var uid := str(obj.get("uid", ""))
		var pos_arr := obj.get("pos", [0.0, 0.0]) as Array
		var pos := Vector2(float(pos_arr[0]), float(pos_arr[1])) if pos_arr.size() >= 2 else Vector2.ZERO
		var props := obj.get("props", {}) as Dictionary

		if obj_type == "ControlSign":
			var lbl := Label.new()
			lbl.name = uid if uid != "" else "ControlSign"
			lbl.position = pos
			lbl.text = str(props.get("text", "P1 & P2 CO-OP!"))
			lbl.z_index = 1
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color(0.35, 0.93, 1.0, 0.9))
			lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
			root.add_child(lbl)
			continue

		var scene_path := str(CustomLevelCatalog.TYPE_TO_SCENE.get(obj_type, ""))
		if scene_path == "":
			continue
		var ps := load(scene_path) as PackedScene
		if ps == null:
			continue
		var node := ps.instantiate() as Node2D
		if node == null:
			continue
		node.name = uid if uid != "" else obj_type
		node.position = pos

		var container_name := str(obj.get("container", CustomLevelCatalog.TYPE_TO_CONTAINER.get(obj_type, "Mechanisms")))
		var target_parent := root.get_node_or_null(container_name)
		if target_parent == null:
			target_parent = root
		target_parent.add_child(node)

		apply_object_props(node, obj_type, props)

		if uid != "":
			uid_map[uid] = node
			if obj_type == "MechanizedPlatform" or obj_type == "EnergyGate":
				pending_links.append({"node": node, "type": obj_type, "uids": props.get("linked_uids", [])})
			elif obj_type == "PressureButton" and str(props.get("paired_uid", "")) != "":
				pending_links.append({"node": node, "type": "PressureButton", "paired": str(props.get("paired_uid", ""))})

	for entry in pending_links:
		var node := entry["node"] as Node
		var entry_type := str(entry["type"])
		if entry_type == "MechanizedPlatform" or entry_type == "EnergyGate":
			var paths: Array[NodePath] = []
			for link_uid in (entry.get("uids", []) as Array):
				var target_node := uid_map.get(str(link_uid), null) as Node
				if target_node != null:
					paths.append(node.get_path_to(target_node))
			node.set("linked_triggers", paths)
		elif entry_type == "PressureButton":
			var partner := uid_map.get(str(entry.get("paired", "")), null) as Node
			if partner != null:
				node.set("paired_button", node.get_path_to(partner))

	return root


static func apply_object_props(node: Node2D, obj_type: String, props: Dictionary) -> void:
	match obj_type:
		"SpikeHazard":
			node.set("hazard_type", int(props.get("hazard_type", 0)))
			node.set("tile_count", int(props.get("tile_count", 2)))
			node.set("orientation", int(props.get("orientation", 0)))
		"LaserHazard":
			node.set("hazard_type", int(props.get("hazard_type", 0)))
			node.set("period", float(props.get("period", 2.0)))
			node.set("duty", float(props.get("duty", 0.5)))
			node.set("start_on", bool(props.get("start_on", true)))
		"FormPortal":
			node.set("target_form", str(props.get("target_form", "CUBE")))
			node.set("allowed_player", str(props.get("allowed_player", "BOTH")))
		"GravityPortal":
			node.set("direction_mode", int(props.get("direction_mode", 1)))
			node.set("target_direction", int(props.get("target_direction", -1)))
			node.set("one_shot", bool(props.get("one_shot", false)))
		"JumpPad":
			node.set("pad_type", int(props.get("pad_type", 0)))
		"JumpOrb":
			node.set("orb_type", int(props.get("orb_type", 0)))
		"PressureButton":
			node.set("mode", int(props.get("mode", 0)))
			node.set("activator", int(props.get("activator", 0)))
			node.set("pair_window", float(props.get("pair_window", 0.5)))
		"MechanizedPlatform":
			var off := props.get("move_offset", [0.0, -96.0]) as Array
			if off.size() >= 2:
				node.set("move_offset", Vector2(float(off[0]), float(off[1])))
			node.set("speed", float(props.get("speed", 140.0)))
			node.set("require_all", bool(props.get("require_all", false)))
		"EnergyGate":
			var gs := props.get("gate_size", [2, 3]) as Array
			if gs.size() >= 2:
				node.set("gate_size", Vector2i(int(gs[0]), int(gs[1])))
			node.set("require_all", bool(props.get("require_all", true)))
			node.set("open_time", float(props.get("open_time", 0.18)))
		"BalancedFloatPair":
			node.set("horizontal_separation", float(props.get("horizontal_separation", 96.0)))
			node.set("spring_strength", float(props.get("spring_strength", 18.0)))
			node.set("damping", float(props.get("damping", 7.0)))
		"RestorePoint":
			node.set("checkpoint_order", int(props.get("checkpoint_order", 1)))
			node.set("require_both_players", bool(props.get("require_both_players", false)))
		"DualExitGate":
			node.set("hold_time", float(props.get("hold_time", 0.5)))
		"DecoProp":
			node.set("prop_type", int(props.get("prop_type", 0)))
			node.set("flip_h", bool(props.get("flip_h", false)))
