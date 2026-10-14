extends SceneTree
## DEV TOOL. Builds levels/campaign.json from the spec table in
## tools/level_specs.gd: for each spec it tries seeded random layouts until the
## real rules (BoardState + Solver) prove the layout is solvable with a shortest
## solution length inside the spec's difficulty band. Output is frozen JSON;
## nothing is generated at runtime.
##
##   godot --headless --path . --script res://tools/generate_levels.gd [-- first last]

const Specs = preload("res://tools/level_specs.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var specs: Array = Specs.SPECS
	var first := 1
	var last := specs.size()
	if args.size() >= 2:
		first = int(args[0])
		last = int(args[1])
	var existing := {}
	var f := FileAccess.open("res://levels/campaign.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for lv in d["levels"]:
				existing[int(lv["id"])] = lv
	var levels: Array = []
	for i in specs.size():
		var id := i + 1
		if id < first or id > last:
			if existing.has(id):
				levels.append(existing[id])
			continue
		var t0 := Time.get_ticks_msec()
		var lv := _make_level(id, specs[i])
		if lv.is_empty():
			printerr("FAILED to generate level %d (%s)" % [id, specs[i]["name"]])
			quit(1)
			return
		print("level %2d %-18s seed=%d opt=%d moves_limit=%d  %dms" % [id, lv["name"], lv["seed"], lv["par"], lv.get("max_moves", 0), Time.get_ticks_msec() - t0])
		levels.append(lv)
		_write(levels)  # incremental: a crash or timeout never loses finished levels
	_write(levels)
	print("wrote %d levels" % levels.size())
	quit(0)


func _write(levels: Array) -> void:
	var out := FileAccess.open("res://levels/campaign.json", FileAccess.WRITE)
	out.store_string(_pretty(levels))
	out.close()


func _make_level(id: int, spec: Dictionary) -> Dictionary:
	var base_seed: int = int(spec.get("seed0", id * 1000))
	var started := Time.get_ticks_msec()
	var limit_ms: int = int(spec.get("time_limit_s", 90)) * 1000
	for attempt in 4000:
		if Time.get_ticks_msec() - started > limit_ms:
			return {}
		var seed_v := base_seed + attempt
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v
		var lv := _layout(id, spec, rng)
		lv["seed"] = seed_v
		lv["solution"] = [[0, 1]]  # placeholder so validate() can run structural checks
		if not _structurally_ok(lv):
			continue
		var board := BoardState.from_level(lv)
		if board.is_won() or not board.has_legal_move():
			continue
		var budget: int = int(spec.get("budget", 60000))
		var opt := Solver.solve_optimal(board, budget)
		var moves: Array
		var par: int
		if opt["found"]:
			moves = opt["moves"]
		elif opt["exhausted"]:
			continue  # unsolvable
		else:
			continue  # too big to prove optimal; reject to keep par honest
		par = moves.size()
		if par < int(spec["lo"]) or par > int(spec["hi"]):
			continue
		lv["solution"] = moves
		lv["par"] = par
		var slack: int = int(spec.get("limit", 0))
		if slack > 0:
			lv["max_moves"] = par + slack
		var vr := LevelValidator.validate(lv, false)
		if not vr["errors"].is_empty():
			continue
		return lv
	return {}


func _structurally_ok(lv: Dictionary) -> bool:
	var r := LevelValidator.validate(lv, false)
	for e in r["errors"]:
		if "recorded solution" in e:
			continue
		return false
	return true


func _layout(id: int, spec: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var counts: Array = spec["counts"]
	var caps: Array = spec["caps"]
	var types := counts.size()
	var tray_n := caps.size()
	var order := range(tray_n)
	_shuffle(order, rng)
	var empty_n: int = int(spec.get("empties", 1))
	var empty_set := {}
	# Empty trays: the designated ones are the first `empty_n` of a random order,
	# biased so that each type's exact-capacity tray still exists.
	for k in empty_n:
		empty_set[order[k]] = true
	var items: Array = []
	for t in types:
		for c in counts[t]:
			items.append({"t": t})
	_shuffle(items, rng)
	var fill_trays: Array = []
	for i in tray_n:
		if not empty_set.has(i):
			fill_trays.append(i)
	var trays: Array = []
	for i in tray_n:
		trays.append({"cap": caps[i], "items": []})
	var guard := 0
	for it in items:
		var placed := false
		while not placed and guard < 10000:
			guard += 1
			var ti: int = fill_trays[rng.randi() % fill_trays.size()]
			if trays[ti]["items"].size() < trays[ti]["cap"]:
				trays[ti]["items"].append(it)
				placed = true
		if not placed:
			return {"id": id, "types": types, "trays": [], "name": spec["name"]}
	# Mechanics.
	var all_objs: Array = []
	for tr in trays:
		for it in tr["items"]:
			all_objs.append(it)
	var n_lock: int = int(spec.get("lock", 0))
	var lock_pool := all_objs.duplicate()
	_shuffle(lock_pool, rng)
	for k in mini(n_lock, lock_pool.size()):
		var o: Dictionary = lock_pool[k]
		var key := rng.randi() % types
		var tries := 0
		while key == o["t"] and tries < 20:
			key = rng.randi() % types
			tries += 1
		o["lock"] = key
	var n_ice: int = int(spec.get("ice", 0))
	var ice_pool := all_objs.duplicate()
	_shuffle(ice_pool, rng)
	var made := 0
	for o in ice_pool:
		if made >= n_ice:
			break
		if o.has("lock"):
			continue
		o["ice"] = int(spec.get("ice_min", 3)) + rng.randi() % (int(spec.get("ice_max", 7)) - int(spec.get("ice_min", 3)) + 1)
		made += 1
	var n_acc: int = int(spec.get("accepts", 0))
	var acc_types := range(types)
	_shuffle(acc_types, rng)
	var done_acc := 0
	for i in tray_n:
		if done_acc >= n_acc:
			break
		if trays[i]["items"].is_empty():
			trays[i]["accepts"] = acc_types[done_acc]
			done_acc += 1
	var n_src: int = int(spec.get("source_only", 0))
	var done_src := 0
	for i in tray_n:
		if done_src >= n_src:
			break
		if not trays[i]["items"].is_empty() and not trays[i].has("accepts"):
			trays[i]["source_only"] = true
			done_src += 1
	# Compact: plain int for plain objects.
	for tr in trays:
		var compact: Array = []
		for it in tr["items"]:
			if it.size() == 1:
				compact.append(it["t"])
			else:
				compact.append(it)
		tr["items"] = compact
	var lv := {"id": id, "name": spec["name"], "stage": spec["stage"], "types": types, "trays": trays}
	if spec.has("intro"):
		lv["intro"] = spec["intro"]
	return lv


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _pretty(levels: Array) -> String:
	# One level per line keeps diffs reviewable.
	var lines := PackedStringArray()
	for lv in levels:
		lines.append("    " + JSON.stringify(lv, "", false))
	return "{\n  \"format\": 1,\n  \"levels\": [\n" + ",\n".join(lines) + "\n  ]\n}\n"
