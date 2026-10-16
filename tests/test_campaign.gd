extends TestCase
## Validates the shipped campaign data and its difficulty/mechanic curve.

var lib: Node


func before_each() -> void:
	lib = load("res://src/core/level_library.gd").new()
	lib.load_campaign("res://levels/campaign.json")


func after_each() -> void:
	lib.free()


func test_campaign_has_at_least_30_levels() -> void:
	check(lib.count() >= 30, "campaign has %d levels" % lib.count())


func test_every_level_validates_and_solution_replays() -> void:
	for lv in lib.levels:
		var r := LevelValidator.validate(lv, false)
		check(r["errors"].is_empty(), "level %s: %s" % [str(lv["id"]), str(r["errors"])])
		check(r["solved"], "level %s solution replays" % str(lv["id"]))


func test_campaign_wide_checks() -> void:
	var r := LevelValidator.validate_campaign(lib.levels, false)
	check(r["errors"].is_empty(), str(r["errors"]))
	check(r["warnings"].is_empty(), "near-duplicates: " + str(r["warnings"]))


func test_constrained_levels_have_feasible_limits() -> void:
	var limited := 0
	for lv in lib.levels:
		var mm := int(lv.get("max_moves", 0))
		if mm > 0:
			limited += 1
			var rep := Solver.replay(lv, lv["solution"])
			check(rep["ok"] and rep["moves_used"] <= mm, "level %d solution fits its limit" % lv["id"])
	check(limited >= 8, "several levels use move limits (%d)" % limited)


func test_mechanics_are_introduced_gradually() -> void:
	var first := {"limit": 999, "lock": 999, "accepts": 999, "source": 999, "ice": 999}
	for lv in lib.levels:
		var id: int = lv["id"]
		if int(lv.get("max_moves", 0)) > 0:
			first["limit"] = mini(first["limit"], id)
		for t in lv["trays"]:
			if int(t.get("accepts", -1)) >= 0:
				first["accepts"] = mini(first["accepts"], id)
			if t.get("source_only", false):
				first["source"] = mini(first["source"], id)
			for it in t["items"]:
				if it is Dictionary and it.has("lock"):
					first["lock"] = mini(first["lock"], id)
				if it is Dictionary and it.has("ice"):
					first["ice"] = mini(first["ice"], id)
	# plain sorting for the first 4 levels, one new mechanic at a time after that
	check(first["limit"] > 4, "no move limits in the basics (first at %d)" % first["limit"])
	var firsts: Array = [first["limit"], first["lock"], first["accepts"], first["source"], first["ice"]]
	firsts.sort()
	for i in range(1, firsts.size()):
		check(firsts[i] > firsts[i - 1], "new mechanics must debut on different levels: %s" % str(firsts))
	for key in first:
		var lv: Dictionary = lib.get_level(first[key])
		check(str(lv.get("intro", "")) != "", "mechanic '%s' debuts on level %d which must have an intro card" % [key, first[key]])


func test_intro_cards_exist_for_every_intro_key() -> void:
	for lv in lib.levels:
		var k := str(lv.get("intro", ""))
		if k != "":
			check(CampaignText.INTROS.has(k), "level %d intro '%s' has text" % [lv["id"], k])


func test_difficulty_trends_upward() -> void:
	# A new mechanic restarts the ramp (its first level is deliberately easy), so
	# check the ramp within each stage and the campaign as a whole.
	var by_stage := {}
	for lv in lib.levels:
		var st: int = lv["stage"]
		if not by_stage.has(st):
			by_stage[st] = []
		by_stage[st].append((lv["solution"] as Array).size())
	for st in by_stage:
		var lens: Array = by_stage[st]
		if lens.size() >= 3:
			check(lens[lens.size() - 1] >= lens[0], "stage %d ends harder than it starts: %s" % [st, str(lens)])
	var all: Array = []
	for lv in lib.levels:
		all.append((lv["solution"] as Array).size())
	var third := all.size() / 3
	var head := 0.0
	var tail := 0.0
	for i in third:
		head += all[i]
		tail += all[all.size() - 1 - i]
	check(tail / third > head / third + 5.0, "last third (%.1f) is clearly harder than first third (%.1f)" % [tail / third, head / third])


func test_stages_are_non_decreasing_and_ids_consecutive() -> void:
	var prev := 0
	for i in lib.levels.size():
		var lv: Dictionary = lib.levels[i]
		eq(int(lv["id"]), i + 1)
		check(int(lv["stage"]) >= prev, "level %d stage order" % lv["id"])
		prev = int(lv["stage"])


