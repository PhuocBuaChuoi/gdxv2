class_name EditorCanvas
extends Control

## Interactive 2D level canvas: live auto-bordered TileMapLayer, StageBackground,
## drag-and-drop placement from Palette, object move/drag, wire linking & offset handle.

signal data_mutated(push_history: bool, reason: String)
signal selection_changed(sel_id: String)
signal hover_cell_changed(cell: Vector2i)
signal link_completed(msg: String)

const TILESET_RES := preload("res://resources/gd_neon_tileset.tres")
const BG_SCENE := preload("res://levels/stage_background.tscn")
const TEX_EMITTER := preload("res://assets/sprites/laser_emitter.png")
const TEX_COOP_BOX := preload("res://assets/sprites/coop_box.png")
const TEX_BREAKABLE := preload("res://assets/sprites/breakable_dash_wall.png")

var level_data: Dictionary = {}
var active_tool: Dictionary = {"kind": "select"} # kind: select | erase | tile | spawn | object | link
var selected_id: String = "" # "" | "spawn_p1" | "spawn_p2" | object uid
var link_source_uid: String = ""
var link_mode: String = "" # "trigger" | "pair"
var show_grid: bool = true

var _svc: SubViewportContainer
var _viewport: SubViewport
var _world: Node2D
var _bg: Node2D
var _terrain: TileMapLayer
var _objects_layer: Node2D
var _overlay: _CanvasOverlay
var _camera: Camera2D

var _painting_tile: bool = false
var _erasing_drag: bool = false
var _last_paint_cell: Vector2i = Vector2i(-999, -999)
var _dragging_obj: bool = false
var _dragging_offset_handle: bool = false
var _drag_start_snap: Vector2 = Vector2.ZERO
var _drag_changed: bool = false
var _panning: bool = false
var _hover_world: Vector2 = Vector2.ZERO
var _hover_inside: bool = false
var _drag_ghost_item: Dictionary = {}


func _ready() -> void:
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	focus_mode = Control.FOCUS_CLICK
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Wrap SubViewportContainer inside a plain Control so Godot 4 GUI drag-and-drop
	# dispatches _can_drop_data/_drop_data reliably to EditorCanvas.
	_svc = SubViewportContainer.new()
	_svc.name = "ViewportHost"
	_svc.stretch = true
	_svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_svc)

	_viewport = SubViewport.new()
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_svc.add_child(_viewport)

	_world = Node2D.new()
	_world.name = "EditorWorld"
	_viewport.add_child(_world)

	_bg = BG_SCENE.instantiate() as Node2D
	_world.add_child(_bg)

	_terrain = TileMapLayer.new()
	_terrain.tile_set = TILESET_RES
	_world.add_child(_terrain)

	_objects_layer = Node2D.new()
	_world.add_child(_objects_layer)

	_overlay = _CanvasOverlay.new()
	_overlay.canvas = self
	_world.add_child(_overlay)

	_camera = Camera2D.new()
	_camera.position = Vector2(560, 290)
	_camera.zoom = Vector2(0.85, 0.85)
	_camera.enabled = true
	_world.add_child(_camera)

	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_exited() -> void:
	_hover_inside = false
	_overlay.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not _drag_ghost_item.is_empty():
			_drag_ghost_item = {}
			if _overlay != null:
				_overlay.queue_redraw()


func load_data(data: Dictionary, reset_cam: bool = false) -> void:
	level_data = data
	if reset_cam:
		_camera.position = Vector2(560, 290)
		_camera.zoom = Vector2(0.85, 0.85)
	if selected_id != "" and selected_id != "spawn_p1" and selected_id != "spawn_p2":
		if find_object(selected_id).is_empty():
			selected_id = ""
	if link_source_uid != "" and find_object(link_source_uid).is_empty():
		link_source_uid = ""
		link_mode = ""
		if str(active_tool.get("kind", "")) == "link":
			active_tool = {"kind": "select"}
	rebuild_all()
	selection_changed.emit(selected_id)


func set_tool(tool_dict: Dictionary) -> void:
	active_tool = tool_dict.duplicate(true)
	if str(active_tool.get("kind", "")) != "link":
		link_source_uid = ""
		link_mode = ""
	if _overlay != null:
		_overlay.queue_redraw()


func start_wire_link(source_uid: String, mode_name: String) -> void:
	link_source_uid = source_uid
	link_mode = mode_name
	active_tool = {"kind": "link"}
	if _overlay != null:
		_overlay.queue_redraw()


func select_entity(ent_id: String) -> void:
	selected_id = ent_id
	selection_changed.emit(selected_id)
	if _overlay != null:
		_overlay.queue_redraw()


