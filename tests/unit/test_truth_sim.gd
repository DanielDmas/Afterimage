extends AfterimageTestCase


## As in test_event_bus.gd / test_game_state_store.gd: event payloads are
## captured via a bound-method Callable on a helper class, not a lambda
## mutating a captured local, to avoid GDScript's by-value closure capture
## of primitives producing a false failure.
class _EventLogger:
	var events: Array = []

	func handle(event: Dictionary) -> void:
		events.append(event)


func test_constructor_spawns_player_at_start_position() -> void:
	var sim := TruthSim.new(500, Vector2i(100, 200), 300)
	assert_eq(sim.player_position(), Vector2i(100, 200))
	assert_eq(sim.actors.count(), 1)


func test_step_moves_player_by_requested_delta_when_unobstructed() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"move_x": 50, "move_y": -30}))
	assert_eq(sim.player_position(), Vector2i(50, -30))


func test_step_with_zero_delta_does_not_move() -> void:
	var sim := TruthSim.new(500, Vector2i(10, 10), 300)
	sim.step(InputFrame.new(1, {}))
	assert_eq(sim.player_position(), Vector2i(10, 10))


func test_step_advances_the_clock_even_with_no_movement() -> void:
	var sim := TruthSim.new(500, Vector2i.ZERO, 300)
	sim.step(InputFrame.new(1, {}))
	sim.step(InputFrame.new(2, {}))
	assert_eq(sim.clock.current_tick, 2)


func test_step_stops_short_of_a_blocked_cell() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 1500), 100)
	sim.grid.set_cell_blocked(Vector2i(2, 2), true)  # world [1000,1500]x[1000,1500]
	sim.step(InputFrame.new(1, {"move_x": 1200, "move_y": 0}))
	assert_eq(sim.player_position(), Vector2i(900, 1500))


func test_run_replay_applies_every_frame_in_order() -> void:
	var sim := TruthSim.new(500, Vector2i.ZERO, 300)
	var replay := ReplayLog.new(1, "test")
	replay.record(InputFrame.new(1, {"move_x": 10, "move_y": 0}))
	replay.record(InputFrame.new(2, {"move_x": 0, "move_y": 20}))
	replay.record(InputFrame.new(3, {"move_x": -5, "move_y": 0}))
	sim.run_replay(replay)
	assert_eq(sim.player_position(), Vector2i(5, 20))
	assert_eq(sim.clock.current_tick, 3)


func test_moving_publishes_actor_moved_event() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("ActorMoved", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i.ZERO, 300, bus)

	sim.step(InputFrame.new(1, {"move_x": 10, "move_y": 0}))

	assert_eq(logger.events.size(), 1)
	var payload: Dictionary = logger.events[0]["payload"]
	assert_eq(payload["id"], sim.player_id)
	assert_eq(payload["position"], Vector2i(10, 0))
	assert_eq(logger.events[0]["tick"], 1)


func test_zero_delta_does_not_publish_actor_moved() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("ActorMoved", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i.ZERO, 300, bus)

	sim.step(InputFrame.new(1, {}))

	assert_eq(logger.events.size(), 0)


func test_two_truth_sims_given_identical_replays_end_up_identical() -> void:
	# The property that actually matters for determinism: same inputs,
	# same starting conditions, same result -- every time.
	var replay := ReplayLog.new(1, "test")
	replay.record(InputFrame.new(1, {"move_x": 37, "move_y": -11}))
	replay.record(InputFrame.new(2, {"move_x": -20, "move_y": 5}))

	var sim_a := TruthSim.new(500, Vector2i(0, 0), 300)
	var sim_b := TruthSim.new(500, Vector2i(0, 0), 300)
	sim_a.run_replay(replay)
	sim_b.run_replay(replay)

	assert_eq(sim_a.player_position(), sim_b.player_position())
	assert_eq(sim_a.clock.current_tick, sim_b.clock.current_tick)
