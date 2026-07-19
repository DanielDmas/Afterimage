extends AfterimageTestCase

## Per master_plan.md §10's spec ("static analysis of decks... against the
## Charter") and roadmap.md's AC ("each Charter rule has a fixture deck
## that fails it"): one deliberately-violating fixture per §4.5 rule below.
## _FakeOp lets each fixture control exactly one property at a time without
## needing every taxonomy class (EntityMask/GeometrySwap aren't implemented
## yet — Pass 9 built 4 of the 10) to already exist for real.


## A minimal stand-in DistortionOp — real op classes always set correct
## metadata in their own _init(), so a genuinely-violating fixture needs a
## test double whose fields can be set wrong on purpose.
class _FakeOp:
	extends DistortionOp

	func _init(
		p_op_class: String, p_fairness_tags: Array, p_dramatic_intent: String = "dread"
	) -> void:
		op_class = p_op_class
		tier = 1
		cost = 5
		dramatic_intent = p_dramatic_intent
		fairness_tags = p_fairness_tags


## Same duck-typed shape as a DistortionOp (op_class/tier/cost/
## dramatic_intent/fairness_tags all present as properties), but does NOT
## extend DistortionOp — Clarity Mode's `is DistortionOp` check (Pass 10)
## would silently skip this, which is exactly what rule 6 exists to catch.
class _FakeNonDistortionOp:
	extends RefCounted

	var op_class: String = "SubtitleDrift"
	var tier: int = 1
	var cost: int = 5
	var dramatic_intent: String = "dread"
	var fairness_tags: Array = [
		"charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"
	]


const FULL_TAGS: Array = [
	"charter_rule_1_never_damages_never_blocks",
	"charter_rule_2_never_masks_damage_capable_entities",
	"charter_rule_3_inputs_never_distorted",
	"charter_rule_4_never_changes_while_observed",
	"charter_rule_5_always_disclosable",
]


func _tags_excluding(excluded_tag: String) -> Array:
	var tags: Array = []
	for tag: String in FULL_TAGS:
		if tag != excluded_tag:
			tags.append(tag)
	return tags


func _any_violation_has_prefix(violations: Array, prefix: String) -> bool:
	for violation: String in violations:
		if violation.begins_with(prefix):
			return true
	return false


func test_a_real_op_with_full_tags_passes() -> void:
	var deck: Array = [SubtitleDrift.new("mishearing")]
	assert_eq(FairnessAuditor.validate(deck, 3), [])
	assert_true(FairnessAuditor.passes(deck, 3))


func test_rule_1_phantom_missing_never_damages_tag_fails() -> void:
	var tags_without_rule_1: Array = _tags_excluding("charter_rule_1_never_damages_never_blocks")
	var deck: Array = [_FakeOp.new("PhantomEntity", tags_without_rule_1)]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_1:"))


func test_rule_2_entity_mask_missing_never_masks_damage_capable_tag_fails() -> void:
	var tags_without_rule_2: Array = _tags_excluding(
		"charter_rule_2_never_masks_damage_capable_entities"
	)
	var deck: Array = [_FakeOp.new("EntityMask", tags_without_rule_2)]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_2:"))


func test_rule_3_any_op_missing_inputs_never_distorted_tag_fails() -> void:
	var tags_without_rule_3: Array = _tags_excluding("charter_rule_3_inputs_never_distorted")
	var deck: Array = [_FakeOp.new("SubtitleDrift", tags_without_rule_3)]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_3:"))


func test_rule_4_geometry_swap_missing_never_changes_while_observed_tag_fails() -> void:
	var tags_without_rule_4: Array = _tags_excluding("charter_rule_4_never_changes_while_observed")
	var deck: Array = [_FakeOp.new("GeometrySwap", tags_without_rule_4)]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_4:"))


func test_rule_5_any_op_missing_always_disclosable_tag_fails() -> void:
	var tags_without_rule_5: Array = _tags_excluding("charter_rule_5_always_disclosable")
	var deck: Array = [_FakeOp.new("AudioSwap", tags_without_rule_5)]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_5:"))


func test_rule_6_entry_that_is_not_a_real_distortion_op_fails() -> void:
	var deck: Array = [_FakeNonDistortionOp.new()]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_6:"))


func test_rule_7_encounter_cap_exceeding_the_global_max_fails() -> void:
	var deck: Array = [SubtitleDrift.new("mishearing")]
	var violations: Array = FairnessAuditor.validate(deck, 5)
	assert_true(_any_violation_has_prefix(violations, "rule_7:"))


func test_rule_8_op_with_no_valid_dramatic_intent_fails() -> void:
	var deck: Array = [_FakeOp.new("PhantomAudio", FULL_TAGS, "confusion")]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_true(_any_violation_has_prefix(violations, "rule_8:"))


func test_unknown_op_class_is_flagged_and_short_circuits_further_per_entry_checks() -> void:
	var deck: Array = [_FakeOp.new("InputRewriter", [])]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_eq(violations, ["unknown_op_class:InputRewriter"])


func test_multiple_violations_in_one_deck_are_all_reported() -> void:
	var deck: Array = [
		_FakeOp.new("PhantomEntity", []),  # missing rule 1, 3, 5
		SubtitleDrift.new("mishearing"),  # clean
	]
	var violations: Array = FairnessAuditor.validate(deck, 3)
	assert_eq(violations.size(), 3)
