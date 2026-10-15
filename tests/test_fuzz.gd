extends TestCase
## Randomised exploration of every level: thousands of random taps/moves/undos/
## restarts with invariants checked after every single action.

const R = BoardState.Reason


func _items(b: BoardState) -> int:
	return b.object_count()


func _check_invariants(lv_id: int, s: GameSession, step: int, cleared_objs: int, initial_total: int) -> bool:
	var b := s.board
	var tag := "L%d step %d" % [lv_id, step]
	for i in b.tray_count():
		var st: PackedInt32Array = b.stacks[i]
		if st.size() > b.caps[i]:
			failures.append("%s: tray %d over capacity" % [tag, i])
			return false
		if st.size() == b.caps[i] and not st.is_empty():
			var u := true
			for o in st:
				if BoardState.obj_type(o) != BoardState.obj_type(st[0]):
					u = false
			if u:
				failures.append("%s: tray %d is full+uniform but was not cleared" % [tag, i])
				return false
		if b.accepts[i] != -1:
			for o in st:
				if BoardState.obj_type(o) != b.accepts[i]:
					failures.append("%s: reserved tray %d holds a foreign type" % [tag, i])
					return false
	if _items(b) + cleared_objs != initial_total:
		failures.append("%s: object count %d + cleared %d != %d" % [tag, _items(b), cleared_objs, initial_total])
		return false
	if s.history.size() != b.moves and s.history.size() < 400:
		failures.append("%s: history %d != moves %d" % [tag, s.history.size(), b.moves])
		return false
	# status must agree with the model
	var won := b.is_won()
	var failed := b.is_failed()
	if won and s.status != GameSession.Status.WON:
		failures.append("%s: board won but status %d" % [tag, s.status])
		return false
	if failed and s.status != GameSession.Status.FAILED:
		failures.append("%s: board failed but status %d" % [tag, s.status])
		return false
	if not won and not failed and s.status != GameSession.Status.PLAYING:
		failures.append("%s: status %d but board is still playable" % [tag, s.status])
		return false
	# legal_moves() must equal brute force over check_move()
	var brute := 0
	for f in b.tray_count():
		for t in b.tray_count():
			if b.check_move(f, t) == R.OK:
				brute += 1
	if brute != b.legal_moves().size():
		failures.append("%s: legal_moves() disagrees with check_move()" % tag)
		return false
	# frozen/locked tops can never be picked
	for i in b.tray_count():
		if not (b.stacks[i] as PackedInt32Array).is_empty():
			var top := b.top_of(i)
			var pick := b.check_pick(i)
			if (b.is_locked(top) and pick != R.LOCKED) or (not b.is_locked(top) and b.is_frozen(top) and pick != R.FROZEN):
				failures.append("%s: pick rule wrong on tray %d" % [tag, i])
				return false
			if pick == R.OK and (b.is_locked(top) or b.is_frozen(top)):
				failures.append("%s: blocked object pickable" % tag)
				return false
	return true


