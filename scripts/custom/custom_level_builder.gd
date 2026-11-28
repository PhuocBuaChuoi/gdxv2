class_name CustomLevelBuilder
extends RefCounted

## Builds a playable LevelRoot (Node2D) scene from portable `.gdx.json` level data.

const BASE_LEVEL_SCENE := preload("res://levels/base_level.tscn")


static func build_from_file(path: String, level_index: int = 0, is_playtest: bool = false) -> Node2D:
	var data := CustomLevelStore.load_file(path)
	if data.is_empty():
		return null
	return build_scene(data, level_index, path, is_playtest)


static func _is_num(v: Variant) -> bool:
	if v is int:
		return true
	if v is float:
		return not (is_nan(v as float) or is_inf(v as float))
	return false


static func _safe_str(v: Variant, fallback: String = "") -> String:
	if v == null or not (v is String):
		return fallback
	var s := v as String
	return fallback if s == "" else s


static func _safe_int(v: Variant, fallback: int = 0) -> int:
	if _is_num(v):
		return int(v)
	if v is String and (v as String).is_valid_int():
		return int(v)
	return fallback


static func _safe_float(v: Variant, fallback: float = 0.0) -> float:
	if _is_num(v):
		return float(v)
	if v is String and (v as String).is_valid_float():
		return float(v)
	return fallback


static func _safe_bool(v: Variant, fallback: bool = false) -> bool:
	if v is bool:
		return v as bool
	return fallback


static func _read_vec2(v: Variant, fallback: Vector2) -> Vector2:
	if v is Array:
		var arr := v as Array
		if arr.size() >= 2 and _is_num(arr[0]) and _is_num(arr[1]):
			return Vector2(float(arr[0]), float(arr[1]))
	return fallback


static func _read_vec2i(v: Variant, fallback: Vector2i) -> Vector2i:
	if v is Array:
		var arr := v as Array
		if arr.size() >= 2 and _is_num(arr[0]) and _is_num(arr[1]):
			return Vector2i(int(arr[0]), int(arr[1]))
	return fallback


static func build_scene(data: Dictionary, level_index: int = 0, source_path: String = "", is_playtest: bool = false) -> Node2D:
	if data == null or data.is_empty():
		return null
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
	root.set("background", _safe_str(data.get("background", "FOREST"), "FOREST"))
	root.set("start_form_p1", StringName(_safe_str(data.get("start_form_p1", "CUBE"), "CUBE")))
	root.set("start_form_p2", StringName(_safe_str(data.get("start_form_p2", "CUBE"), "CUBE")))

	var bg := root.get_node_or_null("StageBackground")
	if bg != null:
		bg.set("dim", clampf(_safe_float(data.get("dim", 0.55), 0.55), 0.0, 1.0))

	var rows := PackedStringArray()
	var map_v: Variant = data.get("ascii_map", [])
	if map_v is Array:
		for r in (map_v as Array):
			rows.append(r as String if r is String else "")
	root.set("ascii_map", rows)

	var p1_pos := _read_vec2(data.get("spawn_p1", null), Vector2(144.0, 384.0))
	var p2_pos := _read_vec2(data.get("spawn_p2", null), Vector2(216.0, 384.0))
	var sp1 := root.get_node_or_null("SpawnP1") as Marker2D
	var sp2 := root.get_node_or_null("SpawnP2") as Marker2D
	if sp1 != null:
		sp1.position = p1_pos
	if sp2 != null:
		sp2.position = p2_pos

	root.set_meta("is_custom_level", true)
	root.set_meta("is_playtest", is_playtest)
	root.set_meta("custom_level_id", _safe_str(data.get("id", ""), ""))
	root.set_meta("custom_level_name", _safe_str(data.get("name", "Custom Stage"), "Custom Stage"))
	root.set_meta("custom_level_path", source_path)

	var uid_map: Dictionary = {}
	var pending_links: Array[Dictionary] = []

	var objs_v: Variant = data.get("objects", [])
	var objs: Array = objs_v as Array if objs_v is Array else []
	for item in objs:
		if not (item is Dictionary):
			continue
		var obj := item as Dictionary
		var obj_type := _safe_str(obj.get("type", ""), "")
		if obj_type == "":
			continue
		var uid := _safe_str(obj.get("uid", ""), "")
		var pos := _read_vec2(obj.get("pos", null), Vector2.ZERO)
		var props_v: Variant = obj.get("props", {})
		var props: Dictionary = props_v as Dictionary if props_v is Dictionary else {}

		if obj_type == "ControlSign":
			var lbl := Label.new()
			lbl.name = uid if uid != "" else "ControlSign"
			lbl.position = pos
			lbl.text = _safe_str(props.get("text", "P1 & P2 CO-OP!"), "P1 & P2 CO-OP!")
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

		apply_object_props(node, obj_type, props)

		var default_container := str(CustomLevelCatalog.TYPE_TO_CONTAINER.get(obj_type, "Mechanisms"))
		var container_name := _safe_str(obj.get("container", default_container), default_container)
		var target_parent := root.get_node_or_null(container_name)
		if target_parent == null:
			target_parent = root
		target_parent.add_child(node)

		if uid != "":
			if uid_map.has(uid):
				push_warning("CustomLevelBuilder: duplicate UID '%s' ignored for wire resolution." % uid)
			else:
				uid_map[uid] = node
				if obj_type == "MechanizedPlatform" or obj_type == "EnergyGate":
					var uids_v: Variant = props.get("linked_uids", [])
					if uids_v is Array:
						pending_links.append({"node": node, "type": obj_type, "uids": uids_v})
				elif obj_type == "PressureButton":
					var paired := _safe_str(props.get("paired_uid", ""), "")
					if paired != "":
						pending_links.append({"node": node, "type": "PressureButton", "paired": paired})

	for entry in pending_links:
		var node := entry["node"] as Node
		var entry_type := str(entry["type"])
		if entry_type == "MechanizedPlatform" or entry_type == "EnergyGate":
			var paths: Array[NodePath] = []
			var seen_targets: Dictionary = {}
			var uid_list := entry.get("uids", []) as Array
			for link_uid_v in uid_list:
				var link_uid := _safe_str(link_uid_v, "")
				if link_uid == "" or seen_targets.has(link_uid):
					continue
				var target_node := uid_map.get(link_uid, null) as Node
				if target_node != null and target_node is PressureButton and target_node != node:
					seen_targets[link_uid] = true
					paths.append(node.get_path_to(target_node))
			node.set("linked_triggers", paths)
		elif entry_type == "PressureButton":
			var partner := uid_map.get(_safe_str(entry.get("paired", ""), ""), null) as Node
			if partner != null and partner is PressureButton and partner != node:
				node.set("paired_button", node.get_path_to(partner))

	return root


