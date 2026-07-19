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


## Per-tick and batched decay do NOT agree exactly: 30 separate truncating
## divisions (one per advance_tick() call) each lose a little more than a
## single division of the same total does. rate_fx=-26214 (-0.4 in Q16.16);
## one tick's share is trunc_div(-26214, 30) = -873 (true value -873.8),
## losing ~0.2 fx units per tick, accumulating to -26190 over 30 ticks —
## 24 fx short of the batched form's exact -26214. This is exactly why
## advance_ticks() exists (see its doc comment): the batch form is the more
## precise one, by design, and this test pins the real, hand-verified size
## of that gap rather than asserting a false "they agree" premise (caught
## by CI, not the sandbox's gdlint/gdformat pass, since there's no local
## Godot binary here to run the actual interpreter).
func test_per_tick_decay_accumulates_more_rounding_error_than_batched() -> void:
	var per_tick := AcuteStressState.new()
	per_tick.gain_entering_combat()  # 8.0
	for _i: int in range(30):
		per_tick.advance_tick(AcuteStressState.Zone.SAFE)
	assert_eq(per_tick.value_fx(), 498098)

	var batched := AcuteStressState.new()
	batched.gain_entering_combat()
	batched.advance_ticks(30, AcuteStressState.Zone.SAFE)
	assert_eq(batched.value_fx(), 498074)

	assert_lt(batched.value_fx(), per_tick.value_fx())


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


## §4.4.5's stimulant cost: "acute-stress gains ×1.25" — 8 x 1.25 = 10
## exactly (1.25 = 5/4 and Q16.16's SCALE=65536 is divisible by 4, so this
## is exact fixed-point arithmetic, not an approximation).
func test_gain_multiplier_inflates_every_gain_method() -> void:
	var state := AcuteStressState.new()
	assert_eq(state.gain_multiplier_fx(), FixedMath.ONE)

	state.set_gain_multiplier_fx(FixedMath.from_float(1.25))
	state.gain_entering_combat()  # 8 x 1.25 = 10
	assert_eq(state.value_fx(), FixedMath.from_int(10))


func test_clear_gain_multiplier_restores_normal_gains() -> void:
	var state := AcuteStressState.new()
	state.set_gain_multiplier_fx(FixedMath.from_float(1.25))
	state.clear_gain_multiplier()
	assert_eq(state.gain_multiplier_fx(), FixedMath.ONE)

	state.gain_entering_combat()  # unmultiplied: 8
	assert_eq(state.value_fx(), FixedMath.from_int(8))


## The multiplier must never apply to relief or passive decay — only to
## gains. A 2x multiplier active throughout still leaves
## relieve_ground_completed()'s -8 untouched.
func test_gain_multiplier_never_applies_to_relief_or_decay() -> void:
	var state := AcuteStressState.new()
	state.set_gain_multiplier_fx(FixedMath.from_int(2))
	state.gain_entering_combat()  # 8 x 2 = 16
	assert_eq(state.value_fx(), FixedMath.from_int(16))

	state.relieve_ground_completed()  # -8, unmultiplied
	assert_eq(state.value_fx(), FixedMath.from_int(8))

	state.advance_ticks(30, AcuteStressState.Zone.SAFE)  # -0.4 over 1s, unmultiplied
	assert_eq(state.value_fx(), FixedMath.from_int(8) - FixedMath.from_float(0.4))
