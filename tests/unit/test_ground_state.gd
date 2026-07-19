extends AfterimageTestCase


func test_initial_state_is_not_holding_and_not_completed() -> void:
	var ground := GroundState.new()
	assert_false(ground.is_holding())
	assert_false(ground.just_completed())
	assert_eq(ground.use_count, 0)


func test_holding_for_fewer_than_duration_ticks_is_holding_but_not_completed() -> void:
	var ground := GroundState.new()
	for _i: int in range(GroundState.DURATION_TICKS - 1):
		ground.advance_tick(true)
	assert_true(ground.is_holding())
	assert_false(ground.just_completed())
	assert_eq(ground.use_count, 0)


func test_completes_at_exactly_duration_ticks_and_use_count_increments() -> void:
	var ground := GroundState.new()
	for _i: int in range(GroundState.DURATION_TICKS - 1):
		ground.advance_tick(true)
	ground.advance_tick(true)
	assert_true(ground.just_completed())
	assert_false(ground.is_holding())
	assert_eq(ground.use_count, 1)


func test_just_completed_is_true_only_on_the_completing_tick() -> void:
	var ground := GroundState.new()
	for _i: int in range(GroundState.DURATION_TICKS):
		ground.advance_tick(true)
	assert_true(ground.just_completed())
	ground.advance_tick(false)
	assert_false(ground.just_completed())


func test_releasing_before_completion_resets_progress() -> void:
	var ground := GroundState.new()
	for _i: int in range(GroundState.DURATION_TICKS - 1):
		ground.advance_tick(true)
	ground.advance_tick(false)  # released one tick early
	assert_false(ground.is_holding())

	# A fresh hold needs the full duration again, not just the one
	# remaining tick from before the release.
	for _i: int in range(GroundState.DURATION_TICKS - 1):
		ground.advance_tick(true)
	assert_true(ground.is_holding())
	assert_false(ground.just_completed())

	ground.advance_tick(true)
	assert_true(ground.just_completed())
	assert_eq(ground.use_count, 1)
