extends AfterimageTestCase


func test_drafts_one_claim_per_event_with_perceived_provenance() -> void:
	var events: Array[Dictionary] = [
		{"id": "claim.a", "subject": "player", "predicate": "fired_shot", "object": "weapon.cz75"},
		{"id": "claim.b", "subject": "player", "predicate": "heard_sound", "object": "footsteps"},
	]
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(events)
	assert_eq(claims.size(), 2)
	assert_eq(claims[0].id, "claim.a")
	assert_eq(claims[1].id, "claim.b")
	for claim: Claim in claims:
		assert_true(claim.has_provenance_type(Claim.ProvenanceType.PERCEIVED))


func test_draft_carries_qualifiers_when_present() -> void:
	var events: Array[Dictionary] = [
		{
			"id": "claim.a",
			"subject": "player",
			"predicate": "saw_entity",
			"object": "second_guard",
			"qualifiers": {"location": "archive_floor"},
		}
	]
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(events)
	assert_eq(claims[0].qualifiers, {"location": "archive_floor"})


## The AC's "a believed-phantom claim drafts correctly": a PhantomEntity
## the player acted on ("a second guard was present") drafts an identical
## Claim to a real event's — drafting only ever looks at what was
## perceived, never at truth (master_plan §4.10's "quiet knife"). Whether
## it's actually true is a later, separate question (DebriefLedger's
## truth-delta), not this class's to answer.
func test_believed_phantom_event_drafts_a_claim_identically_to_a_real_one() -> void:
	var phantom_event: Dictionary = {
		"id": "claim.m01.second_guard",
		"subject": "player",
		"predicate": "saw_entity",
		"object": "second_guard",
	}
	var real_event: Dictionary = {
		"id": "claim.m01.real_guard",
		"subject": "player",
		"predicate": "saw_entity",
		"object": "real_guard",
	}
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events([phantom_event, real_event])

	var phantom_claim: Claim = claims[0]
	var real_claim: Claim = claims[1]
	assert_eq(phantom_claim.predicate, real_claim.predicate)
	assert_eq(phantom_claim.subject, real_claim.subject)
	assert_true(phantom_claim.has_provenance_type(Claim.ProvenanceType.PERCEIVED))
	assert_true(real_claim.has_provenance_type(Claim.ProvenanceType.PERCEIVED))
	# Nothing about the drafted claim itself marks the phantom one as
	# suspect - that's exactly the point.
	assert_eq(phantom_claim.provenance, real_claim.provenance)


func test_empty_event_list_drafts_no_claims() -> void:
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events([])
	assert_eq(claims.size(), 0)
