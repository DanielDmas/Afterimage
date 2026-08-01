extends AfterimageTestCase


func test_sentry_has_no_report() -> void:
	var sentry: AiArchetype = AiArchetype.sentry()
	assert_false(sentry.uses_report)
	assert_eq(sentry.vision_range_mm, 6000)


func test_professional_uses_report_and_sees_farther() -> void:
	var professional: AiArchetype = AiArchetype.professional()
	assert_true(professional.uses_report)
	assert_gt(professional.vision_range_mm, AiArchetype.sentry().vision_range_mm)


func test_professional_has_a_wider_cone_than_sentry() -> void:
	# A wider FOV -> a smaller cos^2(half-angle) (cos shrinks as angle grows).
	var sentry: AiArchetype = AiArchetype.sentry()
	var professional: AiArchetype = AiArchetype.professional()
	assert_lt(professional.vision_cos_sq_half_angle_fx, sentry.vision_cos_sq_half_angle_fx)


func test_custom_archetype_constructor() -> void:
	var custom := AiArchetype.new(12000, 45.0, true)
	assert_eq(custom.vision_range_mm, 12000)
	assert_true(custom.uses_report)
	assert_almost_eq(FixedMath.to_float(custom.vision_cos_sq_half_angle_fx), 0.5, 0.0005)
