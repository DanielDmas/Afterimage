extends AfterimageTestCase


func test_build_produces_one_row_per_candidate_in_insertion_order() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(Claim.new("claim.b", "player", "saw_entity", "second_guard"))
	ledger.add_candidate(Claim.new("claim.a", "player", "fired_shot", "weapon.cz75"))

	var screen: DebriefScreen = DebriefScreen.build(ledger)
	assert_eq(screen.claim_rows.size(), 2)
	assert_eq(screen.claim_rows[0]["claim_id"], "claim.b")
	assert_eq(screen.claim_rows[1]["claim_id"], "claim.a")


func test_summary_reads_subject_predicate_object() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(Claim.new("claim.a", "player", "saw_entity", "second_guard"))
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	assert_eq(screen.claim_rows[0]["summary"], "player saw_entity second_guard")


func test_percept_only_claim_does_not_offer_verified_only() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(
		Claim.new(
			"claim.a",
			"player",
			"saw_entity",
			"second_guard",
			{},
			[{"type": Claim.ProvenanceType.PERCEIVED}]
		)
	)
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	var modes: Array = screen.claim_rows[0]["available_modes"]
	assert_true(modes.has(DebriefLedger.HonestyMode.AS_SEEN))
	assert_true(modes.has(DebriefLedger.HonestyMode.FABRICATE))
	assert_false(modes.has(DebriefLedger.HonestyMode.VERIFIED_ONLY))


func test_grounded_claim_offers_verified_only() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(
		Claim.new(
			"claim.a",
			"player",
			"saw_entity",
			"second_guard",
			{},
			[{"type": Claim.ProvenanceType.GROUNDED}]
		)
	)
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	var modes: Array = screen.claim_rows[0]["available_modes"]
	assert_true(modes.has(DebriefLedger.HonestyMode.VERIFIED_ONLY))


func test_evidence_claim_offers_verified_only() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(
		Claim.new(
			"claim.a",
			"player",
			"saw_entity",
			"second_guard",
			{},
			[{"type": Claim.ProvenanceType.EVIDENCE}]
		)
	)
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	var modes: Array = screen.claim_rows[0]["available_modes"]
	assert_true(modes.has(DebriefLedger.HonestyMode.VERIFIED_ONLY))


func test_screen_reader_text_includes_title_and_every_claim_summary() -> void:
	var ledger := DebriefLedger.new()
	ledger.add_candidate(Claim.new("claim.a", "player", "saw_entity", "second_guard"))
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	var text: String = screen.screen_reader_text()
	assert_true(text.begins_with("Debrief"))
	assert_true(text.contains("player saw_entity second_guard"))


func test_no_candidates_produces_no_rows() -> void:
	var ledger := DebriefLedger.new()
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	assert_eq(screen.claim_rows.size(), 0)