func update_background_dim(v: float) -> void:
	if _bg == null:
		return
	_bg.set("dim", v)
	var dim_rect := _bg.get_node_or_null("DimLayer/DimRect") as ColorRect
	if dim_rect != null:
		dim_rect.color = Color(0.01, 0.03, 0.07, clampf(v, 0.0, 0.95))
	elif _bg.has_method("apply_background"):
		_bg.call("apply_background")


func rebuild_all() -> void:
	if _bg != null:
		_bg.set("background", str(level_data.get("background", "FOREST")))
		_bg.set("dim", float(level_data.get("dim", 0.55)))
		if _bg.has_method("apply_background"):
			_bg.call("apply_background")
	_repaint_terrain()
	_rebuild_object_previews()
	if _overlay != null:
		_overlay.queue_redraw()


func _repaint_terrain() -> void:
	if _terrain == null:
		return
	_terrain.clear()
	var rows := level_data.get("ascii_map", []) as Array
	for y in range(rows.size()):
		var row := str(rows[y])
		for x in range(row.length()):
			var ch := row.substr(x, 1)
			if ch == "#" or ch == "=":
				_terrain.set_cell(Vector2i(x, y), 0, _solid_variant_at(rows, x, y))
			elif ch == "-":
				_terrain.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
			elif ch == ".":
				_terrain.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))


func _solid_variant_at(rows: Array, x: int, y: int) -> Vector2i:
	var mask := 0
	if not _is_solid(rows, x, y - 1): mask |= 1
	if not _is_solid(rows, x + 1, y): mask |= 2
	if not _is_solid(rows, x, y + 1): mask |= 4
	if not _is_solid(rows, x - 1, y): mask |= 8
	return Vector2i(0, 0) if mask == 0 else Vector2i(mask % 4, 1 + (mask >> 2))


