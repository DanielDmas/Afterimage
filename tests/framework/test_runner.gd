## Scans a directory for test_*.gd files whose classes extend
## AfterimageTestCase, runs every test_*() method in each on a fresh
## instance (no state leaks between tests), and produces a plain-text
## report + pass/fail totals. Driven headlessly by tests/run_tests.gd:
##   godot --headless --path . --script res://tests/run_tests.gd
class_name AfterimageTestRunner
extends RefCounted


class CaseResult:
	var script_path: String
	var method_name: String
	var passed: bool
	var failures: Array[String] = []
	var assertion_count: int = 0


class RunReport:
	var results: Array[CaseResult] = []
	var suites_run: int = 0

	func total_tests() -> int:
		return results.size()

	func total_failed() -> int:
		var n: int = 0
		for r: CaseResult in results:
			if not r.passed:
				n += 1
		return n

	func total_assertions() -> int:
		var n: int = 0
		for r: CaseResult in results:
			n += r.assertion_count
		return n

	func all_passed() -> bool:
		return suites_run > 0 and total_failed() == 0 and total_tests() > 0


static func run_directory(dir_path: String) -> RunReport:
	var report := RunReport.new()
	var file_paths: Array[String] = _find_test_scripts(dir_path)
	file_paths.sort()  # deterministic run order regardless of filesystem order

	for file_path: String in file_paths:
		report.suites_run += 1
		_run_script(file_path, report)

	return report


static func _find_test_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("AfterimageTestRunner: cannot open directory %s" % dir_path)
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				found.append_array(_find_test_scripts(full_path))
			elif entry.begins_with("test_") and entry.ends_with(".gd"):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


static func _run_script(file_path: String, report: RunReport) -> void:
	var script: GDScript = load(file_path)
	if script == null:
		push_error("AfterimageTestRunner: failed to load %s" % file_path)
		return

	var probe: Object = script.new()
	if not (probe is AfterimageTestCase):
		push_error(
			"AfterimageTestRunner: %s does not extend AfterimageTestCase, skipping" % file_path
		)
		return

	var test_method_names: Array[String] = []
	for m: Dictionary in probe.get_method_list():
		var method_name: String = m["name"]
		if method_name.begins_with("test_"):
			test_method_names.append(method_name)
	test_method_names.sort()

	for method_name: String in test_method_names:
		var instance: AfterimageTestCase = script.new()
		instance.before_each()
		instance.call(method_name)
		instance.after_each()

		var result := CaseResult.new()
		result.script_path = file_path
		result.method_name = method_name
		result.failures = instance.get_failures()
		result.assertion_count = instance.get_assertion_count()
		result.passed = result.failures.is_empty()
		report.results.append(result)


static func print_report(report: RunReport) -> void:
	print("=".repeat(70))
	print(
		(
			"Afterimage test run — %d suite(s), %d test(s), %d assertion(s)"
			% [report.suites_run, report.total_tests(), report.total_assertions()]
		)
	)
	print("=".repeat(70))
	for result: CaseResult in report.results:
		if result.passed:
			print("  [PASS] %s :: %s" % [result.script_path, result.method_name])
		else:
			print("  [FAIL] %s :: %s" % [result.script_path, result.method_name])
			for f: String in result.failures:
				print("         - %s" % f)
	print("-".repeat(70))
	if report.all_passed():
		print("ALL PASSED (%d/%d)" % [report.total_tests(), report.total_tests()])
	else:
		print(
			(
				"FAILURES: %d/%d tests failed (%d suite(s) run)"
				% [report.total_failed(), report.total_tests(), report.suites_run]
			)
		)
	print("=".repeat(70))
