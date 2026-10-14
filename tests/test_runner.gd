extends SceneTree
## Headless test runner:  godot --headless --path . --script res://tests/test_runner.gd
## Runs every tests/test_*.gd; each file defines test_* methods taking no args
## and uses the inherited assert helpers (see tests/test_case.gd).

func _init() -> void:
	var total := 0
	var failed := 0
	var failures: Array = []
	var dir := DirAccess.open("res://tests")
	var files: Array = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd" and f != "test_runner.gd":
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var tc = script.new()
		var methods: Array = []
		for m in script.get_script_method_list():
			if String(m["name"]).begins_with("test_"):
				methods.append(String(m["name"]))
		methods.sort()
		for m in methods:
			total += 1
			tc.failures.clear()
			if tc.has_method("before_each"):
				tc.before_each()
			tc.call(m)
			if tc.has_method("after_each"):
				tc.after_each()
			if tc.failures.is_empty():
				print("  ok   %s::%s" % [f, m])
			else:
				failed += 1
				print("  FAIL %s::%s" % [f, m])
				for msg in tc.failures:
					print("         - " + msg)
					failures.append("%s::%s: %s" % [f, m, msg])
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)