func _is_solid(rows: Array, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size():
		return false
	var row := str(rows[y])
	if x < 0 or x >= row.length():
		return false
	var ch := row.substr(x, 1)
	return ch == "#" or ch == "="


func _rebuild_object_previews() -> void:
	if _objects_layer == null:
		return
	for c in _objects_layer.get_children():
		_objects_layer.remove_child(c)
		c.queue_free()

	for sid in ["spawn_p1", "spawn_p2"]:
		var arr := level_data.get(sid, [144.0, 384.0]) as Array
		if arr.size() >= 2:
			var marker := Node2D.new()
			marker.position = Vector2(float(arr[0]), float(arr[1]))
			var box := Polygon2D.new()
			box.polygon = PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
			box.color = Color(0.0, 0.9, 1.0, 0.35) if sid == "spawn_p1" else Color(1.0, 0.55, 0.1, 0.35)
			marker.add_child(box)
			var lbl := Label.new()
			lbl.text = "P1" if sid == "spawn_p1" else "P2"
			lbl.position = Vector2(-10, -11)
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			marker.add_child(lbl)
			_objects_layer.add_child(marker)

	for item in (level_data.get("objects", []) as Array):
		if not (item is Dictionary):
			continue
		var obj := item as Dictionary
		var pos_arr := obj.get("pos", [0.0, 0.0]) as Array
		if pos_arr.size() < 2:
			continue
		var holder := Node2D.new()
		holder.position = Vector2(float(pos_arr[0]), float(pos_arr[1]))
		_populate_preview_visual(holder, obj)
		_objects_layer.add_child(holder)


func _populate_preview_visual(holder: Node2D, obj: Dictionary) -> void:
	var obj_type := str(obj.get("type", ""))
	var props := obj.get("props", {}) as Dictionary

	if obj_type == "ControlSign":
		var lbl := Label.new()
		lbl.text = str(props.get("text", "P1 & P2 CO-OP!"))
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.35, 0.93, 1.0, 0.92))
		holder.add_child(lbl)
		return

	if obj_type == "EnergyGate":
		var gs := props.get("gate_size", [2, 3]) as Array
		var w := float(gs[0]) * 48.0 if gs.size() >= 2 else 96.0
		var h := float(gs[1]) * 48.0 if gs.size() >= 2 else 144.0
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5), Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5)])
		poly.color = Color(0.08, 0.52, 0.66, 0.55)
		holder.add_child(poly)
		return

	if obj_type == "LaserHazard":
		var ht := int(props.get("hazard_type", 0))
		var col := Color(1, 0.25, 0.35, 0.8) if ht == 0 else (Color(0.2, 0.9, 1, 0.8) if ht == 1 else Color(1, 0.55, 0.1, 0.8))
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([Vector2(-10, -60), Vector2(10, -60), Vector2(10, 60), Vector2(-10, 60)])
		beam.color = col
		holder.add_child(beam)
		for ey in [-58.0, 58.0]:
			var em := Sprite2D.new()
			em.texture = TEX_EMITTER
			em.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			em.position = Vector2(0.0, ey)
			holder.add_child(em)
		return

	if obj_type == "BreakableDashBlock":
		var bs := props.get("block_size", [1, 3]) as Array
		var bx_count := maxi(1, int(bs[0])) if bs.size() >= 2 else 1
		var by_count := maxi(1, int(bs[1])) if bs.size() >= 2 else 3
		var half_w := float(bx_count) * 24.0
		var half_h := float(by_count) * 24.0
		for bx in range(bx_count):
			for by in range(by_count):
				var spr := Sprite2D.new()
				spr.texture = TEX_BREAKABLE
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.position = Vector2(-half_w + float(bx) * 48.0 + 24.0, -half_h + float(by) * 48.0 + 24.0)
				holder.add_child(spr)
		return

	if obj_type == "BalancedFloatPair":
		var sep := float(props.get("horizontal_separation", 96.0))
		var half_sep := maxf(24.0, sep * 0.5)
		var bar := Line2D.new()
		bar.points = PackedVector2Array([Vector2(-half_sep, 0), Vector2(half_sep, 0)])
		bar.width = 4.0
		bar.default_color = Color(0.3, 0.95, 1.0, 0.85)
		holder.add_child(bar)
		for ox in [-half_sep, half_sep]:
			var spr := Sprite2D.new()
			spr.texture = TEX_COOP_BOX
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.position = Vector2(ox, 0.0)
			holder.add_child(spr)
		return

	if obj_type == "SpikeHazard":
		var count := maxi(1, int(props.get("tile_count", 2)))
		var ori := int(props.get("orientation", 0))
		holder.rotation = [0.0, PI, -PI * 0.5, PI * 0.5][clampi(ori, 0, 3)]
		var icon_path := CustomLevelCatalog.icon_for_object(obj)
		var tex := load(icon_path) as Texture2D
		var start_x := -(float(count - 1) * 48.0) * 0.5
		for i in range(count):
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.position = Vector2(start_x + float(i) * 48.0, -12.0)
			holder.add_child(spr)
		return

	var obj_icon := CustomLevelCatalog.icon_for_object(obj)
	if obj_icon != "" and ResourceLoader.exists(obj_icon):
		var spr := Sprite2D.new()
		spr.texture = load(obj_icon) as Texture2D
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if obj_type == "JumpPad":
			spr.scale = Vector2(0.55, 0.55)
			spr.position = Vector2(0, -6)
		elif obj_type == "JumpOrb" or obj_type == "DashOrb":
			spr.scale = Vector2(0.48, 0.48)
		elif obj_type == "DualExitGate":
			spr.scale = Vector2(0.65, 0.65)
			spr.position = Vector2(0, -6)
		elif obj_type == "DecoProp":
			var pt := int(props.get("prop_type", 0))
			var offsets := {0: Vector2(0, -48), 1: Vector2(0, -24), 2: Vector2(0, -16), 3: Vector2(0, 32), 4: Vector2(0, -32), 5: Vector2(0, -24)}
			spr.position = offsets.get(pt, Vector2.ZERO)
			spr.flip_h = bool(props.get("flip_h", false))
		holder.add_child(spr)


func screen_to_world(local_pos: Vector2) -> Vector2:
	if _camera == null:
		return local_pos
	return _camera.position + (local_pos - size * 0.5) / _camera.zoom


func snap_pos(world_pos: Vector2, fine: bool = false) -> Vector2:
	var step := 12.0 if fine else 24.0
	return Vector2(roundf(world_pos.x / step) * step, roundf(world_pos.y / step) * step)


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / 48.0), floori(world_pos.y / 48.0))


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and bool((data as Dictionary).get("from_palette", false)):
		_hover_inside = true
		_hover_world = screen_to_world(at_position)
		_drag_ghost_item = (data as Dictionary).get("item", {}) as Dictionary
		if _overlay != null:
			_overlay.queue_redraw()
		return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_drag_ghost_item = {}
	if not (data is Dictionary) or not bool((data as Dictionary).get("from_palette", false)):
		return
	var item := (data as Dictionary).get("item", {}) as Dictionary
	var world_pos := screen_to_world(at_position)
	place_palette_item(item, world_pos, Input.is_key_pressed(KEY_SHIFT))


