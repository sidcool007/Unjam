extends SceneTree
## DEV TOOL: full campaign validation incl. exhaustive shortest-solution proof.
##   godot --headless --path . --script res://tools/validate_levels.gd
## Exit code 1 if any error is found.

func _initialize() -> void:
	var lib: Node = load("res://src/core/level_library.gd").new()
	if not lib.load_campaign("res://levels/campaign.json"):
		printerr("cannot load campaign: " + lib.load_error)
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var deep_budget := 600000
	var report := LevelValidator.validate_campaign(lib.levels, false)
	var errors: Array = report["errors"]
	var warnings: Array = report["warnings"]
	print("%-3s %-18s %-5s %-5s %-6s %s" % ["id", "name", "par", "limit", "optimal", "mechanics"])
	for lv in lib.levels:
		var r := LevelValidator.validate(lv, true, deep_budget)
		errors.append_array(r["errors"])
		warnings.append_array(r["warnings"])
		var mech := []
		var locks := 0
		var ice := 0
		for t in lv["trays"]:
			for it in t["items"]:
				if it is Dictionary:
					if it.has("lock"):
						locks += 1
					if it.has("ice"):
						ice += 1
			if int(t.get("accepts", -1)) >= 0:
				mech.append("reserved")
			if t.get("source_only", false):
				mech.append("one-way")
		if locks > 0:
			mech.append("%d locks" % locks)
		if ice > 0:
			mech.append("%d ice" % ice)
		print("%-3d %-18s %-5d %-5d %-6d %s" % [lv["id"], lv["name"], (lv["solution"] as Array).size(), int(lv.get("max_moves", 0)), r["optimal"], ", ".join(mech)])
	print("")
	for w in warnings:
		print("WARNING: " + w)
	for e in errors:
		printerr("ERROR: " + e)
	print("%d levels, %d errors, %d warnings, %.1fs" % [lib.levels.size(), errors.size(), warnings.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	lib.free()
	quit(1 if not errors.is_empty() else 0)
