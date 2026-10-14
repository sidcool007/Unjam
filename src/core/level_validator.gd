class_name LevelValidator
extends RefCounted
## Development-time (and test-time) level checker. Everything is judged by the
## real BoardState rules; see docs/LEVELS.md.

const MAX_TYPES := 8


## Returns {errors:Array[String], warnings:Array[String], optimal:int, solved:bool}.
## deep=true additionally runs the exhaustive BFS (shortest solution / proof).
static func validate(level: Dictionary, deep: bool = false, budget: int = 300000) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var out := {"errors": errors, "warnings": warnings, "optimal": -1, "solved": false}
	for key in ["id", "types", "trays", "solution"]:
		if not level.has(key):
			errors.append("missing field '%s'" % key)
	if not errors.is_empty():
		return out
	var tag := "level %s" % str(level["id"])
	var types := int(level["types"])
	if types < 1 or types > MAX_TYPES:
		errors.append("%s: types %d out of range 1..%d" % [tag, types, MAX_TYPES])
		return out
	var trays: Array = level["trays"]
	if trays.size() < 2 or trays.size() > 10:
		errors.append("%s: needs 2..10 trays (has %d)" % [tag, trays.size()])
		return out
	var counts := {}
	var total := 0
	var total_cap := 0
	for i in trays.size():
		var t = trays[i]
		if not (t is Dictionary) or not t.has("cap") or not t.has("items"):
			errors.append("%s tray %d: needs 'cap' and 'items'" % [tag, i])
			return out
		var cap := int(t["cap"])
		if cap < 2 or cap > 6:
			errors.append("%s tray %d: capacity %d out of range 2..6" % [tag, i, cap])
		total_cap += cap
		var items: Array = t["items"]
		if items.size() > cap:
			errors.append("%s tray %d: %d items exceed capacity %d" % [tag, i, items.size(), cap])
		var acc := int(t.get("accepts", -1))
		if acc < -1 or acc >= types:
			errors.append("%s tray %d: accepts %d is not a valid type" % [tag, i, acc])
		for it in items:
			var ty: int = int(it["t"]) if it is Dictionary else int(it)
			if ty < 0 or ty >= types:
				errors.append("%s tray %d: object type %d out of range" % [tag, i, ty])
				continue
			counts[ty] = counts.get(ty, 0) + 1
			total += 1
			if it is Dictionary:
				var lk := int(it.get("lock", -1))
				if lk >= types or lk < -1:
					errors.append("%s tray %d: lock key %d is not a type" % [tag, i, lk])
				elif lk == ty:
					errors.append("%s tray %d: object %d is locked by its own type (deadlock)" % [tag, i, ty])
				if int(it.get("ice", 0)) < 0 or int(it.get("ice", 0)) > 60:
					errors.append("%s tray %d: ice value out of range" % [tag, i])
	if not errors.is_empty():
		return out
	for ty in types:
		if not counts.has(ty):
			errors.append("%s: type %d is declared but has no objects" % [tag, ty])
		else:
			var fits := false
			for t in trays:
				var a := int(t.get("accepts", -1))
				if not bool(t.get("source_only", false)) and (a == -1 or a == ty) and int(t["cap"]) == counts[ty]:
					fits = true
			if not fits:
				errors.append("%s: type %d has %d objects but no tray with that exact capacity can clear them" % [tag, ty, counts[ty]])
	if total > total_cap:
		errors.append("%s: %d objects exceed total capacity %d" % [tag, total, total_cap])
	for lv in _all_lock_keys(level):
		if not counts.has(lv):
			errors.append("%s: a lock refers to type %d which does not exist" % [tag, lv])
	if not errors.is_empty():
		return out

	var board := BoardState.from_level(level)
	for i in board.stacks.size():
		var s: PackedInt32Array = board.stacks[i]
		if s.size() == board.caps[i] and not s.is_empty():
			var uniform := true
			for o in s:
				if BoardState.obj_type(o) != BoardState.obj_type(s[0]):
					uniform = false
			if uniform:
				errors.append("%s tray %d starts full and uniform (it could never clear)" % [tag, i])
	if board.is_won():
		errors.append("%s: initial state is already solved" % tag)
	elif not board.has_legal_move():
		errors.append("%s: initial state has no legal move (impossible)" % tag)
	if not errors.is_empty():
		return out

	var sol: Array = level["solution"]
	var rep := Solver.replay(level, sol)
	if not rep["ok"]:
		errors.append("%s: recorded solution invalid: %s" % [tag, rep["error"]])
	else:
		out["solved"] = true
		var mm := int(level.get("max_moves", 0))
		if mm > 0:
			if mm < sol.size():
				errors.append("%s: max_moves %d is below the recorded solution length %d" % [tag, mm, sol.size()])
			elif mm - sol.size() < 2:
				warnings.append("%s: move limit has under 2 spare moves over the recorded solution" % tag)
	if deep and out["solved"]:
		var r := Solver.solve_optimal(board, budget)
		if r["found"]:
			out["optimal"] = r["moves"].size()
			if sol.size() > int(r["moves"].size()) * 2 + 4:
				warnings.append("%s: recorded solution (%d) is far longer than optimal (%d)" % [tag, sol.size(), r["moves"].size()])
		elif r["exhausted"]:
			errors.append("%s: exhaustive search says the level is UNSOLVABLE" % tag)
		else:
			warnings.append("%s: optimal search exceeded budget; relying on recorded solution" % tag)
	return out


