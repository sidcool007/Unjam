extends TestCase

const R = BoardState.Reason


func test_valid_move_and_top_only() -> void:
	var b := BoardState.from_level(tiny_level())
	eq(b.check_move(0, 2), R.OK, "top object into empty tray")
	var r := b.apply_move(0, 2)
	check(r["ok"])
	eq(b.stacks[0].size(), 2)
	eq(b.stacks[2].size(), 1)
	eq(b.moves, 1)


func test_match_rule_blocks_mismatch() -> void:
	var b := BoardState.from_level(tiny_level({"trays": [
		{"cap": 4, "items": [0, 1, 0]}, {"cap": 4, "items": [1, 0, 1]}, {"cap": 4, "items": []}]}))
	# tray0 top = 0, tray1 top = 1 -> mismatch both ways
	eq(b.check_move(0, 1), R.TYPE_MISMATCH)
	eq(b.check_move(1, 0), R.TYPE_MISMATCH)


func test_invalid_move_changes_nothing() -> void:
	var b := BoardState.from_level(tiny_level())
	var before := b.snapshot()
	var r := b.apply_move(0, 1)
	check(not r["ok"])
	eq(b.snapshot(), before, "state untouched")
	eq(b.apply_move(2, 0)["reason"], R.EMPTY_SOURCE)
	eq(b.apply_move(0, 0)["reason"], R.SAME_TRAY)
	eq(b.apply_move(0, 9)["reason"], R.BAD_TRAY)
	eq(b.apply_move(-1, 0)["reason"], R.BAD_TRAY)
	eq(b.snapshot(), before)


func test_full_tray_rejects() -> void:
	var lv := tiny_level({"trays": [
		{"cap": 3, "items": [0, 1]}, {"cap": 3, "items": [1, 0, 0]},
		{"cap": 3, "items": [0, 1, 1]}]})
	var b := BoardState.from_level(lv)
	eq(b.check_move(0, 1), R.FULL)


func test_tray_clears_when_full_and_uniform() -> void:
	var lv := {"id": 1, "types": 1, "trays": [
		{"cap": 3, "items": [0, 0]}, {"cap": 3, "items": [0]}], "solution": []}
	var b := BoardState.from_level(lv)
	var r := b.apply_move(1, 0)
	check(r["ok"] and r["cleared"], "uniform full tray clears")
	eq(b.stacks[0].size(), 0, "tray emptied")
	check(b.is_won(), "all cleared = won")


func test_restricted_trays() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 2, "items": [0, 1]},
		{"cap": 2, "items": [], "accepts": 0},
		{"cap": 2, "items": [], "source_only": true},
		{"cap": 2, "items": [1]}], "solution": []}
	var b := BoardState.from_level(lv)
	eq(b.check_move(0, 1), R.WRONG_TYPE_FOR_TRAY, "tray accepts only type 0")
	eq(b.check_move(0, 2), R.SOURCE_ONLY)
	eq(b.check_move(0, 3), R.OK)


func test_locked_object_unlocks_when_key_type_cleared() -> void:
	# type 1 object on top of tray 0 is locked until a type-0 tray clears.
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 2, "items": [0, {"t": 1, "lock": 0}]},
		{"cap": 2, "items": [0]},
		{"cap": 2, "items": [1]},
		{"cap": 2, "items": []}], "solution": []}
	var b := BoardState.from_level(lv)
	eq(b.check_move(0, 2), R.LOCKED)
	eq(b.check_pick(0), R.LOCKED)
	# can't clear type 0 first because the locked object blocks tray 0's 0.
	b.stacks[0] = PackedInt32Array([BoardState.make_obj(1, 0)])
	b.stacks[1] = PackedInt32Array([0])
	b.stacks[3] = PackedInt32Array([0])
	# move 0 from tray1 to tray3 -> tray3 full of 0s -> cleared -> unlock
	var r := b.apply_move(1, 3)
	check(r["cleared"])
	eq(r["unlocked"].size(), 1, "one object unlocked")
	eq(b.check_move(0, 2), R.OK, "now movable")


func test_frozen_object_thaws_by_move_count() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 3, "items": [{"t": 0, "ice": 2}]},
		{"cap": 3, "items": [1]},
		{"cap": 3, "items": []},
		{"cap": 3, "items": [1]}], "solution": []}
	var b := BoardState.from_level(lv)
	eq(b.check_move(0, 2), R.FROZEN)
	b.apply_move(1, 2)
	eq(b.check_move(0, 3), R.FROZEN, "still 1 move to go")
	eq(b.thaw_in(b.top_of(0)), 1)
	b.apply_move(3, 2)
	eq(b.check_move(0, 3), R.OK, "thawed after 2 moves")


func test_move_limit_and_failure() -> void:
	var lv := tiny_level({"max_moves": 1})
	var s := GameSession.new(lv)
	var r := s.try_move(0, 2)
	check(r["ok"])
	eq(s.status, GameSession.Status.FAILED, "limit reached without win")
	eq(s.try_move(1, 2)["reason"], R.GAME_OVER)


func test_deadlock_is_failure() -> void:
	# Two full mixed trays and nowhere to go.
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 2, "items": [0, 1]}, {"cap": 2, "items": [1, 0]}], "solution": []}
	var b := BoardState.from_level(lv)
	check(b.is_failed(), "no legal moves")


func test_undo_restores_exact_state() -> void:
	var s := GameSession.new(tiny_level({"max_moves": 20}))
	var snap0 := s.board.snapshot()
	check(s.try_move(0, 2)["ok"])
	check(s.try_move(1, 0)["ok"])
	var snap2 := s.board.snapshot()
	check(s.try_move(1, 2)["ok"])
	check(s.undo())
	eq(s.board.snapshot(), snap2, "undo one")
	check(s.undo())
	check(s.undo())
	eq(s.board.snapshot(), snap0, "undo to start")
	check(not s.undo(), "nothing left to undo")
	eq(s.board.moves, 0)


func test_restart_resets_everything() -> void:
	var s := GameSession.new(tiny_level())
	var snap0 := s.board.snapshot()
	s.try_move(0, 2)
	check(s.has_progress())
	s.restart()
	eq(s.board.snapshot(), snap0)
	check(not s.has_progress())
	check(s.history.is_empty())
	eq(s.status, GameSession.Status.PLAYING)


func test_undo_after_failure_recovers() -> void:
	var s := GameSession.new(tiny_level({"max_moves": 1}))
	s.try_move(0, 2)
	eq(s.status, GameSession.Status.FAILED)
	check(s.undo())
	eq(s.status, GameSession.Status.PLAYING)
	eq(s.board.moves, 0)


func test_clone_is_independent() -> void:
	var b := BoardState.from_level(tiny_level())
	var before := b.snapshot()
	var c := b.clone()
	c.apply_move(0, 2)
	eq(b.snapshot(), before, "original untouched by clone mutation")
	check(c.snapshot() != before)
