class_name DualExitGate
extends Area2D

## T6.10 — Cổng Đích Đôi: khi CẢ HAI player cùng đứng trong vùng cổng
## đủ `hold_time` (mặc định 0.5s) → khoá input và phát
## `Events.level_completed(level_index, deaths, time_taken)`.
## Thiết kế Neon Cyber Portal: Vòng tròn Synergy, làn sóng năng lượng,
## trụ phát sáng theo từng player, thanh nạp năng lượng khi cùng vào cổng.

@export var hold_time: float = 0.5

var _inside: Dictionary = {}
var _timer: float = 0.0
var _done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	var arch := get_node_or_null("Arch") as Line2D
	var arch_glow := get_node_or_null("ArchGlow") as Line2D
	var post_l := get_node_or_null("PostLeft") as Polygon2D
	var post_r := get_node_or_null("PostRight") as Polygon2D
	var ring := get_node_or_null("SynergyRing") as Line2D
	var wave1 := get_node_or_null("WaveLine1") as Line2D
	var wave2 := get_node_or_null("WaveLine2") as Line2D
	var portal_field := get_node_or_null("PortalField") as Polygon2D
	var charge_bar := get_node_or_null("ChargeBar") as Line2D
	var crest := get_node_or_null("DiamondCrest") as Polygon2D
	
	var now := Time.get_ticks_msec() / 1000.0
	var both := both_inside()
	
	# 1. Arch pulse
	if arch != null:
		if both:
			var fast_pulse := 0.7 + 0.3 * sin(now * 16.0)
			arch.default_color = Color(1.0, 1.0, 0.4, fast_pulse)
		else:
			var slow_pulse := 0.5 + 0.4 * sin(now * 3.5)
			arch.default_color = Color(1.0, 1.0, 1.0, slow_pulse)
	
	if arch_glow != null:
		arch_glow.default_color.a = 0.55 + 0.35 * sin(now * (14.0 if both else 4.0))
		if both:
			arch_glow.default_color = Color(1.0, 0.85, 0.2, arch_glow.default_color.a)
		else:
			arch_glow.default_color = Color(0.4, 0.9, 1.0, arch_glow.default_color.a)
	
	# 2. Pillars brightness based on player occupancy
	if post_l != null:
		var has_p1: bool = _inside.has(1)
		post_l.color.a = 0.98 if has_p1 else (0.65 + 0.20 * sin(now * 3.0))
	if post_r != null:
		var has_p2: bool = _inside.has(2)
		post_r.color.a = 0.98 if has_p2 else (0.65 + 0.20 * sin(now * 3.0 + 1.0))
	
	# 3. Synergy Ring rotation & scale
	if ring != null:
		var spin_speed: float = 7.0 if both else 1.8
		ring.rotation += delta * spin_speed
		var base_scale: float = 1.0 + (0.35 * (_timer / maxf(hold_time, 0.01)) if both else 0.08 * sin(now * 4.0))
		ring.scale = Vector2(base_scale, base_scale)
		if both:
			ring.default_color = Color(1.0, 0.95, 0.4, 0.85 + 0.15 * sin(now * 20.0))
		else:
			ring.default_color = Color(1.0, 1.0, 1.0, 0.35 + 0.2 * sin(now * 3.0))
	
	# 4. Energy Waves oscillation
	if wave1 != null:
		wave1.position.y = 12.0 + 10.0 * sin(now * 3.5)
		wave1.default_color.a = 0.3 + 0.25 * sin(now * 4.0)
	if wave2 != null:
		wave2.position.y = -12.0 + 10.0 * cos(now * 3.5)
		wave2.default_color.a = 0.3 + 0.25 * cos(now * 4.0)
	
	# 5. Portal field glow
	if portal_field != null:
		if both:
			portal_field.color = Color(1.0, 0.85, 0.3, 0.40 + 0.15 * sin(now * 18.0))
		else:
			portal_field.color = Color(0.25, 0.75, 1.0, 0.18 + 0.08 * sin(now * 3.0))
	
	# 6. Charge Progress Bar
	if charge_bar != null:
		if both and _timer > 0.0:
			charge_bar.visible = true
			var prog: float = clampf(_timer / maxf(hold_time, 0.01), 0.0, 1.0)
			var w: float = prog * 50.0
			charge_bar.points = PackedVector2Array([Vector2(-w, 53.0), Vector2(w, 53.0)])
			charge_bar.default_color = Color(1.0, 0.95, 0.3, 0.95)
		else:
			charge_bar.visible = false
	
	# 7. Crest pulsation
	if crest != null:
		var c_scale: float = 1.0 + 0.15 * sin(now * 5.0)
		crest.scale = Vector2(c_scale, c_scale)


func reset() -> void:
	_inside.clear()
	_timer = 0.0
	_done = false


func both_inside() -> bool:
	return _inside.has(1) and _inside.has(2)


func is_done() -> bool:
	return _done


func _on_body_entered(body: Node2D) -> void:
	var pid := _player_id(body)
	if pid > 0:
		_inside[pid] = true


func _on_body_exited(body: Node2D) -> void:
	var pid := _player_id(body)
	if pid > 0:
		_inside.erase(pid)
		_timer = 0.0


func _physics_process(delta: float) -> void:
	if _done:
		return
	if both_inside():
		_timer += delta
		if _timer >= hold_time:
			_complete()
	else:
		_timer = 0.0


func _player_id(body: Node2D) -> int:
	var v: Variant = body.get("player_id")
	return int(v) if v is int and int(v) > 0 else 0


func _find_level_root() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("get_player_positions"):
			return node
		node = node.get_parent()
	return null


func _complete() -> void:
	_done = true
	var level_index := 0
	var time_taken := 0.0
	var death_count := 0
	var lvl := _find_level_root()
	if lvl != null:
		level_index = int(lvl.get("level_index"))
		time_taken = float(lvl.get("level_time"))
		death_count = int(lvl.get("deaths"))
	_lock_players(lvl)
	AudioManager.play_sfx("win")
	Events.level_completed.emit(level_index, death_count, time_taken)


func _lock_players(lvl: Node) -> void:
	if lvl == null:
		return
	var players := lvl.get_node_or_null("Players")
	if players == null:
		return
	for p in players.get_children():
		if p.has_method("set_control_locked"):
			p.call("set_control_locked", true)
