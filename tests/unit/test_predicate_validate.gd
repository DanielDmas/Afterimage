extends AfterimageTestCase

## Covers PredicateEvaluator.validate(): pure static structural linting, no
## WorldQuery involved. Operator evaluation semantics live in
## test_predicate_evaluate.gd — split along that seam because the two
## responsibilities are genuinely distinct, not to dodge a lint threshold.


func test_validate_accepts_well_formed_leaf_predicate() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "hasClaim", "args": {"id": "claim.a"}}
	)
	assert_eq(errors.size(), 0)


func test_validate_rejects_unknown_operator() -> void:
	var errors: Array[String] = PredicateEvaluator.validate({"op": "totallyMadeUp", "args": {}})
	assert_gt(errors.size(), 0)


func test_validate_rejects_missing_required_arg() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "trustAtLeast", "args": {"npc": "npc.doubek"}}
	)
	assert_gt(errors.size(), 0, "missing required 'n' arg should be flagged")


func test_validate_rejects_wrong_arg_type() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": "forty"}}
	)
	assert_gt(errors.size(), 0, "'n' should be an int, not a String")


func test_validate_rejects_invalid_mind_band_values() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "mindBand", "args": {"variable": "sanity", "band": "spooky"}}
	)
	assert_gt(errors.size(), 0)


func test_validate_accepts_valid_mind_band_values() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "mindBand", "args": {"variable": "fatigue", "band": "crisis"}}
	)
	assert_eq(errors.size(), 0)


func test_validate_rejects_non_dictionary_predicate() -> void:
	var errors: Array[String] = PredicateEvaluator.validate("not a predicate")
	assert_gt(errors.size(), 0)


func test_validate_rejects_combinator_missing_predicates_key() -> void:
	var errors: Array[String] = PredicateEvaluator.validate({"op": "all", "args": {}})
	assert_gt(errors.size(), 0)


func test_validate_rejects_empty_all_list() -> void:
	var errors: Array[String] = PredicateEvaluator.validate(
		{"op": "all", "args": {"predicates": []}}
	)
	assert_gt(
		errors.size(),
		0,
		"an empty 'all' list is vacuously true and almost certainly an authoring mistake"
	)


func test_validate_surfaces_nested_child_errors_with_path() -> void:
	var pred: Dictionary = {
		"op": "all",
		"args":
		{
			"predicates":
			[
				{"op": "hasClaim", "args": {"id": "claim.a"}},
				{"op": "unknownOp", "args": {}},
			]
		}
	}
	var errors: Array[String] = PredicateEvaluator.validate(pred)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("unknownOp"))
	assert_true(
		errors[0].contains("all[1]"),
		"error path should point at the second child of the 'all' list"
	)


func test_validate_rejects_not_missing_predicate_key() -> void:
	var errors: Array[String] = PredicateEvaluator.validate({"op": "not", "args": {}})
	assert_gt(errors.size(), 0)
