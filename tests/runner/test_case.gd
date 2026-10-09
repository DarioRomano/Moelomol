class_name TestCase
extends RefCounted
## Base class for tests. Put tests in res://tests/**/test_*.gd, extend this
## class, and name each test method test_<something>. Methods may use await.
##
## Optional hooks: before_each() and after_each().
## Any engine or script error logged while a test runs fails that test, even
## if every assertion passed (see run_tests.gd).

var _failures: Array[String] = []


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String) -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s: expected <%s> (%s), got <%s> (%s)" % [
			message, str(expected), type_string(typeof(expected)),
			str(actual), type_string(typeof(actual)),
		])


func assert_ne(actual: Variant, unexpected: Variant, message: String) -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		fail("%s: did not expect <%s>" % [message, str(actual)])


func take_failures() -> Array[String]:
	var result: Array[String] = _failures.duplicate()
	_failures.clear()
	return result
