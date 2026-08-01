extends AfterimageTestCase

const TRUE_ENTRY := "Left the safehouse at 22:00, alone."
const EDITED_ENTRY := "Left the safehouse at 22:00. Someone was waiting outside."


func _snapshot_with_journal() -> Dictionary:
	return {"tick": 1, "journal_entries": [{"entry_id": "night_3", "true_text": TRUE_ENTRY}]}


func test_metadata_matches_master_plan_table() -> void:
	var op := MemoryEdit.new("night_3", EDITED_ENTRY)
	assert_eq(op.op_class, "MemoryEdit")
	assert_eq(op.tier, 4)
	assert_eq(op.cost, 30)
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_renders_the_edited_text_not_the_true_text() -> void:
	var op := MemoryEdit.new("night_3", EDITED_ENTRY)
	var percept: Dictionary = op.apply(_snapshot_with_journal())
	var entry: Dictionary = (percept["journal_entries"] as Array)[0]
	assert_eq(entry["rendered_text"], EDITED_ENTRY)
	assert_false(entry["grounded"])


func test_apply_is_a_no_op_without_a_journal_entries_key() -> void:
	var op := MemoryEdit.new("night_3", EDITED_ENTRY)
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


## The one Ground response in the whole taxonomy that isn't a clean
## revert: both the true entry and the edited one the player actually
## read stay visible (master_plan.md §4.2).
func test_resolve_grounded_keeps_both_versions_visible() -> void:
	var op := MemoryEdit.new("night_3", EDITED_ENTRY)
	var percept: Dictionary = op.apply(_snapshot_with_journal())
	var grounded: Dictionary = op.resolve_grounded(percept)
	var entry: Dictionary = (grounded["journal_entries"] as Array)[0]
	assert_eq(entry["rendered_text"], TRUE_ENTRY)
	assert_eq(entry["edited_text_disclosed"], EDITED_ENTRY)
	assert_true(entry["grounded"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := MemoryEdit.new("night_3", EDITED_ENTRY)
	var truth: Dictionary = _snapshot_with_journal()
	op.apply(truth)
	var entry: Dictionary = (truth["journal_entries"] as Array)[0]
	assert_eq(entry["true_text"], TRUE_ENTRY)
	assert_false(entry.has("rendered_text"))
