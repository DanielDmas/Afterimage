extends AfterimageTestCase

## Covers PredicateEvaluator.evaluate() against a MockWorldQuery: one leaf
## operator per test, plus the all/any/not combinators and a nested case.
## Static structural validation (PredicateEvaluator.validate()) has its own
## file, test_predicate_validate.gd — split along that seam because the two
## responsibilities are genuinely distinct, not to dodge a lint threshold.


func _query() -> MockWorldQuery:
	return MockWorldQuery.new()


func test_has_claim() -> void:
	var q := _query()
	q.claims["claim.a"] = true
	assert_true(PredicateEvaluator.evaluate({"op": "hasClaim", "args": {"id": "claim.a"}}, q))
	assert_false(PredicateEvaluator.evaluate({"op": "hasClaim", "args": {"id": "claim.b"}}, q))


func test_claim_asserted_any_mode() -> void:
	var q := _query()
	q.claims["claim.a"] = ["as_seen"]
	assert_true(PredicateEvaluator.evaluate({"op": "claimAsserted", "args": {"id": "claim.a"}}, q))
	assert_false(
		PredicateEvaluator.evaluate({"op": "claimAsserted", "args": {"id": "claim.missing"}}, q)
	)


func test_claim_asserted_specific_mode() -> void:
	var q := _query()
	q.claims["claim.a"] = ["verified"]
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "claimAsserted", "args": {"id": "claim.a", "mode": "verified"}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "claimAsserted", "args": {"id": "claim.a", "mode": "fabricate"}}, q
		)
	)


func test_trust_at_least() -> void:
	var q := _query()
	q.trust_values["npc.doubek"] = 40
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": 40}}, q
		)
	)
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": 39}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": 41}}, q
		)
	)


func test_suspicion_at_least() -> void:
	var q := _query()
	q.suspicion_values["npc.vrba"] = 50
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "suspicionAtLeast", "args": {"target": "npc.vrba", "n": 50}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "suspicionAtLeast", "args": {"target": "npc.vrba", "n": 51}}, q
		)
	)


func test_mind_band_match_and_mismatch() -> void:
	var q := _query()
	q.mind_bands["fatigue"] = "loud"
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "mindBand", "args": {"variable": "fatigue", "band": "loud"}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "mindBand", "args": {"variable": "fatigue", "band": "crisis"}}, q
		)
	)


func test_day_after_and_before() -> void:
	var q := _query()
	q.day = 10
	assert_true(PredicateEvaluator.evaluate({"op": "dayAfter", "args": {"day": 9}}, q))
	assert_false(PredicateEvaluator.evaluate({"op": "dayAfter", "args": {"day": 10}}, q))
	assert_true(PredicateEvaluator.evaluate({"op": "dayBefore", "args": {"day": 11}}, q))
	assert_false(PredicateEvaluator.evaluate({"op": "dayBefore", "args": {"day": 10}}, q))


func test_mission_done() -> void:
	var q := _query()
	q.missions_done["m01_induction"] = true
	assert_true(
		PredicateEvaluator.evaluate({"op": "missionDone", "args": {"id": "m01_induction"}}, q)
	)
	assert_false(
		PredicateEvaluator.evaluate({"op": "missionDone", "args": {"id": "m02_listening_room"}}, q)
	)


func test_flag_and_flag_value() -> void:
	var q := _query()
	q.flags["prologue_complete"] = true
	q.flag_values["mole_suspect"] = "milan"
	assert_true(
		PredicateEvaluator.evaluate({"op": "flag", "args": {"name": "prologue_complete"}}, q)
	)
	assert_false(PredicateEvaluator.evaluate({"op": "flag", "args": {"name": "unset_flag"}}, q))
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "flagValue", "args": {"name": "mole_suspect", "value": "milan"}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "flagValue", "args": {"name": "mole_suspect", "value": "sedlak"}}, q
		)
	)


func test_kills_at_least() -> void:
	var q := _query()
	q.kill_counts["civilian"] = 1
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "killsAtLeast", "args": {"context": "civilian", "n": 1}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "killsAtLeast", "args": {"context": "civilian", "n": 2}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "killsAtLeast", "args": {"context": "unaware", "n": 1}}, q
		)
	)


func test_witnessed() -> void:
	var q := _query()
	q.witnessed_tags["m03_beating"] = true
	assert_true(
		PredicateEvaluator.evaluate({"op": "witnessed", "args": {"eventTag": "m03_beating"}}, q)
	)
	assert_false(
		PredicateEvaluator.evaluate({"op": "witnessed", "args": {"eventTag": "m03_other"}}, q)
	)