func place_palette_item(item: Dictionary, world_pos: Vector2, fine: bool = false) -> void:
	var kind := str(item.get("kind", ""))
	if kind == "tile":
		var cell := world_to_cell(world_pos)
		if _paint_cell(cell, str(item.get("char", "="))):
			_repaint_terrain()
			data_mutated.emit(true, "paint_tile")
		return
	var pos := snap_pos(world_pos, fine)
	if kind == "spawn":
		var sid := "spawn_p1" if int(item.get("spawn_id", 1)) == 1 else "spawn_p2"
		level_data[sid] = [pos.x, pos.y]
		select_entity(sid)
		_rebuild_object_previews()
		data_mutated.emit(true, "move_spawn")
		return
	if kind == "object":
		var new_obj := create_object_entry(item, pos)
		(level_data["objects"] as Array).append(new_obj)
		select_entity(str(new_obj["uid"]))
		_rebuild_object_previews()
		data_mutated.emit(true, "add_object")


func _generate_unique_uid(type_name: String) -> String:
	var prefix := type_name.to_lower()
	for _attempt in range(100):
		var candidate := "%s_%d_%d" % [prefix, Time.get_ticks_msec() % 100000, randi() % 9999]
		if find_object(candidate).is_empty():
			return candidate
	return "%s_%d" % [prefix, Time.get_ticks_usec()]


func _next_checkpoint_order() -> int:
	var max_order := 0
	for item in (level_data.get("objects", []) as Array):
		if item is Dictionary and str((item as Dictionary).get("type", "")) == "RestorePoint":
			var props := (item as Dictionary).get("props", {}) as Dictionary
			max_order = maxi(max_order, int(props.get("checkpoint_order", 1)))
	return max_order + 1


func create_object_entry(item: Dictionary, pos: Vector2) -> Dictionary:
	var t := str(item.get("type", "CoopBox"))
	var uid := _generate_unique_uid(t)
	var props := (item.get("default_props", {}) as Dictionary).duplicate(true)
	if t == "RestorePoint":
		props["checkpoint_order"] = _next_checkpoint_order()
	return {
		"uid": uid,
		"type": t,
		"container": str(item.get("container", CustomLevelCatalog.TYPE_TO_CONTAINER.get(t, "Mechanisms"))),
		"pos": [pos.x, pos.y],
		"props": props,
	}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_hover_inside = true
		_hover_world = screen_to_world(mm.position)
		hover_cell_changed.emit(world_to_cell(_hover_world))
		if _panning:
			_camera.position -= mm.relative / _camera.zoom
			_overlay.queue_redraw()
			return
		if _painting_tile:
			var cell := world_to_cell(_hover_world)
			if cell != _last_paint_cell:
				_last_paint_cell = cell
				var ch := " " if _erasing_drag else str(active_tool.get("char", "="))
				if _paint_cell(cell, ch):
					_repaint_terrain()
					_drag_changed = true
		elif _dragging_offset_handle:
			var sel := find_object(selected_id)
			if not sel.is_empty():
				var pos_arr := sel.get("pos", [0.0, 0.0]) as Array
				var base := Vector2(float(pos_arr[0]), float(pos_arr[1]))
				var target := snap_pos(_hover_world, mm.shift_pressed)
				var off := target - base
				(sel["props"] as Dictionary)["move_offset"] = [off.x, off.y]
				_drag_changed = true
				_overlay.queue_redraw()
		elif _dragging_obj:
			var snapped := snap_pos(_hover_world, mm.shift_pressed)
			if snapped != _drag_start_snap:
				_drag_start_snap = snapped
				_set_entity_pos(selected_id, snapped)
				_rebuild_object_previews()
				_drag_changed = true
		_overlay.queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		_hover_world = screen_to_world(mb.position)
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(1.12, mb.position)
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(1.0 / 1.12, mb.position)
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not mb.pressed and _panning:
				_panning = false
				return
			if mb.pressed and Input.is_key_pressed(KEY_SPACE):
				grab_focus()
				_panning = true
				return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_handle_right_click(_hover_world)
			else:
				if _painting_tile and _drag_changed:
					data_mutated.emit(true, "erase_tiles")
				_painting_tile = false
				_erasing_drag = false
				_drag_changed = false
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				grab_focus()
				_handle_left_down(_hover_world, mb.shift_pressed)
			else:
				_handle_left_up()


func _zoom_by(factor: float, cursor_local: Vector2) -> void:
	var before := screen_to_world(cursor_local)
	var new_z := clampf(_camera.zoom.x * factor, 0.4, 2.0)
	_camera.zoom = Vector2(new_z, new_z)
	var after := screen_to_world(cursor_local)
	_camera.position += before - after
	_overlay.queue_redraw()


