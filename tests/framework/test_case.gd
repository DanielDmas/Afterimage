## Minimal, dependency-free xUnit-style test case base for Godot 4 GDScript.
##
## Built in-house because this project's sandboxed authoring environment has
## no network access to fetch third-party addons (e.g. GUT) — see
## tech_guidelines.md §12 amendment log. The assertion surface below mirrors
## GUT's naming on purpose, so migrating to GUT later (once someone with
## network access can pin its commit via a submodule) is a pure swap of the
## base class and runner, not a rewrite of every test file.
class_name AfterimageTestCase
extends RefCounted

var _failures: Array[String] = []
var _assertions: int = 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func _fail(message: String) -> void:
	_failures.append(message)


func _suffix(message: String) -> String:
	return (" — " + message) if message != "" else ""


func assert_true(condition: bool, message: String = "") -> void:
	_assertions += 1
	if not condition:
		_fail("assert_true failed%s" % _suffix(message))


func assert_false(condition: bool, message: String = "") -> void:
	_assertions += 1
	if condition:
		_fail("assert_false failed%s" % _suffix(message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual != expected:
		_fail("assert_eq failed: expected <%s>, got <%s>%s" % [expected, actual, _suffix(message)])


func assert_ne(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual == expected:
		_fail("assert_ne failed: expected value != <%s>%s" % [expected, _suffix(message)])


func assert_almost_eq(
	actual: float, expected: float, tolerance: float, message: String = ""
) -> void:
	_assertions += 1
	if absf(actual - expected) > tolerance:
		_fail(
			(
				"assert_almost_eq failed: expected <%s> +/- %s, got <%s>%s"
				% [expected, tolerance, actual, _suffix(message)]
			)
		)


func assert_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value != null:
		_fail("assert_null failed: got <%s>%s" % [value, _suffix(message)])


func assert_not_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value == null:
		_fail("assert_not_null failed%s" % _suffix(message))


func assert_gt(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if not (actual > expected):
		_fail(
			"assert_gt failed: expected <%s> to be > <%s>%s" % [actual, expected, _suffix(message)]
		)


func assert_lt(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if not (actual < expected):
		_fail(
			"assert_lt failed: expected <%s> to be < <%s>%s" % [actual, expected, _suffix(message)]
		)


func assert_gte(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if not (actual >= expected):
		_fail(
			(
				"assert_gte failed: expected <%s> to be >= <%s>%s"
				% [actual, expected, _suffix(message)]
			)
		)


func assert_lte(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if not (actual <= expected):
		_fail(
			(
				"assert_lte failed: expected <%s> to be <= <%s>%s"
				% [actual, expected, _suffix(message)]
			)
		)


func fail_test(message: String) -> void:
	_assertions += 1
	_fail(message)


func get_failures() -> Array[String]:
	return _failures


func get_assertion_count() -> int:
	return _assertions
