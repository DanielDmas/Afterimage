## Intentionally broken fixture for test_test_runner.gd: a real load-time
## type error (an undefined type name), not a syntax error — gdlint/
## gdformat parse this file fine (it's syntactically valid GDScript), but
## real Godot's `load()` fails to compile it, returning null. This is
## deliberately outside tests/unit/ so the real suite (tests/run_tests.gd
## only scans tests/unit/) never touches it; only test_test_runner.gd's
## direct run_directory() call against this fixture directory does.
extends AfterimageTestCase


func test_this_should_never_actually_run() -> void:
	var x: ThisTypeDoesNotExistAnywhereInTheProject = null
	assert_true(x == null)
