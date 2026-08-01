extends AfterimageTestCase


func test_initial_state_has_no_last_known_position() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))
	assert_false(agent.has_last_known_position())
	assert_eq(agent.current_state, AiUtility.State.PATROL)


func test_seeing_the_target_resolves_to_engage_and_remembers_position() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)
	var state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(500, 0), grid, false
	)
	assert_eq(state, AiUtility.State.ENGAGE)
	assert_true(agent.has_last_known_position())
	assert_eq(agent.last_known_position(), Vector2i(500, 0))


func test_target_out_of_range_does_not_engage() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))  # sentry range 6000mm
	var grid := CollisionGrid.new(500)
	var state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(20000, 0), grid, false
	)
	assert_ne(state, AiUtility.State.ENGAGE)
	assert_false(agent.has_last_known_position())


func test_wall_blocks_sight_even_within_cone_and_range() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)  # directly between observer and target
	var state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 250), Vector2i(2000, 250), grid, false
	)
	assert_ne(state, AiUtility.State.ENGAGE)
	assert_false(agent.has_last_known_position())


func test_sentry_never_reports_even_on_first_sighting() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)
	var state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(500, 0), grid, false
	)
	assert_eq(state, AiUtility.State.ENGAGE, "Sentry has no radio; it goes straight to engage")


func test_professional_reports_on_first_sighting_then_engages() -> void:
	var agent := AiAgent.new(1, AiArchetype.professional(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)

	var first_state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(500, 0), grid, false
	)
	assert_eq(first_state, AiUtility.State.REPORT, "first tick of sight: call it in")

	var second_state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(500, 0), grid, false
	)
	assert_eq(second_state, AiUtility.State.ENGAGE, "second tick: still seeing, now engage")


func test_losing_sight_then_regaining_it_reports_again() -> void:
	var agent := AiAgent.new(1, AiArchetype.professional(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)

	agent.perceive_and_decide(Vector2i(0, 0), Vector2i(500, 0), grid, false)  # spot -> report
	agent.perceive_and_decide(Vector2i(0, 0), Vector2i(500, 0), grid, false)  # engage
	agent.perceive_and_decide(Vector2i(0, 0), Vector2i(20000, 0), grid, false)  # lost sight

	var reacquired: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(500, 0), grid, false
	)
	assert_eq(reacquired, AiUtility.State.REPORT, "re-spotting after losing sight reports again")


func test_heard_noise_without_sight_investigates() -> void:
	var agent := AiAgent.new(1, AiArchetype.sentry(), Vector2i(100, 0))
	var grid := CollisionGrid.new(500)
	var state: AiUtility.State = agent.perceive_and_decide(
		Vector2i(0, 0), Vector2i(20000, 0), grid, true
	)
	assert_eq(state, AiUtility.State.INVESTIGATE)