func _handle_left_down(world_pos: Vector2, fine: bool) -> void:
	var kind := str(active_tool.get("kind", "select"))
	if kind == "link":
		var hit_uid := _pick_entity_at(world_pos)
		if hit_uid != "" and hit_uid != "spawn_p1" and hit_uid != "spawn_p2":
			_complete_wire_link(hit_uid)
		return
	if kind == "tile":
		_painting_tile = true
		_erasing_drag = false
		_drag_changed = false
		var cell := world_to_cell(world_pos)
		_last_paint_cell = cell
		if _paint_cell(cell, str(active_tool.get("char", "="))):
			_repaint_terrain()
			_drag_changed = true
		return
	if kind == "erase":
		var hit := _pick_entity_at(world_pos)
		if hit != "" and hit != "spawn_p1" and hit != "spawn_p2":
			delete_object(hit)
		else:
			_painting_tile = true
			_erasing_drag = true
			_drag_changed = false
			var cell := world_to_cell(world_pos)
			_last_paint_cell = cell
			if _paint_cell(cell, " "):
				_repaint_terrain()
				_drag_changed = true
		return
	if kind == "spawn" or kind == "object":
		place_palette_item(active_tool, world_pos, fine)
		return

	if _is_near_offset_handle(world_pos):
		_dragging_offset_handle = true
		_drag_changed = false
		return

	var hit_id := _pick_entity_at(world_pos)
	select_entity(hit_id)
	if hit_id != "":
		_dragging_obj = true
		_drag_changed = false
		_drag_start_snap = _get_entity_pos(hit_id)


func _handle_left_up() -> void:
	if _painting_tile and _drag_changed:
		data_mutated.emit(true, "paint_tiles")
	elif _dragging_obj and _drag_changed:
		data_mutated.emit(true, "move_object")
		selection_changed.emit(selected_id)
	elif _dragging_offset_handle and _drag_changed:
		data_mutated.emit(true, "move_offset")
		selection_changed.emit(selected_id)
	_painting_tile = false
	_erasing_drag = false
	_dragging_obj = false
	_dragging_offset_handle = false
	_drag_changed = false


func _handle_right_click(world_pos: Vector2) -> void:
	if str(active_tool.get("kind", "")) == "link":
		set_tool({"kind": "select"})
		link_completed.emit("cancelled")
		return
	var hit := _pick_entity_at(world_pos)
	if hit != "" and hit != "spawn_p1" and hit != "spawn_p2":
		delete_object(hit)
		return
	_painting_tile = true
	_erasing_drag = true
	_drag_changed = false
	var cell := world_to_cell(world_pos)
	_last_paint_cell = cell
	if _paint_cell(cell, " "):
		_repaint_terrain()
		_drag_changed = true


func _complete_wire_link(target_uid: String) -> void:
	var src := find_object(link_source_uid)
	var dst := find_object(target_uid)
	if src.is_empty() or dst.is_empty() or target_uid == link_source_uid:
		return
	var dst_type := str(dst.get("type", ""))
	if link_mode == "trigger" and dst_type == "PressureButton":
		var props := src["props"] as Dictionary
		var links := props.get("linked_uids", []) as Array
		if links.has(target_uid):
			links.erase(target_uid)
		else:
			links.append(target_uid)
		props["linked_uids"] = links
		active_tool = {"kind": "select"}
		link_source_uid = ""
		link_mode = ""
		_overlay.queue_redraw()
		data_mutated.emit(true, "link_trigger")
		selection_changed.emit(selected_id)
		link_completed.emit("linked")
	elif link_mode == "pair" and dst_type == "PressureButton":
		var src_props := src["props"] as Dictionary
		var dst_props := dst["props"] as Dictionary
		var src_uid := str(src.get("uid", ""))
		var old_src_partner := str(src_props.get("paired_uid", ""))
		var old_dst_partner := str(dst_props.get("paired_uid", ""))
		if old_src_partner == target_uid:
			src_props["paired_uid"] = ""
			dst_props["paired_uid"] = ""
		else:
			if old_src_partner != "":
				var op_a := find_object(old_src_partner)
				if not op_a.is_empty():
					(op_a["props"] as Dictionary)["paired_uid"] = ""
			if old_dst_partner != "" and old_dst_partner != src_uid:
				var op_b := find_object(old_dst_partner)
				if not op_b.is_empty():
					(op_b["props"] as Dictionary)["paired_uid"] = ""
			src_props["paired_uid"] = target_uid
			dst_props["paired_uid"] = src_uid
		active_tool = {"kind": "select"}
		link_source_uid = ""
		link_mode = ""
		_overlay.queue_redraw()
		data_mutated.emit(true, "pair_buttons")
		selection_changed.emit(selected_id)
		link_completed.emit("paired")


