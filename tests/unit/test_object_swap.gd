extends AfterimageTestCase


func _snapshot_with_props() -> Dictionary:
	return {
		"tick": 1,
		"props": [{"id": 4, "position": Vector2i(100, 200), "true_kind": "dropped_phone"}],
	}


func test_metadata_matches_master_plan_table() -> void:
	var op := ObjectSwap.new(4, "pistol")
	assert_eq(op.op_class, "ObjectSwap")
	assert_eq(op.tier, 2)
	assert_eq(op.cost, 12)
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_renders_the_swapped_kind_for_the_targeted_prop() -> void:
	var op := ObjectSwap.new(4, "pistol")
	var percept: Dictionary = op.apply(_snapshot_with_props())
	var prop: Dictionary = (percept["props"] as Array)[0]
	assert_eq(prop["rendered_kind"], "pistol")
	assert_false(prop["grounded"])


func test_apply_leaves_non_targeted_props_untouched() -> void:
	var op := ObjectSwap.new(4, "pistol")
	var snapshot: Dictionary = {
		"tick": 1, "props": [{"id": 9, "position": Vector2i(0, 0), "true_kind": "briefcase"}]
	}
	var percept: Dictionary = op.apply(snapshot)
	var prop: Dictionary = (percept["props"] as Array)[0]
	assert_false(prop.has("rendered_kind"))


func test_apply_is_a_no_op_without_a_props_key() -> void:
	var op := ObjectSwap.new(4, "pistol")
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


func test_resolve_grounded_restores_the_true_kind() -> void:
	var op := ObjectSwap.new(4, "pistol")
	var percept: Dictionary = op.apply(_snapshot_with_props())
	var grounded: Dictionary = op.resolve_grounded(percept)
	var prop: Dictionary = (grounded["props"] as Array)[0]
	assert_eq(prop["rendered_kind"], "dropped_phone")
	assert_true(prop["grounded"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := ObjectSwap.new(4, "pistol")
	var truth: Dictionary = _snapshot_with_props()
	op.apply(truth)
	var prop: Dictionary = (truth["props"] as Array)[0]
	assert_eq(prop["true_kind"], "dropped_phone")
	assert_false(prop.has("rendered_kind"))
