extends AfterimageTestCase


func test_timing_constants_match_the_art_direction_spec() -> void:
	assert_eq(MotionConstants.MICRO_INTERACTION_MS, 120)
	assert_eq(MotionConstants.PANEL_TRANSITION_MS, 180)
	assert_eq(MotionConstants.SCENE_TRANSITION_MS, 300)


func test_timings_are_strictly_increasing_micro_to_scene() -> void:
	assert_lt(MotionConstants.MICRO_INTERACTION_MS, MotionConstants.PANEL_TRANSITION_MS)
	assert_lt(MotionConstants.PANEL_TRANSITION_MS, MotionConstants.SCENE_TRANSITION_MS)


func test_input_acknowledgement_budget_matches_spec() -> void:
	assert_eq(MotionConstants.INPUT_ACKNOWLEDGEMENT_MAX_MS, 100)
