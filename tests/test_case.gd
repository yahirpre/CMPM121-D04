## Minimal assertions; the runner reads `failures` after each test.
extends RefCounted

var failures: Array[String] = []


func assert_eq(actual: Variant, expected: Variant) -> void:
	if actual != expected:
		failures.append("expected %s, got %s" % [expected, actual])


func assert_almost_eq(actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("expected ~%s, got %s" % [expected, actual])


func assert_true(condition: bool) -> void:
	if not condition:
		failures.append("expected true")
