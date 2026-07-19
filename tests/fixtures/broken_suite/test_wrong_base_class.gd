## Intentionally broken fixture for test_test_runner.gd: this file loads
## fine (valid GDScript, a real base class) but doesn't extend
## AfterimageTestCase, exercising _run_script()'s other failure branch.
extends RefCounted


func test_this_should_never_actually_run_either() -> void:
	pass
