extends AfterimageTestCase


func test_initial_value_is_zero() -> void:
	var state := IdentityStrainState.new()
	assert_eq(state.value_fx(), 0)


## Worked example (§4.4.4): 5 days in cover (+1 each = +5), 3 passed Radek
## skill checks (+2 each = +6), 2 Radek-method acts (+4 each = +8), and
## spending Argus money on personal comfort (+2) sum to exactly 21; two
## Eliška-anchor acts (-3 each) then bring it back down to 15.
func test_worked_example() -> void:
	var state := IdentityStrainState.new()
	for _i: int in range(5):
		state.gain_day_in_cover()
	for _i: int in range(3):
		state.gain_radek_skill_check_passed()
	for _i: int in range(2):
		state.gain_radek_method_act()
	state.gain_argus_money_personal_comfort()
	assert_eq(state.value_fx(), FixedMath.from_int(21))

	for _i: int in range(2):
		state.decay_eliska_anchor_act()
	assert_eq(state.value_fx(), FixedMath.from_int(15))


func test_clamps_at_100_and_0() -> void:
	var high := IdentityStrainState.new()
	for _i: int in range(30):
		high.gain_radek_method_act()  # 30 x 4 = 120, past 100
	assert_eq(high.value_fx(), FixedMath.from_int(100))

	var low := IdentityStrainState.new()
	low.decay_eliska_anchor_act()  # -3 from a floor of 0
	assert_eq(low.value_fx(), 0)
