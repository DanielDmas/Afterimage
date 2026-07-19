extends AfterimageTestCase


func test_default_resolve_grounded_is_identity() -> void:
	var op := DistortionOp.new()
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.resolve_grounded(snapshot), snapshot)


func test_is_a_percept_op() -> void:
	var op := DistortionOp.new()
	assert_true(op is PerceptOp)
