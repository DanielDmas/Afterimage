extends AfterimageTestCase


func test_flags_all_four_pass_9_ops_correctly() -> void:
	var ops: Array = [
		SubtitleDrift.new("drifted"),
		AudioSwap.new(1, "alarm"),
		PhantomAudio.new(Vector2i(0, 0), "footsteps"),
		PhantomEntity.new(Vector2i(0, 0), "dog"),
	]
	var flags: Array = ClarityMode.active_flags(ops)
	assert_eq(flags.size(), 4)
	assert_eq(flags[0], {"op_class": "SubtitleDrift", "tier": 1})
	assert_eq(flags[1], {"op_class": "AudioSwap", "tier": 1})
	assert_eq(flags[2], {"op_class": "PhantomAudio", "tier": 1})
	assert_eq(flags[3], {"op_class": "PhantomEntity", "tier": 3})


func test_no_active_ops_yields_no_flags() -> void:
	assert_eq(ClarityMode.active_flags([]), [])


func test_a_plain_percept_op_with_no_distortion_metadata_is_not_flagged() -> void:
	var ops: Array = [PerceptOp.new()]
	assert_eq(ClarityMode.active_flags(ops), [])
