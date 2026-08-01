extends AfterimageTestCase

## §4.4.5's honest tradeoffs, exercised end to end against the real state
## classes they bill into — the same "prove the pipeline, not just each
## piece" job Pass 20's test_prologue_stub.gd did for the integration
## capstone, scoped here to just the substance/tool mechanics.


func test_stimulant_raises_fatigue_floor_immediately() -> void:
	var fatigue := FatigueState.new()
	var acute_stress := AcuteStressState.new()
	var substances := SubstanceModel.new()

	substances.apply_stimulant(fatigue, acute_stress)
	assert_eq(fatigue.value_fx(), FixedMath.from_int(10))
	assert_true(substances.is_stimulant_active())
	assert_eq(substances.stimulant_days_remaining(), 3)


func test_stimulant_inflates_acute_stress_gains_by_the_documented_multiplier() -> void:
	var fatigue := FatigueState.new()
	var acute_stress := AcuteStressState.new()
	var substances := SubstanceModel.new()

	substances.apply_stimulant(fatigue, acute_stress)
	acute_stress.gain_entering_combat()  # 8 x 1.25 = 10
	assert_eq(acute_stress.value_fx(), FixedMath.from_int(10))


## The floor and multiplier both survive exactly 3 advance_day() calls
## (days 1-2 of the aftermath) and both clear on the 3rd — the "for 3
## days" window this class's docstring commits to.
func test_aftermath_persists_for_exactly_three_days_then_clears() -> void:
	var fatigue := FatigueState.new()
	var acute_stress := AcuteStressState.new()
	var substances := SubstanceModel.new()
	substances.apply_stimulant(fatigue, acute_stress)

	substances.advance_day(fatigue, acute_stress)  # day 1 of the aftermath
	assert_true(substances.is_stimulant_active())
	fatigue.apply_sleep_full_block()  # -40, still clamps to the floor of 10
	assert_eq(fatigue.value_fx(), FixedMath.from_int(10))

	substances.advance_day(fatigue, acute_stress)  # day 2
	assert_true(substances.is_stimulant_active())

	substances.advance_day(fatigue, acute_stress)  # day 3 - aftermath ends
	assert_false(substances.is_stimulant_active())
	assert_eq(acute_stress.gain_multiplier_fx(), FixedMath.ONE)

	fatigue.apply_sleep_full_block()  # -40, now clamps to the permanent floor of 0
	assert_eq(fatigue.value_fx(), 0)


func test_advance_day_before_any_stimulant_is_a_no_op() -> void:
	var fatigue := FatigueState.new()
	var acute_stress := AcuteStressState.new()
	var substances := SubstanceModel.new()
	substances.advance_day(fatigue, acute_stress)
	assert_false(substances.is_stimulant_active())
	assert_eq(fatigue.value_fx(), 0)
	assert_eq(acute_stress.gain_multiplier_fx(), FixedMath.ONE)


func test_taking_a_second_stimulant_refreshes_duration_without_stacking() -> void:
	var fatigue := FatigueState.new()
	var acute_stress := AcuteStressState.new()
	var substances := SubstanceModel.new()
	substances.apply_stimulant(fatigue, acute_stress)
	substances.advance_day(fatigue, acute_stress)  # 1 day elapsed, 2 remain
	assert_eq(substances.stimulant_days_remaining(), 2)

	substances.apply_stimulant(fatigue, acute_stress)  # refreshed, not stacked
	assert_eq(substances.stimulant_days_remaining(), 3)
	assert_eq(fatigue.value_fx(), FixedMath.from_int(10))  # still 10, not 20
	assert_eq(acute_stress.gain_multiplier_fx(), FixedMath.from_float(1.25))


func test_alcohol_drink_bills_identity_strain_and_returns_suspicion_relief() -> void:
	var identity_strain := IdentityStrainState.new()
	var substances := SubstanceModel.new()

	var relief: int = substances.apply_alcohol_drink(identity_strain)
	assert_eq(identity_strain.value_fx(), FixedMath.from_int(2))
	assert_eq(relief, -1)

	substances.apply_alcohol_drink(identity_strain)
	assert_eq(identity_strain.value_fx(), FixedMath.from_int(4))


## seed=0's first draw (test_prng.gd's own pinned vector, 3413504692) is
## even, selecting index 0 among the two tier-1 entries in this deck —
## reusing DistortionDirector's own authorize_free_tier(), just entered
## through SubstanceModel's alcohol-specific wrapper.
func test_alcohol_authorizes_exactly_one_tier1_op_for_free() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 5, []),
		DeckEntry.new("TimeGap", 4, 30, []),
	]
	var director := DistortionDirector.new(0)
	director.budget = 0
	var substances := SubstanceModel.new()

	var record: Dictionary = substances.authorize_tier1_op(director, deck, 10)
	assert_eq(record["op_class"], "SubtitleDrift")
	assert_eq(record["cost"], 0)
	assert_true(record["authorized"])
	assert_eq(director.budget, 0)


func test_sedative_forces_a_full_sleep_block() -> void:
	var fatigue := FatigueState.new()
	fatigue.gain_skipped_sleep_block()
	fatigue.gain_skipped_sleep_block()  # 24
	var substances := SubstanceModel.new()

	substances.apply_sedative_night(fatigue)
	assert_eq(fatigue.value_fx(), 0)  # 24 - 40, clamped