func _paint_cell(cell: Vector2i, ch: String) -> bool:
	var rows := level_data.get("ascii_map", []) as Array
	if cell.y < 0 or cell.y >= rows.size():
		return false
	var row := str(rows[cell.y])
	if cell.x < 0 or cell.x >= row.length():
		return false
	if row.substr(cell.x, 1) == ch:
		return false
	rows[cell.y] = row.substr(0, cell.x) + ch + row.substr(cell.x + 1)
	return true


func _get_object_local_rect(obj: Dictionary) -> Rect2:
	var t := str(obj.get("type", ""))
	var props := obj.get("props", {}) as Dictionary
	match t:
		"SpikeHazard":
			var count := maxi(1, int(props.get("tile_count", 2)))
			var raw := Rect2(-float(count) * 24.0, -34.0, float(count) * 48.0, 44.0)
			var ori := clampi(int(props.get("orientation", 0)), 0, 3)
			var ang: float = [0.0, PI, -PI * 0.5, PI * 0.5][ori]
			if is_zero_approx(ang):
				return raw
			var corners := [
				raw.position.rotated(ang),
				Vector2(raw.end.x, raw.position.y).rotated(ang),
				raw.end.rotated(ang),
				Vector2(raw.position.x, raw.end.y).rotated(ang),
			]
			var box := Rect2(corners[0], Vector2.ZERO)
			for c in corners:
				box = box.expand(c)
			return box
		"EnergyGate":
			var gs := props.get("gate_size", [2, 3]) as Array
			var w := float(gs[0]) * 48.0 if gs.size() >= 2 else 96.0
			var h := float(gs[1]) * 48.0 if gs.size() >= 2 else 144.0
			return Rect2(-w * 0.5, -h * 0.5, w, h)
		"BreakableDashBlock":
			var bs := props.get("block_size", [1, 3]) as Array
			var bw := float(bs[0]) * 48.0 if bs.size() >= 2 else 48.0
			var bh := float(bs[1]) * 48.0 if bs.size() >= 2 else 144.0
			return Rect2(-bw * 0.5, -bh * 0.5, bw, bh)
		"BalancedFloatPair":
			var sep := float(props.get("horizontal_separation", 96.0))
			var total_w := maxf(96.0, sep + 48.0)
			return Rect2(-total_w * 0.5, -24.0, total_w, 48.0)
		"DualExitGate":
			return Rect2(-96.0, -64.0, 192.0, 116.0)
		"LaserHazard":
			return Rect2(-22.0, -70.0, 44.0, 140.0)
		"MechanizedPlatform":
			return Rect2(-52.0, -18.0, 104.0, 36.0)
		"FormPortal", "GravityPortal":
			return Rect2(-32.0, -48.0, 64.0, 96.0)
		"ControlSign":
			var txt := str(props.get("text", "P1 & P2 CO-OP!"))
			var tw := clampf(float(txt.length()) * 9.0, 96.0, 360.0)
			return Rect2(-8.0, -14.0, tw, 36.0)
		"DecoProp":
			var pt := int(props.get("prop_type", 0))
			if pt == 0:
				return Rect2(-24.0, -96.0, 48.0, 96.0)
			if pt == 3:
				return Rect2(-24.0, 0.0, 48.0, 64.0)
			if pt == 4:
				return Rect2(-28.0, -64.0, 56.0, 64.0)
			return Rect2(-24.0, -48.0, 48.0, 48.0)
		"PressureButton":
			return Rect2(-26.0, -24.0, 52.0, 28.0)
		_:
			return Rect2(-28.0, -28.0, 56.0, 56.0)


func _pick_entity_at(world_pos: Vector2) -> String:
	var objs := level_data.get("objects", []) as Array
	for i in range(objs.size() - 1, -1, -1):
		var obj := objs[i] as Dictionary
		var pos_arr := obj.get("pos", [0.0, 0.0]) as Array
		if pos_arr.size() >= 2:
			var p := Vector2(float(pos_arr[0]), float(pos_arr[1]))
			var r := _get_object_local_rect(obj).grow(6.0)
			r.position += p
			if r.has_point(world_pos):
				return str(obj.get("uid", ""))
	for sid in ["spawn_p2", "spawn_p1"]:
		var arr := level_data.get(sid, []) as Array
		if arr.size() >= 2:
			if world_pos.distance_to(Vector2(float(arr[0]), float(arr[1]))) <= 28.0:
				return sid
	return ""


