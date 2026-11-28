class_name CustomLevelCatalog
extends RefCounted

## Central registry of all palette tools, objects, assets, defaults, and level validation rules.

const TILE_SIZE := 48.0

const PALETTE_ITEMS: Array[Dictionary] = [
	# --- Tab 0: Terrain & Spawns ---
	{
		"id": "tile_solid", "kind": "tile", "tab": 0, "char": "=",
		"label_key": "ed_obj_tile_solid", "icon": "res://assets/sprites/ai_tile_cyber_block.png",
	},
	{
		"id": "tile_oneway", "kind": "tile", "tab": 0, "char": "-",
		"label_key": "ed_obj_tile_oneway", "icon": "res://assets/sprites/mechanized_platform.png",
	},
	{
		"id": "tile_deco", "kind": "tile", "tab": 0, "char": ".",
		"label_key": "ed_obj_tile_deco", "icon": "res://assets/sprites/ai_cyber_arrow.png",
	},
	{
		"id": "spawn_p1", "kind": "spawn", "tab": 0, "spawn_id": 1,
		"label_key": "ed_obj_spawn_p1", "icon": "res://assets/sprites/portal_cube.png",
	},
	{
		"id": "spawn_p2", "kind": "spawn", "tab": 0, "spawn_id": 2,
		"label_key": "ed_obj_spawn_p2", "icon": "res://assets/sprites/portal_ship.png",
	},
	{
		"id": "control_sign", "kind": "object", "tab": 0, "type": "ControlSign", "container": "Root",
		"label_key": "ed_obj_control_sign", "icon": "res://assets/sprites/deco_arrow_sign.png",
		"default_props": {"text": "P1 & P2 CO-OP!"},
	},

	# --- Tab 1: Hazards ---
	{
		"id": "spike_neutral", "kind": "object", "tab": 1, "type": "SpikeHazard", "container": "Hazards",
		"scene": "res://components/spike_hazard.tscn",
		"label_key": "ed_obj_spike_neutral", "icon": "res://assets/sprites/spike_red.png",
		"default_props": {"hazard_type": 0, "tile_count": 2, "orientation": 0},
	},
	{
		"id": "spike_cyan", "kind": "object", "tab": 1, "type": "SpikeHazard", "container": "Hazards",
		"scene": "res://components/spike_hazard.tscn",
		"label_key": "ed_obj_spike_cyan", "icon": "res://assets/sprites/spike_cyan.png",
		"default_props": {"hazard_type": 1, "tile_count": 2, "orientation": 0},
	},
	{
		"id": "spike_orange", "kind": "object", "tab": 1, "type": "SpikeHazard", "container": "Hazards",
		"scene": "res://components/spike_hazard.tscn",
		"label_key": "ed_obj_spike_orange", "icon": "res://assets/sprites/spike_orange.png",
		"default_props": {"hazard_type": 2, "tile_count": 2, "orientation": 0},
	},
	{
		"id": "laser_neutral", "kind": "object", "tab": 1, "type": "LaserHazard", "container": "Hazards",
		"scene": "res://components/laser_hazard.tscn",
		"label_key": "ed_obj_laser_neutral", "icon": "res://assets/sprites/laser_emitter.png",
		"default_props": {"hazard_type": 0, "period": 2.0, "duty": 0.5, "start_on": true},
	},
	{
		"id": "laser_cyan", "kind": "object", "tab": 1, "type": "LaserHazard", "container": "Hazards",
		"scene": "res://components/laser_hazard.tscn",
		"label_key": "ed_obj_laser_cyan", "icon": "res://assets/sprites/laser_emitter.png",
		"default_props": {"hazard_type": 1, "period": 2.0, "duty": 0.5, "start_on": true},
	},
	{
		"id": "laser_orange", "kind": "object", "tab": 1, "type": "LaserHazard", "container": "Hazards",
		"scene": "res://components/laser_hazard.tscn",
		"label_key": "ed_obj_laser_orange", "icon": "res://assets/sprites/laser_emitter.png",
		"default_props": {"hazard_type": 2, "period": 2.0, "duty": 0.5, "start_on": true},
	},

	# --- Tab 2: Portals, Pads & Orbs ---
	{
		"id": "portal_cube", "kind": "object", "tab": 2, "type": "FormPortal", "container": "Portals",
		"scene": "res://components/form_portal.tscn",
		"label_key": "ed_obj_portal_cube", "icon": "res://assets/sprites/portal_cube.png",
		"default_props": {"target_form": "CUBE", "allowed_player": "BOTH"},
	},
	{
		"id": "portal_ship", "kind": "object", "tab": 2, "type": "FormPortal", "container": "Portals",
		"scene": "res://components/form_portal.tscn",
		"label_key": "ed_obj_portal_ship", "icon": "res://assets/sprites/portal_ship.png",
		"default_props": {"target_form": "SHIP", "allowed_player": "BOTH"},
	},
	{
		"id": "portal_ufo", "kind": "object", "tab": 2, "type": "FormPortal", "container": "Portals",
		"scene": "res://components/form_portal.tscn",
		"label_key": "ed_obj_portal_ufo", "icon": "res://assets/sprites/portal_ufo.png",
		"default_props": {"target_form": "UFO", "allowed_player": "BOTH"},
	},
	{
		"id": "portal_dash", "kind": "object", "tab": 2, "type": "FormPortal", "container": "Portals",
		"scene": "res://components/form_portal.tscn",
		"label_key": "ed_obj_portal_dash", "icon": "res://assets/sprites/portal_dash.png",
		"default_props": {"target_form": "DASH", "allowed_player": "BOTH"},
	},
	{
		"id": "gravity_portal", "kind": "object", "tab": 2, "type": "GravityPortal", "container": "Portals",
		"scene": "res://components/gravity_portal.tscn",
		"label_key": "ed_obj_gravity_portal", "icon": "res://assets/sprites/gravity_portal.png",
		"default_props": {"direction_mode": 1, "target_direction": -1, "one_shot": false},
	},
	{
		"id": "pad_yellow", "kind": "object", "tab": 2, "type": "JumpPad", "container": "Mechanisms",
		"scene": "res://components/jump_pad.tscn",
		"label_key": "ed_obj_pad_yellow", "icon": "res://assets/sprites/jump_pad_yellow.png",
		"default_props": {"pad_type": 0},
	},
	{
		"id": "pad_pink", "kind": "object", "tab": 2, "type": "JumpPad", "container": "Mechanisms",
		"scene": "res://components/jump_pad.tscn",
		"label_key": "ed_obj_pad_pink", "icon": "res://assets/sprites/jump_pad_pink.png",
		"default_props": {"pad_type": 1},
	},
	{
		"id": "pad_red", "kind": "object", "tab": 2, "type": "JumpPad", "container": "Mechanisms",
		"scene": "res://components/jump_pad.tscn",
		"label_key": "ed_obj_pad_red", "icon": "res://assets/sprites/jump_pad_red.png",
		"default_props": {"pad_type": 2},
	},
	{
		"id": "orb_yellow", "kind": "object", "tab": 2, "type": "JumpOrb", "container": "Mechanisms",
		"scene": "res://components/jump_orb.tscn",
		"label_key": "ed_obj_orb_yellow", "icon": "res://assets/sprites/jump_orb_yellow.png",
		"default_props": {"orb_type": 0},
	},
	{
		"id": "orb_blue", "kind": "object", "tab": 2, "type": "JumpOrb", "container": "Mechanisms",
		"scene": "res://components/jump_orb.tscn",
		"label_key": "ed_obj_orb_blue", "icon": "res://assets/sprites/jump_orb_blue.png",
		"default_props": {"orb_type": 1},
	},
	{
		"id": "dash_orb", "kind": "object", "tab": 2, "type": "DashOrb", "container": "Mechanisms",
		"scene": "res://components/dash_orb.tscn",
		"label_key": "ed_obj_orb_dash", "icon": "res://assets/sprites/dash_orb.png",
		"default_props": {},
	},

	# --- Tab 3: Mechanisms & Goal ---
	{
		"id": "pressure_button", "kind": "object", "tab": 3, "type": "PressureButton", "container": "Mechanisms",
		"scene": "res://components/pressure_button.tscn",
		"label_key": "ed_obj_pressure_button", "icon": "res://assets/sprites/pressure_button.png",
		"default_props": {"mode": 0, "activator": 0, "pair_window": 0.5, "paired_uid": ""},
	},
	{
		"id": "mech_platform", "kind": "object", "tab": 3, "type": "MechanizedPlatform", "container": "Mechanisms",
		"scene": "res://components/mechanized_platform.tscn",
		"label_key": "ed_obj_mech_platform", "icon": "res://assets/sprites/mechanized_platform.png",
		"default_props": {"move_offset": [0.0, -96.0], "speed": 140.0, "require_all": false, "linked_uids": []},
	},
	{
		"id": "energy_gate", "kind": "object", "tab": 3, "type": "EnergyGate", "container": "Mechanisms",
		"scene": "res://components/energy_gate.tscn",
		"label_key": "ed_obj_energy_gate", "icon": "res://assets/sprites/breakable_dash_wall.png",
		"default_props": {"gate_size": [2, 3], "require_all": true, "open_time": 0.18, "linked_uids": []},
	},
	{
		"id": "breakable_wall", "kind": "object", "tab": 3, "type": "BreakableDashBlock", "container": "Mechanisms",
		"scene": "res://components/breakable_dash_block.tscn",
		"label_key": "ed_obj_breakable_wall", "icon": "res://assets/sprites/breakable_dash_wall.png",
		"default_props": {},
	},
	{
		"id": "coop_box", "kind": "object", "tab": 3, "type": "CoopBox", "container": "Mechanisms",
		"scene": "res://components/coop_box.tscn",
		"label_key": "ed_obj_coop_box", "icon": "res://assets/sprites/coop_box.png",
		"default_props": {},
	},
	{
		"id": "float_pair", "kind": "object", "tab": 3, "type": "BalancedFloatPair", "container": "Mechanisms",
		"scene": "res://components/balanced_float_pair.tscn",
		"label_key": "ed_obj_float_pair", "icon": "res://assets/sprites/coop_box.png",
		"default_props": {"horizontal_separation": 96.0, "spring_strength": 18.0, "damping": 7.0},
	},
	{
		"id": "restore_point", "kind": "object", "tab": 3, "type": "RestorePoint", "container": "Checkpoints",
		"scene": "res://components/restore_point.tscn",
		"label_key": "ed_obj_restore_point", "icon": "res://assets/sprites/restore_point.png",
		"default_props": {"checkpoint_order": 1, "require_both_players": false},
	},
	{
		"id": "dual_exit_gate", "kind": "object", "tab": 3, "type": "DualExitGate", "container": "Mechanisms",
		"scene": "res://components/dual_exit_gate.tscn",
		"label_key": "ed_obj_dual_exit_gate", "icon": "res://assets/sprites/dual_exit_gate.png",
		"default_props": {"hold_time": 0.5},
	},

	# --- Tab 4: Decorations (All 6 DecoProp variants) ---
	{
		"id": "deco_pylon", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_pylon", "icon": "res://assets/sprites/deco_pylon.png",
		"default_props": {"prop_type": 0, "flip_h": false},
	},
	{
		"id": "deco_crystals", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_crystals", "icon": "res://assets/sprites/deco_crystals.png",
		"default_props": {"prop_type": 1, "flip_h": false},
	},
	{
		"id": "deco_foliage", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_foliage", "icon": "res://assets/sprites/deco_foliage.png",
		"default_props": {"prop_type": 2, "flip_h": false},
	},
	{
		"id": "deco_vine", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_vine", "icon": "res://assets/sprites/deco_hanging_vines.png",
		"default_props": {"prop_type": 3, "flip_h": false},
	},
	{
		"id": "deco_terminal", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_terminal", "icon": "res://assets/sprites/deco_terminal.png",
		"default_props": {"prop_type": 4, "flip_h": false},
	},
	{
		"id": "deco_arrow", "kind": "object", "tab": 4, "type": "DecoProp", "container": "Decorations",
		"scene": "res://components/deco_prop.tscn",
		"label_key": "ed_obj_deco_arrow", "icon": "res://assets/sprites/deco_arrow_sign.png",
		"default_props": {"prop_type": 5, "flip_h": false},
	},
]

