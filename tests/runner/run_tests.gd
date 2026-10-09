extends SceneTree
## Headless test runner. Usage (see tools/run-tests.sh):
##   godot --headless --path . -s res://tests/runner/run_tests.gd [-- --filter <text>]
##
## Discovers res://tests/**/test_*.gd, runs every method named test_*, and
## exits with code 1 if anything failed, if a test file could not be loaded,
## or if no tests were found at all. Errors logged by the engine or by scripts
## while a test runs (script errors, push_error) fail that test.
## Under GitHub Actions, failures are also printed as ::error annotations so
## they are readable from the check run.

const TESTS_ROOT: String = "res://tests"
const RUNNER_DIR: String = "res://tests/runner"


class ErrorCollector extends Logger:
	var _mutex: Mutex = Mutex.new()
	var _errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		var text: String = code if rationale.is_empty() else "%s (%s)" % [rationale, code]
		_mutex.lock()
		_errors.append("%s at %s:%d in %s()" % [text, file, line, function])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func take() -> Array[String]:
		_mutex.lock()
		var result: Array[String] = _errors.duplicate()
		_errors.clear()
		_mutex.unlock()
		return result


var _collector: ErrorCollector = ErrorCollector.new()
var _in_ci: bool = OS.get_environment("GITHUB_ACTIONS") == "true"
var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	OS.add_logger(_collector)
	_run.call_deferred()


func _run() -> void:
	var filter: String = _read_filter()
	var files: Array[String] = _find_test_files(TESTS_ROOT)
	files.sort()
	if files.is_empty():
		_report_failure(TESTS_ROOT, "discovery", "no test files found under %s" % TESTS_ROOT)
	for path: String in files:
		await _run_file(path, filter)
	print("")
	print("%d passed, %d failed" % [_passed, _failed])
	if _passed + _failed == 0:
		_report_failure(TESTS_ROOT, "discovery", "no tests ran (filter: '%s')" % filter)
	OS.remove_logger(_collector)
	quit(1 if _failed > 0 else 0)


func _run_file(path: String, filter: String) -> void:
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_report_failure(path, "load", "could not load or instantiate test script")
		_collector.take()
		return
	var instance: Variant = script.new()
	if not instance is TestCase:
		_report_failure(path, "load", "test script does not extend TestCase")
		return
	var test: TestCase = instance
	_collector.take()
	for method: Dictionary in script.get_script_method_list():
		var name: String = method["name"]
		if not name.begins_with("test_"):
			continue
		if not filter.is_empty() and not (path + "::" + name).contains(filter):
			continue
		if test.has_method("before_each"):
			await test.call("before_each")
		await test.call(name)
		if test.has_method("after_each"):
			await test.call("after_each")
		var problems: Array[String] = test.take_failures()
		for error: String in _collector.take():
			problems.append("error logged during test: " + error)
		if problems.is_empty():
			_passed += 1
			print("PASS %s::%s" % [path, name])
		else:
			for problem: String in problems:
				_report_failure(path, name, problem)


func _report_failure(path: String, test_name: String, message: String) -> void:
	_failed += 1
	print("FAIL %s::%s\n     %s" % [path, test_name, message])
	if _in_ci:
		var file: String = path.trim_prefix("res://")
		print("::error file=%s,title=%s::%s" % [file, test_name, message.replace("\n", " ")])


func _find_test_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	if dir_path == RUNNER_DIR:
		return result
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub: String in dir.get_directories():
		result.append_array(_find_test_files(dir_path.path_join(sub)))
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(dir_path.path_join(file))
	return result


func _read_filter() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--filter")
	if index >= 0 and index + 1 < args.size():
		return args[index + 1]
	return ""
