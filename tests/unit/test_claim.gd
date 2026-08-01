extends AfterimageTestCase


func test_constructor_assigns_all_fields() -> void:
	var provenance: Array[Dictionary] = [{"type": Claim.ProvenanceType.PERCEIVED}]
	var qualifiers: Dictionary = {"location": "archive_floor"}
	var claim := Claim.new(
		"claim.m01.second_guard", "player", "saw_entity", "second_guard", qualifiers, provenance
	)
	assert_eq(claim.id, "claim.m01.second_guard")
	assert_eq(claim.subject, "player")
	assert_eq(claim.predicate, "saw_entity")
	assert_eq(claim.object_value, "second_guard")
	assert_eq(claim.qualifiers, qualifiers)
	assert_eq(claim.provenance, provenance)


func test_constructor_defaults_qualifiers_and_provenance_to_empty() -> void:
	var claim := Claim.new("claim.a", "player", "fired_shot", "weapon.cz75")
	assert_eq(claim.qualifiers.size(), 0)
	assert_eq(claim.provenance.size(), 0)


func test_has_provenance_type_true_when_present() -> void:
	var provenance: Array[Dictionary] = [{"type": Claim.ProvenanceType.GROUNDED}]
	var claim := Claim.new("claim.a", "player", "heard_sound", "footsteps", {}, provenance)
	assert_true(claim.has_provenance_type(Claim.ProvenanceType.GROUNDED))
	assert_false(claim.has_provenance_type(Claim.ProvenanceType.EVIDENCE))


func test_has_provenance_type_false_when_provenance_is_empty() -> void:
	var claim := Claim.new("claim.a", "player", "heard_sound", "footsteps")
	assert_false(claim.has_provenance_type(Claim.ProvenanceType.PERCEIVED))


func test_has_provenance_type_checks_across_multiple_entries() -> void:
	var provenance: Array[Dictionary] = [
		{"type": Claim.ProvenanceType.TOLD, "teller": "npc.sova"},
		{"type": Claim.ProvenanceType.PERCEIVED},
	]
	var claim := Claim.new("claim.a", "npc.sova", "location", "archive_floor", {}, provenance)
	assert_true(claim.has_provenance_type(Claim.ProvenanceType.TOLD))
	assert_true(claim.has_provenance_type(Claim.ProvenanceType.PERCEIVED))
	assert_false(claim.has_provenance_type(Claim.ProvenanceType.GROUNDED))