func _is_near_offset_handle(world_pos: Vector2) -> bool:
	var obj := find_object(selected_id)
	if obj.is_empty() or str(obj.get("type", "")) != "MechanizedPlatform":
		return false
	var p := _get_entity_pos(selected_id)
	var off := (obj["props"] as Dictionary).get("move_offset", [0.0, -96.0]) as Array
	if off.size() < 2:
		return false
	var target := p + Vector2(float(off[0]), float(off[1]))
	return world_pos.distance_to(target) <= 22.0


func find_object(uid: String) -> Dictionary:
	for item in (level_data.get("objects", []) as Array):
		if item is Dictionary and str((item as Dictionary).get("uid", "")) == uid:
			return item as Dictionary
	return {}


func _get_entity_pos(ent_id: String) -> Vector2:
	if ent_id == "spawn_p1" or ent_id == "spawn_p2":
		var arr := level_data.get(ent_id, [0.0, 0.0]) as Array
		return Vector2(float(arr[0]), float(arr[1])) if arr.size() >= 2 else Vector2.ZERO
	var obj := find_object(ent_id)
	if not obj.is_empty():
		var arr := obj.get("pos", [0.0, 0.0]) as Array
		return Vector2(float(arr[0]), float(arr[1])) if arr.size() >= 2 else Vector2.ZERO
	return Vector2.ZERO


func _set_entity_pos(ent_id: String, p: Vector2) -> void:
	if ent_id == "spawn_p1" or ent_id == "spawn_p2":
		level_data[ent_id] = [p.x, p.y]
		return
	var obj := find_object(ent_id)
	if not obj.is_empty():
		obj["pos"] = [p.x, p.y]


func delete_object(uid: String) -> bool:
	if uid == "" or uid == "spawn_p1" or uid == "spawn_p2":
		return false
	var objs := level_data.get("objects", []) as Array
	for i in range(objs.size()):
		if str((objs[i] as Dictionary).get("uid", "")) == uid:
			objs.remove_at(i)
			for other in objs:
				var props := (other as Dictionary).get("props", {}) as Dictionary
				if props.has("linked_uids") and props["linked_uids"] is Array:
					(props["linked_uids"] as Array).erase(uid)
				if str(props.get("paired_uid", "")) == uid:
					props["paired_uid"] = ""
			if link_source_uid == uid:
				set_tool({"kind": "select"})
				link_completed.emit("cancelled")
			if selected_id == uid:
				select_entity("")
			_rebuild_object_previews()
			data_mutated.emit(true, "delete_object")
			return true
	return false


func duplicate_selected() -> bool:
	var obj := find_object(selected_id)
	if obj.is_empty():
		return false
	var copy := obj.duplicate(true)
	var t := str(copy.get("type", "Obj"))
	copy["uid"] = _generate_unique_uid(t)
	var props := copy.get("props", {}) as Dictionary
	if t == "PressureButton" and props.has("paired_uid"):
		props["paired_uid"] = ""
	if t == "RestorePoint":
		props["checkpoint_order"] = _next_checkpoint_order()
	var p := _get_entity_pos(selected_id) + Vector2(48.0, 0.0)
	copy["pos"] = [p.x, p.y]
	(level_data["objects"] as Array).append(copy)
	select_entity(str(copy["uid"]))
	_rebuild_object_previews()
	data_mutated.emit(true, "duplicate_object")
	return true


func rotate_selected() -> bool:
	var obj := find_object(selected_id)
	if obj.is_empty():
		return false
	var t := str(obj.get("type", ""))
	var props := obj["props"] as Dictionary
	if t == "SpikeHazard":
		props["orientation"] = (int(props.get("orientation", 0)) + 1) % 4
	elif t == "DecoProp":
		props["flip_h"] = not bool(props.get("flip_h", false))
	else:
		return false
	_rebuild_object_previews()
	data_mutated.emit(true, "rotate_object")
	selection_changed.emit(selected_id)
	return true