static func apply_object_props(node: Node2D, obj_type: String, props: Dictionary) -> void:
	if node == null or props == null:
		return
	match obj_type:
		"SpikeHazard":
			node.set("hazard_type", _safe_int(props.get("hazard_type", 0), 0))
			node.set("tile_count", _safe_int(props.get("tile_count", 2), 2))
			node.set("orientation", _safe_int(props.get("orientation", 0), 0))
		"LaserHazard":
			node.set("hazard_type", _safe_int(props.get("hazard_type", 0), 0))
			node.set("period", _safe_float(props.get("period", 2.0), 2.0))
			node.set("duty", _safe_float(props.get("duty", 0.5), 0.5))
			node.set("start_on", _safe_bool(props.get("start_on", true), true))
		"FormPortal":
			node.set("target_form", _safe_str(props.get("target_form", "CUBE"), "CUBE"))
			node.set("allowed_player", _safe_str(props.get("allowed_player", "BOTH"), "BOTH"))
		"GravityPortal":
			node.set("allowed_player", _safe_str(props.get("allowed_player", "BOTH"), "BOTH"))
			node.set("direction_mode", _safe_int(props.get("direction_mode", 1), 1))
			node.set("target_direction", _safe_int(props.get("target_direction", -1), -1))
			node.set("one_shot", _safe_bool(props.get("one_shot", false), false))
		"JumpPad":
			node.set("pad_type", _safe_int(props.get("pad_type", 0), 0))
		"JumpOrb":
			node.set("orb_type", _safe_int(props.get("orb_type", 0), 0))
		"PressureButton":
			node.set("mode", _safe_int(props.get("mode", 0), 0))
			node.set("activator", _safe_int(props.get("activator", 0), 0))
			node.set("pair_window", _safe_float(props.get("pair_window", 0.5), 0.5))
		"MechanizedPlatform":
			node.set("move_offset", _read_vec2(props.get("move_offset", null), Vector2(0.0, -96.0)))
			node.set("speed", _safe_float(props.get("speed", 140.0), 140.0))
			node.set("require_all", _safe_bool(props.get("require_all", false), false))
		"EnergyGate":
			var gs := _read_vec2i(props.get("gate_size", null), Vector2i(2, 3))
			node.set("gate_size", Vector2i(maxi(1, gs.x), maxi(1, gs.y)))
			node.set("require_all", _safe_bool(props.get("require_all", true), true))
			node.set("open_time", _safe_float(props.get("open_time", 0.18), 0.18))
		"BreakableDashBlock":
			var bs := _read_vec2i(props.get("block_size", null), Vector2i(1, 3))
			node.set("block_size", Vector2i(maxi(1, bs.x), maxi(1, bs.y)))
		"BalancedFloatPair":
			node.set("horizontal_separation", _safe_float(props.get("horizontal_separation", 96.0), 96.0))
			node.set("spring_strength", _safe_float(props.get("spring_strength", 18.0), 18.0))
			node.set("damping", _safe_float(props.get("damping", 7.0), 7.0))
		"RestorePoint":
			node.set("checkpoint_order", _safe_int(props.get("checkpoint_order", 1), 1))
			node.set("require_both_players", _safe_bool(props.get("require_both_players", false), false))
		"DualExitGate":
			node.set("hold_time", _safe_float(props.get("hold_time", 0.5), 0.5))
		"DecoProp":
			node.set("prop_type", _safe_int(props.get("prop_type", 0), 0))
			node.set("flip_h", _safe_bool(props.get("flip_h", false), false))
