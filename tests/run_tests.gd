extends SceneTree

## Headless test entry point:
##   godot --headless --path . --script res://tests/run_tests.gd
## Exit code 0 = all tests passed; nonzero = at least one failure, or the
## suite failed to discover any tests at all (an empty run is a red build,
## never a silent green one — see RunReport.all_passed()).


func _initialize() -> void:
	var report: AfterimageTestRunner.RunReport = AfterimageTestRunner.run_directory(
		"res://tests/unit"
	)
	AfterimageTestRunner.print_report(report)
	quit(0 if report.all_passed() else 1)
