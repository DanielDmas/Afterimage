extends AfterimageTestCase


func test_build_produces_four_rows_in_fixed_order() -> void:
	var mind := MindModel.new()
	var settings := AccessibilitySettings.new()
	var screen: ScreenSpec = MindDashboardScreen.build(mind, settings)
	assert_eq(screen.title, "Dr. Sova's Worksheets")
	assert_eq(screen.rows.size(), 4)
	assert_eq(screen.rows[0]["label"], "Acute Stress")
	assert_eq(screen.rows[1]["label"], "Fatigue")
	assert_eq(screen.rows[2]["label"], "Moral Injury")
	assert_eq(screen.rows[3]["label"], "Identity Strain")


func test_build_defaults_to_band_only_values() -> void:
	var mind := MindModel.new()
	var settings := AccessibilitySettings.new()
	var screen: ScreenSpec = MindDashboardScreen.build(mind, settings)
	assert_eq(screen.rows[0]["value"], "Quiet")


func test_build_includes_numbers_when_setting_enabled() -> void:
	var mind := MindModel.new()
	mind.acute_stress.gain_entering_combat()  # 8
	var settings := AccessibilitySettings.new()
	settings.mind_dashboard_shows_numbers = true
	var screen: ScreenSpec = MindDashboardScreen.build(mind, settings)
	assert_eq(screen.rows[0]["value"], "Quiet (8)")


func test_build_reflects_a_non_quiet_band() -> void:
	var mind := MindModel.new()
	for _i: int in range(4):
		mind.fatigue.gain_skipped_sleep_block()  # 48 -> Murmur
	var settings := AccessibilitySettings.new()
	var screen: ScreenSpec = MindDashboardScreen.build(mind, settings)
	assert_eq(screen.rows[1]["value"], "Murmur")
