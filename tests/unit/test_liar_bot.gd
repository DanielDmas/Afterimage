extends AfterimageTestCase

## foundation_blueprints.md §7: "a 'liar bot' fabricates every claim to
## smoke-test the consequence graph... must finish every mission." No real
## missions exist yet (Pass 13's content pipeline only has a stub
## DistortionDirector mission, not a debrief-shaped one) - this is the
## smoke test at the scale this pass's actual subsystem supports: draft a
## batch of claims from perceived events (a mix that would and wouldn't
## match ground truth), fabricate every single one regardless, and confirm
## the ledger processes the whole batch without erroring and accumulates
## exactly the moral injury §4.4.3/§4.10 promise.


## Always chooses FABRICATE, regardless of what's true - the bot has no
## opinion about truth, which is the whole point of this smoke test.
func _liar_bot_submit_all(
	ledger: DebriefLedger,
	claims: Array[Claim],
	ground_truth: Dictionary,
	moral_injury: MoralInjuryState
) -> void:
	for claim: Claim in claims:
		var truth_object: String = ground_truth.get(claim.id, "")
		ledger.submit_claim(
			claim.id, DebriefLedger.HonestyMode.FABRICATE, truth_object, moral_injury, false
		)


func test_liar_bot_fabricates_a_full_batch_without_erroring() -> void:
	var events: Array[Dictionary] = [
		{"id": "claim.1", "subject": "player", "predicate": "saw_entity", "object": "second_guard"},
		{"id": "claim.2", "subject": "player", "predicate": "fired_shot", "object": "weapon.cz75"},
		{"id": "claim.3", "subject": "player", "predicate": "heard_sound", "object": "footsteps"},
		{
			"id": "claim.4",
			"subject": "player",
			"predicate": "touched_objective",
			"object": "safe.archive"
		},
		{"id": "claim.5", "subject": "player", "predicate": "witnessed", "object": "npc.vrba"},
	]
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(events)

	var ledger := DebriefLedger.new()
	for claim: Claim in claims:
		ledger.add_candidate(claim)

	# Ground truth: claim.1 and claim.5 are actually false (a phantom and a
	# misidentification); the rest match truth exactly. The bot doesn't
	# care either way - it fabricates all five regardless.
	var ground_truth: Dictionary = {
		"claim.1": "nobody",
		"claim.2": "weapon.cz75",
		"claim.3": "footsteps",
		"claim.4": "safe.archive",
		"claim.5": "npc.rohanova",
	}

	var moral_injury := MoralInjuryState.new()
	_liar_bot_submit_all(ledger, claims, ground_truth, moral_injury)

	assert_eq(ledger.submissions().size(), 5)
	for claim: Claim in claims:
		assert_true(ledger.is_submitted(claim.id))

	# 5 fabrications x GAIN_KNOWING_LIE_IN_DEBRIEF (3) = 15
	assert_eq(moral_injury.value_fx(), FixedMath.from_int(15))


func test_liar_bot_batch_preserves_correct_truth_deltas_despite_fabricating_all() -> void:
	## Truth-delta is engine-computed from actual content match, not from
	## the chosen mode - fabricating doesn't change what's objectively
	## true, only what's *claimed*. Both should be tracked independently.
	var events: Array[Dictionary] = [
		{
			"id": "claim.true",
			"subject": "player",
			"predicate": "fired_shot",
			"object": "weapon.cz75"
		},
		{
			"id": "claim.false",
			"subject": "player",
			"predicate": "saw_entity",
			"object": "second_guard"
		},
	]
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(events)
	var ledger := DebriefLedger.new()
	for claim: Claim in claims:
		ledger.add_candidate(claim)

	var ground_truth: Dictionary = {"claim.true": "weapon.cz75", "claim.false": "nobody"}
	var moral_injury := MoralInjuryState.new()
	_liar_bot_submit_all(ledger, claims, ground_truth, moral_injury)

	var submissions: Array = ledger.submissions()
	assert_eq(submissions[0]["truth_delta"], 0)  # claim.true actually matched truth
	assert_eq(submissions[1]["truth_delta"], 1)  # claim.false did not
	# both were still fabricated, both still cost moral injury
	assert_eq(moral_injury.value_fx(), FixedMath.from_int(6))  # 2 x 3