func test_grounded() -> void:
	var q := _query()
	q.grounded_refs["PhantomEntity"] = true
	assert_true(
		PredicateEvaluator.evaluate({"op": "grounded", "args": {"ref": "PhantomEntity"}}, q)
	)
	assert_false(
		PredicateEvaluator.evaluate({"op": "grounded", "args": {"ref": "SubtitleDrift"}}, q)
	)


func test_cover_blown_to_any_and_specific() -> void:
	var q := _query()
	q.blown_factions["vrba"] = true
	assert_true(
		PredicateEvaluator.evaluate({"op": "coverBlownTo", "args": {}}, q),
		"empty faction arg means 'blown to anyone'"
	)
	assert_true(PredicateEvaluator.evaluate({"op": "coverBlownTo", "args": {"faction": "vrba"}}, q))
	assert_false(
		PredicateEvaluator.evaluate({"op": "coverBlownTo", "args": {"faction": "rohanova"}}, q)
	)

	var q2 := _query()
	assert_false(
		PredicateEvaluator.evaluate({"op": "coverBlownTo", "args": {}}, q2),
		"no faction blown at all"
	)


func test_ending_gate() -> void:
	var q := _query()
	q.ending_gates["extraction"] = true
	assert_true(
		PredicateEvaluator.evaluate({"op": "endingGate", "args": {"family": "extraction"}}, q)
	)
	assert_false(
		PredicateEvaluator.evaluate({"op": "endingGate", "args": {"family": "erasure"}}, q)
	)


func test_item_held() -> void:
	var q := _query()
	q.items["camera"] = true
	assert_true(PredicateEvaluator.evaluate({"op": "itemHeld", "args": {"id": "camera"}}, q))
	assert_false(PredicateEvaluator.evaluate({"op": "itemHeld", "args": {"id": "lockpicks"}}, q))


func test_relationship_at_least() -> void:
	var q := _query()
	q.relationship_tiers["npc.sova"] = 3
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "relationshipAtLeast", "args": {"npc": "npc.sova", "tier": 3}}, q
		)
	)
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "relationshipAtLeast", "args": {"npc": "npc.sova", "tier": 4}}, q
		)
	)


func test_all_combinator() -> void:
	var q := _query()
	q.flags["a"] = true
	q.flags["b"] = true
	var pred_all_true: Dictionary = {
		"op": "all",
		"args":
		{
			"predicates":
			[
				{"op": "flag", "args": {"name": "a"}},
				{"op": "flag", "args": {"name": "b"}},
			]
		}
	}
	assert_true(PredicateEvaluator.evaluate(pred_all_true, q))

	var pred_one_false: Dictionary = {
		"op": "all",
		"args":
		{
			"predicates":
			[
				{"op": "flag", "args": {"name": "a"}},
				{"op": "flag", "args": {"name": "missing"}},
			]
		}
	}
	assert_false(PredicateEvaluator.evaluate(pred_one_false, q))


func test_any_combinator() -> void:
	var q := _query()
	q.flags["a"] = true
	var pred: Dictionary = {
		"op": "any",
		"args":
		{
			"predicates":
			[
				{"op": "flag", "args": {"name": "missing_1"}},
				{"op": "flag", "args": {"name": "a"}},
				{"op": "flag", "args": {"name": "missing_2"}},
			]
		}
	}
	assert_true(PredicateEvaluator.evaluate(pred, q))

	var pred_all_false: Dictionary = {
		"op": "any",
		"args":
		{
			"predicates":
			[
				{"op": "flag", "args": {"name": "missing_1"}},
				{"op": "flag", "args": {"name": "missing_2"}},
			]
		}
	}
	assert_false(PredicateEvaluator.evaluate(pred_all_false, q))


func test_not_combinator() -> void:
	var q := _query()
	q.flags["a"] = true
	assert_false(
		PredicateEvaluator.evaluate(
			{"op": "not", "args": {"predicate": {"op": "flag", "args": {"name": "a"}}}}, q
		)
	)
	assert_true(
		PredicateEvaluator.evaluate(
			{"op": "not", "args": {"predicate": {"op": "flag", "args": {"name": "missing"}}}}, q
		)
	)


func test_nested_combinators() -> void:
	var q := _query()
	q.trust_values["npc.doubek"] = 50
	q.flags["cover_intact"] = true
	var pred: Dictionary = {
		"op": "all",
		"args":
		{
			# all(trustAtLeast(doubek,40), any(flag(cover_intact), flag(never_set)))
			"predicates":
			[
				{"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": 40}},
				{
					"op": "any",
					"args":
					{
						"predicates":
						[
							{"op": "flag", "args": {"name": "cover_intact"}},
							{"op": "flag", "args": {"name": "never_set"}},
						]
					}
				},
				{"op": "not", "args": {"predicate": {"op": "flag", "args": {"name": "never_set"}}}},
			]
		}
	}
	assert_true(PredicateEvaluator.evaluate(pred, q))
