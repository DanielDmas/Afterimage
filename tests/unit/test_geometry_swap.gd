extends AfterimageTestCase


func _snapshot_with_geometry() -> Dictionary:
	return {"tick": 1, "geometry_cells": [{"cell_id": "corridor_3", "true_kind": "wall"}]}


func test_metadata_matches_master_plan_table() -> void:
	var op := GeometrySwap.new("corridor_3", "door")
	assert_eq(op.op_class, "GeometrySwap")
	assert_eq(op.tier, 3)
	assert_eq(op.cost, 20)
	assert_true(op.fairness_tags.has("charter_rule_4_never_changes_while_observed"))
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_renders_the_swapped_kind_for_the_targeted_cell() -> void:
	var op := GeometrySwap.new("corridor_3", "door")
	var percept: Dictionary = op.apply(_snapshot_with_geometry())
	var cell: Dictionary = (percept["geometry_cells"] as Array)[0]
	assert_eq(cell["rendered_kind"], "door")
	assert_false(cell["grounded"])


func test_apply_is_a_no_op_without_a_geometry_cells_key() -> void:
	var op := GeometrySwap.new("corridor_3", "door")
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


func test_resolve_grounded_restores_the_true_kind() -> void:
	var op := GeometrySwap.new("corridor_3", "door")
	var percept: Dictionary = op.apply(_snapshot_with_geometry())
	var grounded: Dictionary = op.resolve_grounded(percept)
	var cell: Dictionary = (grounded["geometry_cells"] as Array)[0]
	assert_eq(cell["rendered_kind"], "wall")
	assert_true(cell["grounded"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := GeometrySwap.new("corridor_3", "door")
	var truth: Dictionary = _snapshot_with_geometry()
	op.apply(truth)
	var cell: Dictionary = (truth["geometry_cells"] as Array)[0]
	assert_eq(cell["true_kind"], "wall")
	assert_false(cell.has("rendered_kind"))
