extends TestCase
## Follow hints from the start of every level: each must be legal, the level
## must be won, and the first hint of each level must come back quickly.

const MAX_FIRST_HINT_MS := 1500


func test_following_hints_wins_every_level() -> void:
	var lib: Node = load("res://src/core/level_library.gd").new()
	lib.load_campaign("res://levels/campaign.json")
	var worst_ms := 0
	var worst_level := 0
	for lv in lib.levels:
		var s := GameSession.new(lv)
		var guard := 0
		var first := true
		while s.status == GameSession.Status.PLAYING and guard < 120:
			guard += 1
			var t0 := Time.get_ticks_msec()
			var h := HintService.get_hint(s)
			var dt := Time.get_ticks_msec() - t0
			if first:
				first = false
				if dt > worst_ms:
					worst_ms = dt
					worst_level = lv["id"]
			if h["kind"] != HintService.Kind.MOVE:
				failures.append("level %d: no hint at move %d (%s)" % [lv["id"], s.board.moves, str(h)])
				break
			var r := s.try_move(h["from"], h["to"])
			if not r["ok"]:
				failures.append("level %d: hint illegal at move %d" % [lv["id"], s.board.moves])
				break
		check(s.status == GameSession.Status.WON, "level %d won by following hints (status %d after %d moves)" % [lv["id"], s.status, s.board.moves])
	print("      worst first-hint time: %d ms (level %d)" % [worst_ms, worst_level])
	check(worst_ms <= MAX_FIRST_HINT_MS, "first hint took %d ms on level %d" % [worst_ms, worst_level])
	lib.free()


func test_hints_work_after_leaving_the_authored_path() -> void:
	# A player who deviates from the recorded solution must still get a prompt, legal, useful hint.
	var lib: Node = load("res://src/core/level_library.gd").new()
	lib.load_campaign("res://levels/campaign.json")
	var worst := 0
	var worst_level := 0
	for lv in lib.levels:
		var s := GameSession.new(lv)
		var sol: Array = lv["solution"]
		var moved := false
		for mv in s.board.legal_moves():
			if mv != [int(sol[0][0]), int(sol[0][1])]:
				s.try_move(mv[0], mv[1])
				moved = true
				break
		if not moved or s.status != GameSession.Status.PLAYING:
			continue
		var t0 := Time.get_ticks_msec()
		var h := HintService.get_hint(s)
		var dt := Time.get_ticks_msec() - t0
		if dt > worst:
			worst = dt
			worst_level = lv["id"]
		check(h["kind"] != HintService.Kind.UNAVAILABLE or int(h.get("rewind", 0)) > 0, "level %d: neither a hint nor a rewind instruction off the authored path" % lv["id"])
		if h["kind"] == HintService.Kind.UNAVAILABLE:
			# the rewind instruction must be true: undoing that many moves puts the player back on the authored path
			var n := int(h["rewind"])
			for k in n:
				s.undo()
			check(HintService._on_authored_path(s, sol), "level %d: rewind of %d does not reach the authored path" % [lv["id"], n])
			continue
		if h["kind"] == HintService.Kind.MOVE:
			check(s.board.check_move(h["from"], h["to"]) == BoardState.Reason.OK, "level %d: illegal hint off-path" % lv["id"])
	print("      worst off-path hint time: %d ms (level %d)" % [worst, worst_level])
	check(worst <= 2500, "off-path hint took %d ms on level %d" % [worst, worst_level])
	lib.free()
