extends AfterimageTestCase


## As in test_truth_sim.gd/test_truth_sim_combat.gd: event payloads are
## captured via a bound-method Callable on a helper class, not a lambda
## mutating a captured local.
class _EventLogger:
	var events: Array = []

	func handle(event: Dictionary) -> void:
		events.append(event)


func test_movement_and_fire_are_blocked_while_grounding() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var starting_ammo: int = sim.player_weapon_ammo()
	for i: int in range(GroundState.DURATION_TICKS):
		sim.step(
			InputFrame.new(
				i + 1, {"ground": true, "move_x": 50, "fire": true, "aim_dir": Vector2i(1, 0)}
			)
		)
	assert_eq(sim.player_position(), Vector2i(0, 0))
	assert_eq(sim.player_weapon_ammo(), starting_ammo)


func test_ground_completed_event_fires_with_no_observer_when_unseen() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("GroundCompleted", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i(0, 0), 300, bus)
	for i: int in range(GroundState.DURATION_TICKS):
		sim.step(InputFrame.new(i + 1, {"ground": true}))
	assert_eq(logger.events.size(), 1)
	assert_eq(logger.events[0]["payload"]["observed_by"], -1)


func test_ground_observed_event_fires_when_an_ai_can_see_the_player() -> void:
	var bus := EventBus.new()
	var completed_logger := _EventLogger.new()
	var observed_logger := _EventLogger.new()
	bus.subscribe("GroundCompleted", Callable(completed_logger, "handle"))
	bus.subscribe("GroundObserved", Callable(observed_logger, "handle"))
	var sim := TruthSim.new(500, Vector2i(0, 0), 300, bus)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry(), Vector2i(-1, 0))

	for i: int in range(GroundState.DURATION_TICKS):
		sim.step(InputFrame.new(i + 1, {"ground": true}))

	assert_eq(completed_logger.events[0]["payload"]["observed_by"], ai_id)
	assert_eq(observed_logger.events.size(), 1)
	assert_eq(observed_logger.events[0]["payload"]["observer_id"], ai_id)
	assert_eq(
		observed_logger.events[0]["payload"]["suspicion_weight"],
		TruthSim.GROUND_OBSERVED_SUSPICION_WEIGHT
	)


func test_ground_use_count_increments_on_completion_regardless_of_observation() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	for i: int in range(GroundState.DURATION_TICKS):
		sim.step(InputFrame.new(i + 1, {"ground": true}))
	assert_eq(sim.ground_use_count(), 1)


func test_releasing_ground_early_does_not_complete_or_fire_events() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("GroundCompleted", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i(0, 0), 300, bus)
	for i: int in range(GroundState.DURATION_TICKS - 1):
		sim.step(InputFrame.new(i + 1, {"ground": true}))
	sim.step(InputFrame.new(GroundState.DURATION_TICKS, {"ground": false, "move_x": 50}))
	assert_eq(logger.events.size(), 0)
	assert_eq(sim.player_position(), Vector2i(50, 0))  # movement resumes once ground is released


func test_snapshot_exposes_ground_holding_and_completion_flags() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"ground": true}))
	assert_true(sim.capture_percept_snapshot()["ground_is_holding"])
	assert_false(sim.capture_percept_snapshot()["ground_just_completed"])

	for i: int in range(GroundState.DURATION_TICKS - 1):
		sim.step(InputFrame.new(2 + i, {"ground": true}))
	assert_true(sim.capture_percept_snapshot()["ground_just_completed"])