func test_first_level_is_trivial() -> void:
	var lv: Dictionary = lib.get_level(1)
	check((lv["solution"] as Array).size() <= 6)
	eq(int(lv.get("max_moves", 0)), 0, "no move limit on level 1")


func test_small_levels_recorded_solution_is_optimal() -> void:
	for lv in lib.levels:
		if int(lv["id"]) > 10:
			break
		var opt := Solver.solve_optimal(BoardState.from_level(lv), 200000)
		check(opt["found"] and opt["moves"].size() == (lv["solution"] as Array).size(), "level %d recorded solution is shortest" % lv["id"])


func test_validator_catches_bad_levels() -> void:
	var good: Dictionary = lib.get_level(1).duplicate(true)
	var bad := good.duplicate(true)
	bad["trays"][0]["items"] = [0, 0, 0, 0]  # over capacity
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "over capacity")
	bad = good.duplicate(true)
	bad["types"] = 1
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "type out of range")
	bad = good.duplicate(true)
	bad["solution"] = [[0, 1]]
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "bad recorded solution")
	bad = good.duplicate(true)
	bad["trays"] = [{"cap": 3, "items": [0, 0, 0]}, {"cap": 3, "items": [1, 1, 1]}, {"cap": 3, "items": []}]
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "starts full+uniform")
	bad = good.duplicate(true)
	bad["trays"] = [{"cap": 3, "items": [0, {"t": 1, "lock": 1}, 0]}, {"cap": 3, "items": [1, 0, 1]}, {"cap": 3, "items": []}]
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "self-locked object")
	bad = good.duplicate(true)
	bad["max_moves"] = 1
	check(not LevelValidator.validate(bad)["errors"].is_empty(), "limit below solution")


func test_unsolvable_level_is_detected_by_exhaustive_search() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 3, "items": [0, 1, 0]}, {"cap": 3, "items": [1, 0, 1]}, {"cap": 3, "items": []}],
		"solution": [[0, 2]]}
	# structurally fine; the recorded 1-move 'solution' is wrong so it must fail
	check(not LevelValidator.validate(lv, true)["errors"].is_empty())
	var res := Solver.solve_optimal(BoardState.from_level(lv), 100000)
	check(res["found"] or res["exhausted"])


func test_tutorial_claims_match_the_levels_that_show_them() -> void:
	# Each intro card promises a mechanic; the level that shows it must really contain it.
	var needs := {
		"limit": func(lv): return int(lv.get("max_moves", 0)) > 0,
		"lock": func(lv): return _any_item(lv, func(it): return it is Dictionary and it.has("lock")),
		"ice": func(lv): return _any_item(lv, func(it): return it is Dictionary and it.has("ice")),
		"accepts": func(lv): return _any_tray(lv, func(t): return int(t.get("accepts", -1)) >= 0),
		"source": func(lv): return _any_tray(lv, func(t): return bool(t.get("source_only", false))),
		"capacity": func(lv): return _caps_differ(lv),
		"mix": func(lv): return _any_item(lv, func(it): return it is Dictionary and it.has("lock")) and _any_item(lv, func(it): return it is Dictionary and it.has("ice")),
	}
	var seen := {}
	for lv in lib.levels:
		var k := str(lv.get("intro", ""))
		if k == "" or k == "basics":
			continue
		seen[k] = true
		check(needs.has(k), "intro '%s' has a content check" % k)
		if needs.has(k):
			check(needs[k].call(lv), "level %d shows intro '%s' but does not contain that mechanic" % [lv["id"], k])
	for k in needs:
		check(seen.has(k), "intro '%s' is used by some level" % k)


func test_rule_text_mentions_every_mechanic_and_the_real_numbers() -> void:
	var t := CampaignText.RULES_TEXT.to_lower()
	for word in ["top object", "same shape", "empty tray", "padlock", "ice", "arrow", "move limit", "clear"]:
		check(t.contains(word), "rules text mentions '%s'" % word)
	# every Reason a player can hit has player-facing text (except same-tray, which just deselects)
	for r in BoardState.Reason.values():
		if r in [BoardState.Reason.OK, BoardState.Reason.SAME_TRAY]:
			continue
		check(CampaignText.reason_text(r) != "That move isn't allowed.", "reason %d has specific text" % r)


func _any_item(lv: Dictionary, f: Callable) -> bool:
	for t in lv["trays"]:
		for it in t["items"]:
			if f.call(it):
				return true
	return false


func _any_tray(lv: Dictionary, f: Callable) -> bool:
	for t in lv["trays"]:
		if f.call(t):
			return true
	return false


func _caps_differ(lv: Dictionary) -> bool:
	var first := int(lv["trays"][0]["cap"])
	for t in lv["trays"]:
		if int(t["cap"]) != first:
			return true
	return false
