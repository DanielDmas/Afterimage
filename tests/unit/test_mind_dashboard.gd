extends AfterimageTestCase


func test_snapshot_defaults_to_bands_only_no_numbers() -> void:
	var mind := MindModel.new()
	mind.acute_stress.gain_entering_combat()  # 8, Quiet
	var snapshot: Dictionary = MindDashboard.snapshot(mind)
	assert_eq(snapshot["acute_stress"]["band"], "Quiet")
	assert_false(snapshot["acute_stress"].has("value"))


func test_snapshot_includes_numbers_when_requested() -> void:
	var mind := MindModel.new()
	mind.acute_stress.gain_entering_combat()  # 8
	var snapshot: Dictionary = MindDashboard.snapshot(mind, true)
	assert_eq(snapshot["acute_stress"]["value"], 8)


func test_snapshot_reports_all_four_variables() -> void:
	var mind := MindModel.new()
	var snapshot: Dictionary = MindDashboard.snapshot(mind)
	assert_true(snapshot.has("acute_stress"))
	assert_true(snapshot.has("fatigue"))
	assert_true(snapshot.has("moral_injury"))
	assert_true(snapshot.has("identity_strain"))


func test_snapshot_bands_match_thresholds() -> void:
	var mind := MindModel.new()
	for _i: int in range(4):
		mind.fatigue.gain_skipped_sleep_block()  # 48 -> Murmur
	var snapshot: Dictionary = MindDashboard.snapshot(mind)
	assert_eq(snapshot["fatigue"]["band"], "Murmur")


func test_snapshot_reflects_crisis_band() -> void:
	var mind := MindModel.new()
	for _i: int in range(7):
		mind.moral_injury.gain_civilian_casualty()  # 7 x 15 = 105, clamps to 100 -> Crisis
	var snapshot: Dictionary = MindDashboard.snapshot(mind)
	assert_eq(snapshot["moral_injury"]["band"], "Crisis")