class _CanvasOverlay extends Node2D:
	var canvas: EditorCanvas

	func _draw() -> void:
		if canvas == null or canvas.level_data.is_empty():
			return
		var cols := int(canvas.level_data.get("grid_cols", 48))
		var rows := int(canvas.level_data.get("grid_rows", 12))
		var w := float(cols) * 48.0
		var h := float(rows) * 48.0

		if canvas.show_grid:
			var grid_col := Color(0.28, 0.72, 0.95, 0.16)
			for x in range(cols + 1):
				draw_line(Vector2(x * 48.0, 0.0), Vector2(x * 48.0, h), grid_col, 1.0)
			for y in range(rows + 1):
				draw_line(Vector2(0.0, y * 48.0), Vector2(w, y * 48.0), grid_col, 1.0)

		draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.25, 0.92, 1.0, 0.65), false, 2.0)

		for item in (canvas.level_data.get("objects", []) as Array):
			if not (item is Dictionary):
				continue
			var obj := item as Dictionary
			var t := str(obj.get("type", ""))
			var props := obj.get("props", {}) as Dictionary
			var p_arr := obj.get("pos", [0.0, 0.0]) as Array
			if p_arr.size() < 2:
				continue
			var src_pos := Vector2(float(p_arr[0]), float(p_arr[1]))
			if t == "MechanizedPlatform" or t == "EnergyGate":
				for luid in (props.get("linked_uids", []) as Array):
					var dst := canvas.find_object(str(luid))
					if not dst.is_empty():
						var dpos := canvas._get_entity_pos(str(luid))
						draw_line(dpos, src_pos, Color(0.25, 1.0, 0.55, 0.85), 2.5)
						draw_circle(dpos, 5.0, Color(0.25, 1.0, 0.55, 0.95))
			elif t == "PressureButton" and str(props.get("paired_uid", "")) != "":
				var partner := str(props.get("paired_uid", ""))
				if str(obj.get("uid", "")) < partner:
					var dpos := canvas._get_entity_pos(partner)
					draw_dashed_line(src_pos, dpos, Color(1.0, 0.35, 0.9, 0.85), 2.0, 8.0)

		if str(canvas.active_tool.get("kind", "")) == "link" and canvas.link_source_uid != "":
			var lp := canvas._get_entity_pos(canvas.link_source_uid)
			draw_circle(lp, 18.0, Color(0.2, 0.95, 1.0, 0.35))
			if canvas._hover_inside:
				var line_col := Color(1.0, 0.35, 0.9, 0.9) if canvas.link_mode == "pair" else Color(0.25, 1.0, 0.55, 0.9)
				draw_dashed_line(lp, canvas._hover_world, line_col, 2.5, 8.0)

		if canvas.selected_id != "":
			var sp := canvas._get_entity_pos(canvas.selected_id)
			var sel_obj := canvas.find_object(canvas.selected_id)
			var sel_rect := Rect2(-26, -26, 52, 52) if sel_obj.is_empty() else canvas._get_object_local_rect(sel_obj)
			sel_rect.position += sp
			draw_rect(sel_rect, Color(1.0, 0.85, 0.2, 0.95), false, 2.5)
			if not sel_obj.is_empty() and str(sel_obj.get("type", "")) == "MechanizedPlatform":
				var off := (sel_obj["props"] as Dictionary).get("move_offset", [0.0, -96.0]) as Array
				if off.size() >= 2:
					var dst := sp + Vector2(float(off[0]), float(off[1]))
					draw_dashed_line(sp, dst, Color(0.25, 0.95, 1.0, 0.9), 2.0, 6.0)
					draw_rect(Rect2(dst - Vector2(48, 12), Vector2(96, 24)), Color(0.25, 0.95, 1.0, 0.3), true)
					draw_circle(dst, 8.0, Color(1.0, 0.85, 0.2, 0.95))

		var preview_item: Dictionary = canvas._drag_ghost_item if not canvas._drag_ghost_item.is_empty() else canvas.active_tool
		if canvas._hover_inside and not preview_item.is_empty():
			var pkind := str(preview_item.get("kind", ""))
			if pkind == "tile" or pkind == "erase":
				var c := canvas.world_to_cell(canvas._hover_world)
				var col := Color(1, 0.3, 0.3, 0.35) if pkind == "erase" else Color(0.2, 0.95, 1.0, 0.35)
				draw_rect(Rect2(Vector2(c.x * 48.0, c.y * 48.0), Vector2(48, 48)), col, true)
			elif pkind == "object" or pkind == "spawn":
				var snapped := canvas.snap_pos(canvas._hover_world, Input.is_key_pressed(KEY_SHIFT))
				draw_rect(Rect2(snapped - Vector2(24, 24), Vector2(48, 48)), Color(0.3, 1.0, 0.65, 0.32), true)
				draw_rect(Rect2(snapped - Vector2(24, 24), Vector2(48, 48)), Color(0.3, 1.0, 0.65, 0.9), false, 2.0)
