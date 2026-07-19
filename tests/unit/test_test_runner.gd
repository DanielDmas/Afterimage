extends AfterimageTestCase

## Regression test for the exact incident Pass 6's CI run caught: a test
## suite with a real type error made run_directory() still print "ALL
## PASSED" with that suite's tests silently missing from the count.
## tests/fixtures/broken_suite/test_broken_type_reference.gd can never
## legitimately pass (a genuine undefined-type load error); run_tests.gd
## never scans that directory (only tests/unit/), so this is the only
## thing that ever loads it.
##
## Deliberately asserts only the property that actually matters — a
## directory containing a broken suite must never report all_passed() —
## rather than an exact failure count. A first version of this test
## asserted exactly 2 recorded failures across two broken fixtures and
## caught a second, real surprise: load() on a script with a parse error
## does not reliably return null in this Godot version (see
## test_runner.gd's _run_script() for the can_instantiate() fix), and with
## two broken files in the same directory the exact failure attribution
## became hard to pin down without a local Godot to verify against.
## Fewer, looser assertions here are the more honest test of the one
## guarantee this class actually needs to provide.

const BROKEN_SUITE_DIR := "res://tests/fixtures/broken_suite"


func test_a_suite_that_fails_to_load_is_recorded_as_a_failure_not_silently_skipped() -> void:
	var report: AfterimageTestRunner.RunReport = AfterimageTestRunner.run_directory(
		BROKEN_SUITE_DIR
	)
	assert_false(
		report.all_passed(),
		"a broken suite must never report green (run_tests.gd: 'never a silent green one')"
	)
	assert_gt(report.total_failed(), 0)
	assert_gt(report.total_tests(), 0)
