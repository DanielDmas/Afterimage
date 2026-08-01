extends AfterimageTestCase


func test_initial_value_is_zero() -> void:
	var state := FatigueState.new()
	assert_eq(state.value_fx(), 0)


## Worked example (§4.4.2): skipped sleep (+12), Ground used 3 times
## (+1.5 each = +4.5), 2 hours awake past 18 (+2 each = +4), a White Night
## mission (+10) sums to exactly 30.5 — Murmur band.
func test_worked_example_gains() -> void:
	var state := FatigueState.new()
	state.gain_skipped_sleep_block()
	for _i: int in range(3):
		state.gain_ground_use()
	for _i: int in range(2):
		state.gain_hour_awake_past_18()
	state.gain_white_night_mission()
	assert_eq(
		state.value_fx(),
		FixedMath.from_int(12) + FixedMath.from_float(4.5) + FixedMath.from_int(14)
	)
	assert_eq(MindModel.band_for(state.value_fx()), MindModel.Band.MURMUR)


func test_only_decays_via_sleep() -> void:
	var state := FatigueState.new()
	state.gain_skipped_sleep_block()
	for _i: int in range(3):
		state.gain_ground_use()
	for _i: int in range(2):
		state.gain_hour_awake_past_18()
	state.gain_white_night_mission()
	var before_fx: int = state.value_fx()  # 30.5

	state.apply_sleep_partial_block()  # -15
	assert_eq(state.value_fx(), before_fx - FixedMath.from_int(15))

	state.apply_sleep_full_block()  # -40, clamps to 0
	assert_eq(state.value_fx(), 0)


func test_clamps_at_100() -> void:
	var state := FatigueState.new()
	for _i: int in range(10):
		state.gain_skipped_sleep_block()  # 10 x 12 = 120, past 100
	assert_eq(state.value_fx(), FixedMath.from_int(100))


## §4.4.5's stimulant aftermath: a temporary floor raises the value
## immediately if it's currently below the floor (the same raise-only
## contract AcuteStressState.apply_hub_rest_floor() already established),
## and even a full sleep block (-40) can't push fatigue below the floor
## while it's active.
func test_temporary_floor_raises_current_value_and_blocks_decay_below_it() -> void:
	var state := FatigueState.new()
	state.set_temporary_floor(FixedMath.from_int(10))
	assert_eq(state.value_fx(), FixedMath.from_int(10))

	state.apply_sleep_full_block()  # -40, would clamp to 0 without the floor
	assert_eq(state.value_fx(), FixedMath.from_int(10))


func test_clearing_temporary_floor_does_not_itself_reduce_the_value() -> void:
	var state := FatigueState.new()
	state.set_temporary_floor(FixedMath.from_int(10))
	state.clear_temporary_floor()
	assert_eq(state.value_fx(), FixedMath.from_int(10))

	state.apply_sleep_full_block()  # -40, now clamps to the permanent floor of 0
	assert_eq(state.value_fx(), 0)
