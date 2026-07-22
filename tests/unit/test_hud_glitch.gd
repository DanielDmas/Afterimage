extends AfterimageTestCase

const TRUE_TIME := "23:14"
const GLITCHED_TIME := "23:41"


func _snapshot_with_hud() -> Dictionary:
	return {
		"tick": 1,
		"hud_elements":
		[{"element_id": "clock", "element_kind": "clock_time", "true_value": TRUE_TIME}],
	}


func test_metadata_matches_master_plan_table() -> void:
	var op := HUDGlitch.new("clock", GLITCHED_TIME)
	assert_eq(op.op_class, "HUDGlitch")
	assert_eq(op.tier, 2)
	assert_eq(op.cost, 10)
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_renders_the_glitched_value() -> void:
	var op := HUDGlitch.new("clock", GLITCHED_TIME)
	var percept: Dictionary = op.apply(_snapshot_with_hud())
	var elt: Dictionary = (percept["hud_elements"] as Array)[0]
	assert_eq(elt["rendered_value"], GLITCHED_TIME)
	assert_false(elt["grounded"])


func test_apply_is_a_no_op_without_a_hud_elements_key() -> void:
	var op := HUDGlitch.new("clock", GLITCHED_TIME)
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


## The Charter's "never health, ammo, stamina, input prompts" restriction
## is structural (apply() asserts element_kind is in ALLOWED_ELEMENT_KINDS
## before glitching it — an assert failure aborts the whole test run in
## this codebase's debug-mode headless harness, so that path itself isn't
## exercised here, the same "asserts aren't crash-tested" stance every
## other assert(false, ...) in this codebase already has); this test
## instead proves the bounded set matches the Charter's own enumeration.
func test_bounded_element_kind_set_matches_the_charter() -> void:
	var kinds: Array[String] = HUDGlitch.ALLOWED_ELEMENT_KINDS
	assert_eq(kinds.size(), 4)
	assert_true(kinds.has("map_annotation"))
	assert_true(kinds.has("objective_phrasing"))
	assert_true(kinds.has("clock_time"))
	assert_true(kinds.has("journal_margin_note"))
	assert_false(kinds.has("health"))
	assert_false(kinds.has("ammo"))
	assert_false(kinds.has("stamina"))
	assert_false(kinds.has("input_prompt"))


func test_resolve_grounded_restores_the_true_value() -> void:
	var op := HUDGlitch.new("clock", GLITCHED_TIME)
	var percept: Dictionary = op.apply(_snapshot_with_hud())
	var grounded: Dictionary = op.resolve_grounded(percept)
	var elt: Dictionary = (grounded["hud_elements"] as Array)[0]
	assert_eq(elt["rendered_value"], TRUE_TIME)
	assert_true(elt["grounded"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := HUDGlitch.new("clock", GLITCHED_TIME)
	var truth: Dictionary = _snapshot_with_hud()
	op.apply(truth)
	var elt: Dictionary = (truth["hud_elements"] as Array)[0]
	assert_eq(elt["true_value"], TRUE_TIME)
	assert_false(elt.has("rendered_value"))