static func _all_lock_keys(level: Dictionary) -> Array:
	var keys := []
	for t in level["trays"]:
		for it in t["items"]:
			if it is Dictionary and int(it.get("lock", -1)) >= 0:
				keys.append(int(it["lock"]))
	return keys


## Canonical layout signature (trays sorted within identical configurations).
static func signature(level: Dictionary) -> String:
	return BoardState.from_level(level).key()


## Fraction (0..1) of tray slots with identical contents when compared tray by
## tray; used to flag near-duplicate levels.
static func similarity(a: Dictionary, b: Dictionary) -> float:
	var ta: Array = a["trays"]
	var tb: Array = b["trays"]
	if ta.size() != tb.size() or int(a["types"]) != int(b["types"]):
		return 0.0
	var same := 0
	var all := 0
	for i in ta.size():
		var ia := _types_only(ta[i]["items"])
		var ib := _types_only(tb[i]["items"])
		for j in maxi(ia.size(), ib.size()):
			all += 1
			if j < ia.size() and j < ib.size() and ia[j] == ib[j]:
				same += 1
	return float(same) / float(maxi(all, 1))


static func _types_only(items: Array) -> Array:
	var out := []
	for it in items:
		out.append(int(it["t"]) if it is Dictionary else int(it))
	return out


## Validate a whole campaign: per-level checks plus duplicate/ordering checks.
static func validate_campaign(levels: Array, deep: bool = false) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var seen_ids := {}
	var sigs := {}
	var lens: Array = []
	for lv in levels:
		var r := validate(lv, deep)
		errors.append_array(r["errors"])
		warnings.append_array(r["warnings"])
		var id := int(lv.get("id", -1))
		if seen_ids.has(id):
			errors.append("duplicate level id %d" % id)
		seen_ids[id] = true
		if r["errors"].is_empty():
			var sg := signature(lv)
			if sigs.has(sg):
				errors.append("level %d is identical to level %d" % [id, sigs[sg]])
			sigs[sg] = id
			lens.append([id, (lv["solution"] as Array).size()])
	for i in levels.size():
		if int(levels[i].get("id", -1)) != i + 1:
			errors.append("level ids must be consecutive from 1 (position %d has id %s)" % [i + 1, str(levels[i].get("id"))])
	for i in range(levels.size()):
		for j in range(i + 1, mini(i + 4, levels.size())):
			if levels[i].get("trays") is Array and levels[j].get("trays") is Array:
				if similarity(levels[i], levels[j]) > 0.85:
					warnings.append("levels %d and %d are very similar (%.0f%%)" % [i + 1, j + 1, similarity(levels[i], levels[j]) * 100])
	return {"errors": errors, "warnings": warnings, "lengths": lens}