func test_random_play_keeps_invariants_on_every_level() -> void:
	var lib: Node = load("res://src/core/level_library.gd").new()
	lib.load_campaign("res://levels/campaign.json")
	var actions := 0
	for lv in lib.levels:
		for seed_v in 3:
			var rng := RandomNumberGenerator.new()
			rng.seed = int(lv["id"]) * 100 + seed_v
			var s := GameSession.new(lv)
			var total := s.board.object_count()
			var cleared := 0
			var shadow: Array = []   # snapshots taken before each applied move (our own history)
			var shadow_cleared: Array = []
			var n := s.board.tray_count()
			for step in 260:
				actions += 1
				var r := rng.randi() % 100
				var before := s.board.snapshot()
				if r < 70:
					var f := rng.randi_range(-1, n)   # includes invalid indices
					var t := rng.randi_range(-1, n)
					if rng.randf() < 0.5 and not s.board.legal_moves().is_empty() and s.status == GameSession.Status.PLAYING:
						var lm: Array = s.board.legal_moves()
						var mv: Array = lm[rng.randi() % lm.size()]
						f = mv[0]
						t = mv[1]
					var legal := s.board.check_move(f, t) == R.OK and s.status == GameSession.Status.PLAYING
					var res := s.try_move(f, t)
					if res["ok"] != legal:
						failures.append("L%d: try_move ok=%s but check_move legal=%s" % [lv["id"], res["ok"], legal])
						return
					if res["ok"]:
						shadow.append(before)
						shadow_cleared.append(cleared)
						if res["cleared"]:
							cleared += s.board.caps[t]
						if s.board.moves != int(before["moves"]) + 1:
							failures.append("L%d: move counter wrong" % lv["id"])
							return
					elif s.board.snapshot() != before:
						failures.append("L%d: rejected move changed state (%d->%d)" % [lv["id"], f, t])
						return
				elif r < 90:
					var could := s.can_undo()
					var ok := s.undo()
					if ok != could:
						failures.append("L%d: can_undo/undo disagree" % lv["id"])
						return
					if ok:
						var want: Dictionary = shadow.pop_back()
						cleared = shadow_cleared.pop_back()
						if s.board.snapshot() != want:
							failures.append("L%d step %d: undo did not restore the exact previous state" % [lv["id"], step])
							return
					elif s.board.snapshot() != before:
						failures.append("L%d: failed undo changed state" % lv["id"])
						return
				elif r < 94:
					s.restart()
					shadow.clear()
					shadow_cleared.clear()
					cleared = 0
					if s.board.moves != 0 or s.board.object_count() != total or s.board.cleared_mask != 0 or not s.history.is_empty():
						failures.append("L%d: restart did not reset" % lv["id"])
						return
				if not _check_invariants(lv["id"], s, step, cleared, total):
					return
	print("      %d random actions, all invariants held" % actions)
	lib.free()


func test_win_exactly_at_move_limit_is_a_win() -> void:
	var lv := tiny_level({"max_moves": 2, "types": 1, "trays": [
		{"cap": 2, "items": [0]}, {"cap": 2, "items": [0]}]})
	var s := GameSession.new(lv)
	var wins := [0]
	var fails := [0]
	s.won.connect(func(): wins[0] += 1)
	s.failed.connect(func(): fails[0] += 1)
	s.try_move(0, 1)
	eq(s.status, GameSession.Status.WON)
	eq(wins[0], 1)
	eq(fails[0], 0)
	var lv2 := tiny_level({"max_moves": 1, "types": 1, "trays": [
		{"cap": 2, "items": [0]}, {"cap": 2, "items": [0]}]})
	var s2 := GameSession.new(lv2)
	s2.try_move(0, 1)   # last allowed move wins: must not be reported as out of moves
	eq(s2.status, GameSession.Status.WON)


func test_undo_after_clear_restores_tray_and_locks() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 2, "items": [{"t": 1, "lock": 0}]},
		{"cap": 2, "items": [0]}, {"cap": 2, "items": [0]}, {"cap": 2, "items": [1]}], "solution": []}
	var s := GameSession.new(lv)
	var before := s.board.snapshot()
	var r := s.try_move(1, 2)       # clears a tray of type 0, opening the lock
	check(r["ok"] and r["cleared"])
	eq(s.board.check_pick(0), R.OK, "lock open after clear")
	check(s.undo())
	eq(s.board.snapshot(), before)
	eq(s.board.check_pick(0), R.LOCKED, "undo re-locks the object")
	eq(s.board.cleared_mask, 0)


func test_undo_restores_frozen_countdown() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 3, "items": [{"t": 0, "ice": 3}]}, {"cap": 3, "items": [1]},
		{"cap": 3, "items": []}, {"cap": 3, "items": [1]}], "solution": []}
	var s := GameSession.new(lv)
	s.try_move(1, 2)
	s.try_move(3, 2)
	eq(s.board.thaw_in(s.board.top_of(0)), 1)
	s.undo()
	eq(s.board.thaw_in(s.board.top_of(0)), 2)
	s.undo()
	eq(s.board.thaw_in(s.board.top_of(0)), 3)
	eq(s.board.check_pick(0), R.FROZEN)
