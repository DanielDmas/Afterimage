extends AfterimageTestCase

## Every fx-value assertion below was hand-verified against a Python
## reference (Q16.16 arithmetic, round-half-away-from-zero, truncating
## division) before porting, per this project's "verify externally, then
## port" discipline for arithmetic with real rounding risk. Assertions
## compare exact Q16.16 integers, never floats.


func test_initial_value_is_zero() -> void:
	var state := AcuteStressState.new()
	assert_eq(state.value_fx(), 0)


## Worked example (§4.4.1): enter combat (+8), near discovery (+10),
## witnessing a kill (+6) sums to exactly 24 — still Quiet, one shy of
## Murmur — then gunfire in earshot (+2) crosses into Murmur at 26.
func test_worked_example_gains_and_band_crossing() -> void:
	var state := AcuteStressState.new()
	state.gain_entering_combat()
	state.gain_near_discovery()
	state.gain_witnessing_kill()
	assert_eq(state.value_fx(), FixedMath.from_int(24))
	assert_eq(MindModel.band_for(state.value_fx()), MindModel.Band.QUIET)

	state.gain_gunfire_in_earshot()
	assert_eq(state.value_fx(), FixedMath.from_int(26))
	assert_eq(MindModel.band_for(state.value_fx()), MindModel.Band.MURMUR)

	state.gain_acting_on_believed_phantom()
	state.gain_focus_use()
	assert_eq(state.value_fx(), FixedMath.from_int(37))


## 30 ticks (exactly 1 second) of safe-zone decay at -0.4/s subtracts
## exactly 0.4 in fixed point — the "scale once, divide once" batch formula
## has zero rounding error when ticks is an exact multiple of TICK_RATE.
func test_safe_zone_decay_for_one_second_is_exact() -> void:
	var state := AcuteStressState.new()
	state.gain_entering_combat()  # 8.0
	state.advance_ticks(30, AcuteStressState.Zone.SAFE)
	assert_eq(state.value_fx(), FixedMath.from_int(8) - FixedMath.from_float(0.4))


func test_mission_alerted_zone_applies_no_decay() -> void:
	var state := AcuteStressState.new()
	state.gain_entering_combat()
	state.advance_ticks(300, AcuteStressState.Zone.MISSION_ALERTED)
	assert_eq(state.value_fx(), FixedMath.from_int(8))


func test_per_tick_and_batch_decay_agree_over_one_second() -> void:
	var per_tick := AcuteStressState.new()
	per_tick.gain_entering_combat()
	for _i: int in range(30):
		per_tick.advance_tick(AcuteStressState.Zone.SAFE)

	var batched := AcuteStressState.new()
	batched.gain_entering_combat()
	batched.advance_ticks(30, AcuteStressState.Zone.SAFE)

	assert_eq(per_tick.value_fx(), batched.value_fx())


func test_relieved_by_ground_completion() -> void:
	var state := AcuteStressState.new()
	for _i: int in range(5):
		state.gain_entering_combat()  # 40
	state.relieve_ground_completed()
	assert_eq(state.value_fx(), FixedMath.from_int(32))


func test_clamps_at_100_and_0() -> void:
	var high := AcuteStressState.new()
	for _i: int in range(20):
		high.gain_near_discovery()  # 20 x 10 = 200, way past 100
	assert_eq(high.value_fx(), FixedMath.from_int(100))

	var low := AcuteStressState.new()
	low.relieve_ground_completed()  # -8 from a floor of 0
	assert_eq(low.value_fx(), 0)


func test_hub_rest_floor_raises_a_lower_value() -> void:
	var state := AcuteStressState.new()
	state.gain_near_discovery()  # 10
	state.apply_hub_rest_floor(FixedMath.from_int(18))
	assert_eq(state.value_fx(), FixedMath.from_int(18))


func test_hub_rest_floor_never_lowers_a_higher_value() -> void:
	var state := AcuteStressState.new()
	for _i: int in range(5):
		state.gain_entering_combat()  # 40
	state.apply_hub_rest_floor(FixedMath.from_int(18))
	assert_eq(state.value_fx(), FixedMath.from_int(40))