const TYPE_TO_SCENE := {
	"SpikeHazard": "res://components/spike_hazard.tscn",
	"LaserHazard": "res://components/laser_hazard.tscn",
	"FormPortal": "res://components/form_portal.tscn",
	"GravityPortal": "res://components/gravity_portal.tscn",
	"JumpPad": "res://components/jump_pad.tscn",
	"JumpOrb": "res://components/jump_orb.tscn",
	"DashOrb": "res://components/dash_orb.tscn",
	"PressureButton": "res://components/pressure_button.tscn",
	"MechanizedPlatform": "res://components/mechanized_platform.tscn",
	"EnergyGate": "res://components/energy_gate.tscn",
	"BreakableDashBlock": "res://components/breakable_dash_block.tscn",
	"CoopBox": "res://components/coop_box.tscn",
	"BalancedFloatPair": "res://components/balanced_float_pair.tscn",
	"RestorePoint": "res://components/restore_point.tscn",
	"DualExitGate": "res://components/dual_exit_gate.tscn",
	"DecoProp": "res://components/deco_prop.tscn",
}

const TYPE_TO_CONTAINER := {
	"SpikeHazard": "Hazards",
	"LaserHazard": "Hazards",
	"FormPortal": "Portals",
	"GravityPortal": "Portals",
	"JumpPad": "Mechanisms",
	"JumpOrb": "Mechanisms",
	"DashOrb": "Mechanisms",
	"PressureButton": "Mechanisms",
	"MechanizedPlatform": "Mechanisms",
	"EnergyGate": "Mechanisms",
	"BreakableDashBlock": "Mechanisms",
	"CoopBox": "Mechanisms",
	"BalancedFloatPair": "Mechanisms",
	"RestorePoint": "Checkpoints",
	"DualExitGate": "Mechanisms",
	"DecoProp": "Decorations",
	"ControlSign": "Root",
}


