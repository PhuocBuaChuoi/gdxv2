extends Node

## T1.10 — Signal Bus toàn cục (Autoload: Events).
## Mọi giao tiếp chết / checkpoint / đổi dạng / về đích đi qua đây
## để tránh tham chiếu chéo giữa player, level và UI.

signal player_died(player_id: int, death_pos: Vector2)
signal checkpoint_activated(checkpoint_id: int, spawn_p1: Vector2, spawn_p2: Vector2)
signal player_form_changed(player_id: int, new_form: StringName)
signal player_entered_goal(player_id: int)
signal player_exited_goal(player_id: int)
signal level_completed(level_index: int, deaths: int, time_taken: float)
