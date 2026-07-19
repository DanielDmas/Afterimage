extends AfterimageTestCase


func test_initial_value_is_zero() -> void:
	var state := MoralInjuryState.new()
	assert_eq(state.value_fx(), 0)


## Worked example (§4.4.3): four combat/social gains sum to exactly 47,
## then a fully-disclosed Sova session (-8), a Doubek hard truth (-6), and
## one day of passive decay (-0.1) bring it down to exactly 32.9.
func test_worked_example_gains_and_active_decay() -> void:
	var state := MoralInjuryState.new()
	state.gain_kill_in_open_combat()
	state.gain_kill_of_unaware_victim()
	state.gain_executing_downed_enemy()
	state.gain_civilian_casualty()
	assert_eq(state.value_fx(), FixedMath.from_int(34))

	state.gain_betraying_friendly_argus_npc()
	state.gain_knowing_lie_in_debrief(true)
	assert_eq(state.value_fx(), FixedMath.from_int(47))

	state.apply_sova_session(FixedMath.ONE)  # full disclosure -> full -8
	assert_eq(state.value_fx(), FixedMath.from_int(39))

	state.apply_doubek_hard_truth()
	assert_eq(state.value_fx(), FixedMath.from_int(33))

	state.decay_passive_daily()
	assert_eq(state.value_fx(), FixedMath.from_int(33) - FixedMath.from_float(0.1))


func test_knowing_lie_costs_less_when_it_conceals_nothing() -> void:
	var conceals_death := MoralInjuryState.new()
	conceals_death.gain_knowing_lie_in_debrief(true)
	assert_eq(conceals_death.value_fx(), FixedMath.from_int(5))

	var no_concealment := MoralInjuryState.new()
	no_concealment.gain_knowing_lie_in_debrief(false)
	assert_eq(no_concealment.value_fx(), FixedMath.from_int(3))


func test_sova_session_scales_between_minus_4_and_minus_8_by_disclosure() -> void:
	var minimal := MoralInjuryState.new()
	minimal.gain_civilian_casualty()  # 15
	minimal.apply_sova_session(0)  # no disclosure -> -4
	assert_eq(minimal.value_fx(), FixedMath.from_int(11))

	var half := MoralInjuryState.new()
	half.gain_civilian_casualty()  # 15
	half.apply_sova_session(FixedMath.HALF)  # halfway -> -6
	assert_eq(half.value_fx(), FixedMath.from_int(9))


func test_clamps_at_100_and_0() -> void:
	var high := MoralInjuryState.new()
	for _i: int in range(10):
		high.gain_civilian_casualty()  # 10 x 15 = 150, past 100
	assert_eq(high.value_fx(), FixedMath.from_int(100))

	var low := MoralInjuryState.new()
	low.apply_doubek_hard_truth()  # -6 from a floor of 0
	assert_eq(low.value_fx(), 0)
