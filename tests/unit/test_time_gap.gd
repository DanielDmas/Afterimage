extends AfterimageTestCase


func test_metadata_matches_master_plan_table() -> void:
	var op := TimeGap.new(900)
	assert_eq(op.op_class, "TimeGap")
	assert_eq(op.tier, 4)
	assert_eq(op.cost, 30)
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_marks_the_snapshot_as_gapped() -> void:
	var op := TimeGap.new(900)
	var percept: Dictionary = op.apply({"tick": 1, "actors": []})
	assert_true(percept["time_gap"]["active"])
	assert_eq(percept["time_gap"]["true_duration_ticks"], 900)


func test_apply_never_touches_other_snapshot_keys() -> void:
	var op := TimeGap.new(900)
	var truth: Dictionary = {"tick": 1, "actors": [{"id": 1, "position": Vector2i(0, 0)}]}
	var percept: Dictionary = op.apply(truth)
	assert_eq(percept["actors"], truth["actors"])


## "Cannot be grounded during (it already happened)": unlike every other
## op, resolve_grounded() re-applies the same gap marker rather than
## revealing anything.
func test_resolve_grounded_still_marks_the_snapshot_as_gapped() -> void:
	var op := TimeGap.new(900)
	var grounded: Dictionary = op.resolve_grounded({"tick": 1, "actors": []})
	assert_true(grounded["time_gap"]["active"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := TimeGap.new(900)
	var truth: Dictionary = {"tick": 1, "actors": []}
	op.apply(truth)
	assert_false(truth.has("time_gap"))
