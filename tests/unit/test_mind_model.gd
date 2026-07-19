extends AfterimageTestCase


func test_new_mind_model_composes_four_zeroed_states() -> void:
	var mind := MindModel.new()
	assert_eq(mind.acute_stress.value_fx(), 0)
	assert_eq(mind.fatigue.value_fx(), 0)
	assert_eq(mind.moral_injury.value_fx(), 0)
	assert_eq(mind.identity_strain.value_fx(), 0)


func test_band_thresholds_are_inclusive_at_their_lower_bound() -> void:
	assert_eq(MindModel.band_for(FixedMath.from_int(24)), MindModel.Band.QUIET)
	assert_eq(MindModel.band_for(FixedMath.from_int(25)), MindModel.Band.MURMUR)
	assert_eq(MindModel.band_for(FixedMath.from_int(49)), MindModel.Band.MURMUR)
	assert_eq(MindModel.band_for(FixedMath.from_int(50)), MindModel.Band.LOUD)
	assert_eq(MindModel.band_for(FixedMath.from_int(74)), MindModel.Band.LOUD)
	assert_eq(MindModel.band_for(FixedMath.from_int(75)), MindModel.Band.CRISIS)
	assert_eq(MindModel.band_for(FixedMath.from_int(100)), MindModel.Band.CRISIS)


## §4.4.1's hub-rest rule: rest raises acute stress to a floor of
## max(fatigue, moralInjury) × 0.3. Expected fx is 1179660, not
## FixedMath.from_int(18) (1179648) — 0.3 has no exact Q16.16
## representation (0.3 * 65536 = 19660.8, rounds to 19661), and that
## rounding surfaces once multiplied by 60. Verified against a Python
## reference before porting.
func test_hub_rest_raises_acute_stress_to_the_fatigue_or_moral_injury_floor() -> void:
	var mind := MindModel.new()
	for _i: int in range(3):
		mind.fatigue.gain_skipped_sleep_block()  # 36
	mind.fatigue.gain_hour_awake_past_18()  # +2 -> 38
	mind.fatigue.gain_hour_awake_past_18()  # +2 -> 40
	for _i: int in range(4):
		mind.moral_injury.gain_civilian_casualty()  # 15 x 4 = 60

	mind.apply_hub_rest()
	assert_eq(mind.acute_stress.value_fx(), 1179660)


func test_hub_rest_never_lowers_acute_stress_already_above_the_floor() -> void:
	var mind := MindModel.new()
	for _i: int in range(3):
		mind.fatigue.gain_skipped_sleep_block()  # 36
	mind.fatigue.gain_hour_awake_past_18()  # 38
	mind.fatigue.gain_hour_awake_past_18()  # 40 -> floor would be 12
	for _i: int in range(5):
		mind.acute_stress.gain_entering_combat()  # 40, already above the floor
	mind.apply_hub_rest()
	assert_eq(mind.acute_stress.value_fx(), FixedMath.from_int(40))