static func items_for_tab(tab_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in PALETTE_ITEMS:
		if int(item.get("tab", -1)) == tab_index:
			out.append(item)
	return out


static func find_palette_item(item_id: String) -> Dictionary:
	for item in PALETTE_ITEMS:
		if str(item.get("id", "")) == item_id:
			return item
	return {}


static func icon_for_object(obj: Dictionary) -> String:
	var obj_type := str(obj.get("type", ""))
	var props := obj.get("props", {}) as Dictionary
	match obj_type:
		"SpikeHazard":
			var ht := int(props.get("hazard_type", 0))
			if ht == 1:
				return "res://assets/sprites/spike_cyan.png"
			if ht == 2:
				return "res://assets/sprites/spike_orange.png"
			return "res://assets/sprites/spike_red.png"
		"FormPortal":
			var f := str(props.get("target_form", "CUBE")).to_lower()
			return "res://assets/sprites/portal_%s.png" % f
		"JumpPad":
			var pt := int(props.get("pad_type", 0))
			if pt == 1:
				return "res://assets/sprites/jump_pad_pink.png"
			if pt == 2:
				return "res://assets/sprites/jump_pad_red.png"
			return "res://assets/sprites/jump_pad_yellow.png"
		"JumpOrb":
			var ot := int(props.get("orb_type", 0))
			if ot == 1:
				return "res://assets/sprites/jump_orb_blue.png"
			if ot == 2:
				return "res://assets/sprites/jump_orb_pink.png"
			return "res://assets/sprites/jump_orb_yellow.png"
		"DecoProp":
			var dp := int(props.get("prop_type", 0))
			var paths := [
				"res://assets/sprites/deco_pylon.png",
				"res://assets/sprites/deco_crystals.png",
				"res://assets/sprites/deco_foliage.png",
				"res://assets/sprites/deco_hanging_vines.png",
				"res://assets/sprites/deco_terminal.png",
				"res://assets/sprites/deco_arrow_sign.png",
			]
			return paths[clampi(dp, 0, paths.size() - 1)]
	for item in PALETTE_ITEMS:
		if str(item.get("type", "")) == obj_type:
			return str(item.get("icon", ""))
	return "res://assets/sprites/coop_box.png"


static func default_level_data(level_name: String = "Custom Stage 1", cols: int = 48, rows: int = 12) -> Dictionary:
	var c := clampi(cols, 24, 120)
	var r := clampi(rows, 10, 24)
	var empty_row := " ".repeat(c)
	var floor_top := "=".repeat(c)
	var floor_fill := "#".repeat(c)
	var grid: Array[String] = []
	for y in range(r):
		if y == r - 2:
			grid.append(floor_top)
		elif y == r - 1:
			grid.append(floor_fill)
		else:
			grid.append(empty_row)
	var floor_y := float((r - 2) * 48) - 48.0
	var gate_x := float((c - 3) * 48)
	var gate_y := float((r - 2) * 48) - 56.0
	var stamp := int(Time.get_unix_time_from_system())
	return {
		"format": "gdxv2-level",
		"version": 1,
		"id": "custom_%d_%d" % [stamp, randi() % 1000],
		"name": level_name,
		"author": "Player",
		"background": "FOREST",
		"dim": 0.55,
		"start_form_p1": "CUBE",
		"start_form_p2": "CUBE",
		"grid_cols": c,
		"grid_rows": r,
		"ascii_map": grid,
		"spawn_p1": [144.0, floor_y],
		"spawn_p2": [216.0, floor_y],
		"objects": [
			{
				"uid": "goal_1",
				"type": "DualExitGate",
				"container": "Mechanisms",
				"pos": [gate_x, gate_y],
				"props": {"hold_time": 0.5},
			}
		],
	}


static func resize_ascii_map(ascii_map: Array, cols: int, rows: int) -> Array[String]:
	var c := clampi(cols, 24, 120)
	var r := clampi(rows, 10, 24)
	var out: Array[String] = []
	for y in range(r):
		var src := str(ascii_map[y]) if y < ascii_map.size() else ""
		if src.length() < c:
			src += " ".repeat(c - src.length())
		elif src.length() > c:
			src = src.substr(0, c)
		out.append(src)
	return out


static func validate_level_data(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var p1 := data.get("spawn_p1", []) as Array
	var p2 := data.get("spawn_p2", []) as Array
	if p1.size() < 2 or p2.size() < 2:
		errors.append(LocalePack.tr_key("ed_err_no_spawn"))

	var objs := data.get("objects", []) as Array
	var has_gate := false
	var unlinked := 0
	for item in objs:
		if not (item is Dictionary):
			continue
		var obj := item as Dictionary
		var t := str(obj.get("type", ""))
		var props := obj.get("props", {}) as Dictionary
		if t == "DualExitGate":
			has_gate = true
		elif t == "MechanizedPlatform" or t == "EnergyGate":
			var links := props.get("linked_uids", []) as Array
			if links.is_empty():
				unlinked += 1
		elif t == "PressureButton" and int(props.get("mode", 0)) == 2:
			if str(props.get("paired_uid", "")) == "":
				unlinked += 1

	if not has_gate:
		errors.append(LocalePack.tr_key("ed_err_no_gate"))
	if unlinked > 0:
		warnings.append(LocalePack.tr_key("ed_warn_unlinked", [unlinked]))

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
	}
