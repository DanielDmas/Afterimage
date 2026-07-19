extends AfterimageTestCase


func _sample_claim(claim_id: String = "claim.a") -> Claim:
	return Claim.new(claim_id, "player", "saw_entity", "second_guard")


func test_add_candidate_and_candidate_lookup() -> void:
	var ledger := DebriefLedger.new()
	var claim: Claim = _sample_claim()
	ledger.add_candidate(claim)
	assert_eq(ledger.candidate("claim.a").id, "claim.a")
	assert_false(ledger.is_submitted("claim.a"))


func test_candidates_preserves_insertion_order() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim("claim.b"))
	ledger.add_candidate(_sample_claim("claim.a"))
	var ids: Array[String] = []
	for claim: Claim in ledger.candidates():
		ids.append(claim.id)
	assert_eq(ids, ["claim.b", "claim.a"])  # insertion order, not alphabetical


func test_submit_claim_with_matching_truth_object_has_zero_delta() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	var record: Dictionary = ledger.submit_claim(
		"claim.a", DebriefLedger.HonestyMode.AS_SEEN, "second_guard"
	)
	assert_eq(record["truth_delta"], 0)
	assert_true(ledger.is_submitted("claim.a"))


func test_submit_claim_with_mismatched_truth_object_has_delta_one() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	# the claim asserts "second_guard" but truth says no one was there
	var record: Dictionary = ledger.submit_claim(
		"claim.a", DebriefLedger.HonestyMode.AS_SEEN, "nobody"
	)
	assert_eq(record["truth_delta"], 1)


func test_verified_only_requires_grounded_or_evidence_provenance() -> void:
	var ledger := DebriefLedger.new()
	var grounded_claim := Claim.new(
		"claim.a",
		"player",
		"saw_entity",
		"second_guard",
		{},
		[{"type": Claim.ProvenanceType.GROUNDED}]
	)
	ledger.add_candidate(grounded_claim)
	var record: Dictionary = ledger.submit_claim(
		"claim.a", DebriefLedger.HonestyMode.VERIFIED_ONLY, "second_guard"
	)
	assert_eq(record["mode"], DebriefLedger.HonestyMode.VERIFIED_ONLY)


func test_fabricate_bills_moral_injury_when_supplied() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	var moral_injury := MoralInjuryState.new()
	ledger.submit_claim(
		"claim.a", DebriefLedger.HonestyMode.FABRICATE, "nobody", moral_injury, false
	)
	assert_eq(moral_injury.value_fx(), FixedMath.from_int(3))  # GAIN_KNOWING_LIE_IN_DEBRIEF


func test_fabricate_concealing_death_bills_more_moral_injury() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	var moral_injury := MoralInjuryState.new()
	ledger.submit_claim(
		"claim.a", DebriefLedger.HonestyMode.FABRICATE, "nobody", moral_injury, true
	)
	assert_eq(moral_injury.value_fx(), FixedMath.from_int(5))  # GAIN_KNOWING_LIE_CONCEALING_DEATH


func test_fabricate_without_moral_injury_argument_does_not_error() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	ledger.submit_claim("claim.a", DebriefLedger.HonestyMode.FABRICATE, "nobody")
	assert_true(ledger.is_submitted("claim.a"))


func test_as_seen_does_not_bill_moral_injury() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	var moral_injury := MoralInjuryState.new()
	ledger.submit_claim("claim.a", DebriefLedger.HonestyMode.AS_SEEN, "second_guard", moral_injury)
	assert_eq(moral_injury.value_fx(), 0)


func test_submissions_returns_a_copy_not_a_live_reference() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(_sample_claim())
	ledger.submit_claim("claim.a", DebriefLedger.HonestyMode.AS_SEEN, "second_guard")
	var submissions_copy: Array = ledger.submissions()
	submissions_copy.clear()
	assert_eq(ledger.submissions().size(), 1)
