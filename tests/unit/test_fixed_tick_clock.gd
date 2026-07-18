extends AfterimageTestCase


func test_starts_at_zero() -> void:
	var clock := FixedTickClock.new()
	assert_eq(clock.current_tick, 0)


func test_advance_increments_and_returns_new_tick() -> void:
	var clock := FixedTickClock.new()
	assert_eq(clock.advance(), 1)
	assert_eq(clock.advance(), 2)
	assert_eq(clock.current_tick, 2)


func test_reset_returns_to_zero() -> void:
	var clock := FixedTickClock.new()
	clock.advance()
	clock.advance()
	clock.reset()
	assert_eq(clock.current_tick, 0)


func test_tick_rate_is_30hz() -> void:
	assert_eq(FixedTickClock.TICK_RATE_HZ, 30)
	assert_almost_eq(FixedTickClock.TICK_DURATION_SECONDS, 1.0 / 30.0, 0.00001)


func test_seconds_to_ticks_rounds_to_nearest() -> void:
	assert_eq(FixedTickClock.seconds_to_ticks(1.0), 30)
	assert_eq(FixedTickClock.seconds_to_ticks(2.5), 75)
	assert_eq(FixedTickClock.seconds_to_ticks(0.0), 0)


func test_seconds_to_ticks_ground_verb_duration() -> void:
	# master_plan.md §4.6: Ground baseline is 2.5s -> 75 ticks at 30Hz.
	assert_eq(FixedTickClock.seconds_to_ticks(2.5), 75)
