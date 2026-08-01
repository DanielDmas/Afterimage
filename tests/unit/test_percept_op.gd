extends AfterimageTestCase


func test_default_apply_is_identity() -> void:
	var op := PerceptOp.new()
	var snapshot: Dictionary = {"tick": 5, "actors": [{"id": 1, "position": Vector2i(10, 20)}]}
	assert_eq(op.apply(snapshot), snapshot)
