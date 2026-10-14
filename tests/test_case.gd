class_name TestCase
extends RefCounted

var failures: Array = []


func check(cond: bool, msg: String = "check failed") -> void:
	if not cond:
		failures.append(msg)


func eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [msg, str(expected), str(actual)])


## A tiny hand-made level: 2 types, cap 3, one spare tray.
func tiny_level(extra: Dictionary = {}) -> Dictionary:
	var lv := {
		"id": 1, "types": 2,
		"trays": [
			{"cap": 3, "items": [0, 1, 0]},
			{"cap": 3, "items": [1, 0, 1]},
			{"cap": 3, "items": []},
		],
		"solution": [],
	}
	lv.merge(extra, true)
	return lv
