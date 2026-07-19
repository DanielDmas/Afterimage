extends AfterimageTestCase

## Regression test for the exact incident Pass 6's CI run caught: a test
## suite with a real type error made load() return null, and the run
## still printed "ALL PASSED" with that suite's tests silently missing
## from the count. tests/fixtures/broken_suite/ holds two scripts that
## can never legitimately pass (one fails to load, one has the wrong base
## class); run_tests.gd never scans that directory (only tests/unit/), so
## this is the only thing that ever loads them.

const BROKEN_SUITE_DIR := "res://tests/fixtures/broken_suite"


func test_a_suite_that_fails_to_load_is_recorded_as_a_failure_not_silently_skipped() -> void:
	var report: AfterimageTestRunner.RunReport = AfterimageTestRunner.run_directory(
		BROKEN_SUITE_DIR
	)
	assert_false(
		report.all_passed(),
		"a broken suite must never report green (run_tests.gd: 'never a silent green one')"
	)
	assert_eq(report.total_failed(), 2)
	assert_eq(report.total_tests(), 2)


func test_load_failure_reasons_are_recorded_for_both_kinds_of_broken_suite() -> void:
	var report: AfterimageTestRunner.RunReport = AfterimageTestRunner.run_directory(
		BROKEN_SUITE_DIR
	)
	# Deterministic order: run_directory sorts discovered paths, and
	# "broken_type_reference" sorts before "wrong_base_class".
	assert_eq(report.results.size(), 2)
	assert_true(report.results[0].failures[0].contains("failed to load"))
	assert_true(report.results[1].failures[0].contains("does not extend AfterimageTestCase"))
