extends AfterimageTestCase


## A trivial test-only DistortionOp — the same pattern test_clarity_mode.gd
## (Pass 10) and test_percept_renderer.gd (Pass 8) already established —
## just enough to prove clarity_flags_for() actually delegates to
## ClarityMode.active_flags() rather than reimplementing it.
class _StubOp:
	extends DistortionOp

	func _init() -> void:
		op_class = "AudioSwap"
		tier = 1
		cost = 8
		dramatic_intent = "doubt"


func test_ui_scale_defaults_to_step_zero_factor_one() -> void:
	var settings := AccessibilitySettings.new()
	assert_eq(settings.ui_scale_step, 0)
	assert_eq(settings.ui_scale_factor(), 1.0)


func test_set_ui_scale_step_changes_the_factor() -> void:
	var settings := AccessibilitySettings.new()
	settings.set_ui_scale_step(3)
	assert_eq(settings.ui_scale_factor(), 1.5)


func test_subtitle_size_defaults_to_step_zero_factor_one() -> void:
	var settings := AccessibilitySettings.new()
	assert_eq(settings.subtitle_size_factor(), 1.0)


func test_set_subtitle_size_step_changes_the_factor() -> void:
	var settings := AccessibilitySettings.new()
	settings.set_subtitle_size_step(2)
	assert_eq(settings.subtitle_size_factor(), 1.5)


func test_toggle_defaults_are_all_off() -> void:
	var settings := AccessibilitySettings.new()
	assert_false(settings.colorblind_safe_mode)
	assert_false(settings.photosensitivity_safe_mode)
	assert_false(settings.clarity_mode_enabled)
	assert_false(settings.screen_reader_enabled)
	assert_false(settings.mind_dashboard_shows_numbers)
	assert_eq(settings.ground_input_mode, AccessibilitySettings.GroundInputMode.HOLD)


func test_clarity_flags_for_returns_empty_when_disabled() -> void:
	var settings := AccessibilitySettings.new()
	var flags: Array = settings.clarity_flags_for([_StubOp.new()])
	assert_eq(flags.size(), 0)


func test_clarity_flags_for_delegates_to_clarity_mode_when_enabled() -> void:
	var settings := AccessibilitySettings.new()
	settings.clarity_mode_enabled = true
	var flags: Array = settings.clarity_flags_for([_StubOp.new()])
	assert_eq(flags.size(), 1)
	assert_eq(flags[0]["op_class"], "AudioSwap")
