extends AfterimageTestCase


func test_constructor_defaults() -> void:
	var f := InputFrame.new()
	assert_eq(f.tick, 0)
	assert_eq(f.inputs, {})


func test_constructor_with_values() -> void:
	var f := InputFrame.new(7, {"move_x": 1, "roll": true})
	assert_eq(f.tick, 7)
	assert_eq(f.inputs, {"move_x": 1, "roll": true})


func test_to_dict_and_from_dict_round_trip() -> void:
	var original := InputFrame.new(42, {"move_x": -1, "move_y": 1, "roll": false})
	var restored := InputFrame.from_dict(original.to_dict())
	assert_eq(restored.tick, original.tick)
	assert_eq(restored.inputs, original.inputs)
	assert_true(restored.equals(original))


func test_from_dict_defaults_on_missing_keys() -> void:
	var f := InputFrame.from_dict({})
	assert_eq(f.tick, 0)
	assert_eq(f.inputs, {})


func test_equals_detects_differences() -> void:
	var a := InputFrame.new(1, {"move_x": 1})
	var b := InputFrame.new(1, {"move_x": 2})
	var c := InputFrame.new(2, {"move_x": 1})
	assert_false(a.equals(b), "different inputs must not be equal")
	assert_false(a.equals(c), "different ticks must not be equal")


func test_constructor_duplicates_input_dict_defensively() -> void:
	var shared: Dictionary = {"move_x": 1}
	var f := InputFrame.new(1, shared)
	shared["move_x"] = 999
	assert_eq(f.inputs["move_x"], 1, "InputFrame must not alias the caller's dictionary")
