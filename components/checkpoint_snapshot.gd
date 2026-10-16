class_name CheckpointSnapshot
extends RefCounted

## T5.02 — Immutable-ish state captured for both co-op players.
var spawn_pos_p1: Vector2 = Vector2.ZERO
var spawn_pos_p2: Vector2 = Vector2.ZERO
var form_p1: StringName = &"CUBE"
var form_p2: StringName = &"CUBE"
var gravity_p1: int = 1
var gravity_p2: int = 1
var checkpoint_order: int = -1

static func from_players(p1: GdxPlayer, p2: GdxPlayer) -> CheckpointSnapshot:
	return from_players_at(p1, p2, p1.global_position, p2.global_position)

static func from_players_at(p1: GdxPlayer, p2: GdxPlayer, spawn_p1: Vector2, spawn_p2: Vector2) -> CheckpointSnapshot:
	var snapshot := CheckpointSnapshot.new()
	snapshot.spawn_pos_p1 = spawn_p1
	snapshot.spawn_pos_p2 = spawn_p2
	snapshot.form_p1 = p1.form
	snapshot.form_p2 = p2.form
	snapshot.gravity_p1 = p1.gravity_direction
	snapshot.gravity_p2 = p2.gravity_direction
	return snapshot
