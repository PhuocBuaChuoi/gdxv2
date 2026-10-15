class_name StateMachine
extends RefCounted


## T4.01 - Factory manager cho tất cả PlayerFormState subclasses.
## Singleton factory pattern, tạo state mới mỗi khi transition hoặc reuse nếu cần.


func get_cube_state(player: GdxPlayer, prev: PlayerFormState) -> CubeState:
	"""Return CubeState instance."""
	var state := CubeState.new()
	state.enter(player, prev)
	return state


func get_ship_state(player: GdxPlayer, prev: PlayerFormState) -> ShipState:
	"""Return ShipState instance."""
	var state := ShipState.new()
	state.enter(player, prev)
	return state


func get_ufo_state(player: GdxPlayer, prev: PlayerFormState) -> UfoState:
	"""Return UFOState instance."""
	var state := UfoState.new()
	state.enter(player, prev)
	return state


func get_dash_state(player: GdxPlayer, prev: PlayerFormState) -> DashState:
	"""Return DashState instance."""
	var state := DashState.new()
	state.enter(player, prev)
	return state
