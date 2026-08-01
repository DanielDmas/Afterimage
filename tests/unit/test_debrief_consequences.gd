extends AfterimageTestCase


## Worked examples, docs/forward_dev_plan.md Phase C's own acceptance
## wording ("test the trust/resource math against a worked example") —
## each case is one cell of DebriefConsequences.bill()'s truth table.
func test_as_seen_true_gains_trust_no_resources() -> void:
	var result: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.AS_SEEN, 0)
	assert_eq(result["trust_delta"], 2)
	assert_eq(result["resource_delta"], 0)


func test_as_seen_false_loses_a_little_trust() -> void:
	var result: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.AS_SEEN, 1)
	assert_eq(result["trust_delta"], -1)
	assert_eq(result["resource_delta"], 0)


func test_verified_true_gains_more_trust_and_resources() -> void:
	var result: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.VERIFIED_ONLY, 0)
	assert_eq(result["trust_delta"], 3)
	assert_eq(result["resource_delta"], 5)


func test_verified_false_is_handled_even_though_it_should_not_arise() -> void:
	var result: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.VERIFIED_ONLY, 1)
	assert_eq(result["trust_delta"], -2)
	assert_eq(result["resource_delta"], 0)


func test_fabricate_always_loses_trust_regardless_of_truth_delta() -> void:
	var when_true: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.FABRICATE, 0)
	var when_false: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.FABRICATE, 1)
	assert_eq(when_true["trust_delta"], -3)
	assert_eq(when_false["trust_delta"], -3)
	assert_eq(when_true["resource_delta"], 0)


## §4.10: "an honest error costs less trust than a fabrication when
## discovered" — the one qualitative constraint the spec actually pins.
func test_fabrication_costs_more_trust_than_an_honest_error() -> void:
	var honest_error: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.AS_SEEN, 1)
	var fabrication: Dictionary = DebriefConsequences.bill(DebriefLedger.HonestyMode.FABRICATE, 0)
	assert_true(fabrication["trust_delta"] < honest_error["trust_delta"])
