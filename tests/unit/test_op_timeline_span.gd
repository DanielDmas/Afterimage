extends AfterimageTestCase


func test_constructor_assigns_all_fields() -> void:
	var span := OpTimelineSpan.new(
		"AudioSwap", 1, "acute_stress", 10, 40, OpTimelineSpan.Resolution.GROUNDED
	)
	assert_eq(span.op_class, "AudioSwap")
	assert_eq(span.tier, 1)
	assert_eq(span.cause_variable, "acute_stress")
	assert_eq(span.tick_start, 10)
	assert_eq(span.tick_end, 40)
	assert_eq(span.resolution, OpTimelineSpan.Resolution.GROUNDED)


func test_resolution_defaults_to_undisclosed() -> void:
	var span := OpTimelineSpan.new("PhantomAudio", 1, "moral_injury", 1, 5)
	assert_eq(span.resolution, OpTimelineSpan.Resolution.UNDISCLOSED)


func test_is_active_at_is_inclusive_of_both_endpoints() -> void:
	var span := OpTimelineSpan.new("AudioSwap", 1, "acute_stress", 10, 12)
	assert_false(span.is_active_at(9))
	assert_true(span.is_active_at(10))
	assert_true(span.is_active_at(11))
	assert_true(span.is_active_at(12))
	assert_false(span.is_active_at(13))


func test_is_active_at_handles_a_single_tick_span() -> void:
	var span := OpTimelineSpan.new("PhantomEntity", 3, "moral_injury", 5, 5)
	assert_false(span.is_active_at(4))
	assert_true(span.is_active_at(5))
	assert_false(span.is_active_at(6))
