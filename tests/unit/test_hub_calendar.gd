extends AfterimageTestCase


func test_advance_day_increments_current_day() -> void:
	var calendar := HubCalendar.new()
	var fatigue := FatigueState.new()
	assert_eq(calendar.current_day, 0)
	calendar.advance_day(HubCalendar.SleepChoice.FULL, fatigue)
	assert_eq(calendar.current_day, 1)
	calendar.advance_day(HubCalendar.SleepChoice.FULL, fatigue)
	assert_eq(calendar.current_day, 2)


## The roadmap AC, verbatim: "a full sleep-debt week produces the §4.4.2
## fatigue trace." Seven consecutive skipped-sleep days, each +12
## (FatigueState.GAIN_SKIPPED_SLEEP_BLOCK), decay only via sleep (never
## applied here) — a whole-integer trace with zero fixed-point rounding
## risk to hand-verify.
func test_full_sleep_debt_week_produces_the_expected_fatigue_trace() -> void:
	var calendar := HubCalendar.new()
	var fatigue := FatigueState.new()
	var trace: Array[int] = []
	for _day: int in range(7):
		calendar.advance_day(HubCalendar.SleepChoice.SKIPPED, fatigue)
		trace.append(fatigue.value_fx())

	var expected: Array[int] = []
	for day_number: int in range(1, 8):
		expected.append(FixedMath.from_int(day_number * 12))
	assert_eq(trace, expected)
	assert_eq(calendar.current_day, 7)


func test_mixed_week_of_sleep_choices_produces_the_expected_trace() -> void:
	## SKIPPED, SKIPPED, SKIPPED, PARTIAL, SKIPPED, SKIPPED, FULL:
	## 12, 24, 36, 36-15=21, 33, 45, 45-40=5 - hand-verified, all whole
	## integers (no fractional constants used in this scenario).
	var calendar := HubCalendar.new()
	var fatigue := FatigueState.new()
	var choices: Array[HubCalendar.SleepChoice] = [
		HubCalendar.SleepChoice.SKIPPED,
		HubCalendar.SleepChoice.SKIPPED,
		HubCalendar.SleepChoice.SKIPPED,
		HubCalendar.SleepChoice.PARTIAL,
		HubCalendar.SleepChoice.SKIPPED,
		HubCalendar.SleepChoice.SKIPPED,
		HubCalendar.SleepChoice.FULL,
	]
	var trace: Array[int] = []
	for choice: HubCalendar.SleepChoice in choices:
		calendar.advance_day(choice, fatigue)
		trace.append(fatigue.value_fx())

	var expected: Array[int] = [
		FixedMath.from_int(12),
		FixedMath.from_int(24),
		FixedMath.from_int(36),
		FixedMath.from_int(21),
		FixedMath.from_int(33),
		FixedMath.from_int(45),
		FixedMath.from_int(5),
	]
	assert_eq(trace, expected)


func test_advance_day_bills_hours_awake_past_18() -> void:
	var calendar := HubCalendar.new()
	var fatigue := FatigueState.new()
	calendar.advance_day(HubCalendar.SleepChoice.FULL, fatigue, 3)  # 3 hours -> +6, then -40 sleep
	# order: sleep resolved first (FULL: -40, clamped at 0), then +2 x 3 = +6
	assert_eq(fatigue.value_fx(), FixedMath.from_int(6))


func test_advance_day_bills_ground_uses() -> void:
	var calendar := HubCalendar.new()
	var fatigue := FatigueState.new()
	calendar.advance_day(HubCalendar.SleepChoice.SKIPPED, fatigue, 0, 2)  # +12, then +1.5 x 2 = +3
	assert_eq(fatigue.value_fx(), FixedMath.from_int(15))
