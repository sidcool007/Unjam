extends TestCase
## Economy, progression, persistence (save/load, corruption, suspend/resume).

const ProgressScript = preload("res://src/services/progress.gd")
const PATH := "user://test_save.json"


func _new_progress(level_count: int = 10) -> Node:
	var p = ProgressScript.new()
	p.save_path = PATH
	p.level_count = level_count
	return p


func before_each() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_new_player_defaults() -> void:
	var p = _new_progress()
	p.load_data()
	eq(p.load_status, "new")
	eq(p.coins, ProgressScript.STARTING_COINS)
	eq(p.highest_unlocked, 1)
	check(p.is_unlocked(1) and not p.is_unlocked(2), "only level 1 unlocked")
	check(not p.tutorial_done)
	p.free()


func test_completion_rewards_exactly_once() -> void:
	var p = _new_progress()
	var start: int = p.coins
	var r1 = p.complete_level(1, 6, 6)
	check(r1["first_time"])
	eq(r1["stars"], 3)
	eq(r1["coins_awarded"], ProgressScript.REWARD_BASE + 3 * ProgressScript.REWARD_PER_STAR)
	eq(p.coins, start + r1["coins_awarded"])
	var after: int = p.coins
	var r2 = p.complete_level(1, 6, 6)  # duplicate callback / replay
	check(not r2["first_time"])
	eq(r2["coins_awarded"], 0, "no second reward")
	eq(p.coins, after)
	p.free()


func test_replay_improves_stars_without_coins() -> void:
	var p = _new_progress()
	p.complete_level(1, 20, 6)  # 1 star
	eq(p.stars_of(1), 1)
	var coins: int = p.coins
	var r = p.complete_level(1, 6, 6)
	check(r["new_best"])
	eq(p.stars_of(1), 3)
	eq(p.coins, coins, "replay never pays")
	p.complete_level(1, 30, 6)  # worse result keeps best
	eq(p.stars_of(1), 3)
	p.free()


func test_unlocking_progression() -> void:
	var p = _new_progress(3)
	check(not p.is_unlocked(2))
	var r = p.complete_level(1, 5, 5)
	check(r["unlocked_next"])
	check(p.is_unlocked(2) and not p.is_unlocked(3))
	p.complete_level(2, 5, 5)
	p.complete_level(3, 5, 5)
	eq(p.highest_unlocked, 3, "capped at level count")
	check(not p.is_unlocked(4))
	p.free()


func test_cannot_complete_nonexistent_level() -> void:
	var p = _new_progress(3)
	var coins: int = p.coins
	var r = p.complete_level(99, 5, 5)
	eq(r["coins_awarded"], 0)
	eq(p.coins, coins)
	p.free()


func test_spend_never_goes_negative() -> void:
	var p = _new_progress()
	p.coins = 20
	check(not p.spend_coins(25), "insufficient")
	eq(p.coins, 20)
	check(not p.spend_coins(0))
	check(not p.spend_coins(-5), "negative spend rejected")
	eq(p.coins, 20)
	check(p.spend_coins(20))
	eq(p.coins, 0)
	check(not p.spend_coins(1))
	eq(p.coins, 0)
	p.add_coins(-10)
	eq(p.coins, 0, "negative reward rejected")
	p.free()


func test_save_load_round_trip() -> void:
	var p = _new_progress()
	p.complete_level(1, 6, 6)
	p.complete_level(2, 12, 6)
	p.coins = 77
	p.tutorial_done = true
	p.mark_intro_seen(1)
	p.settings["music"] = false
	p.current_level = 2
	check(p.save())
	var q = _new_progress()
	q.load_data()
	eq(q.load_status, "ok")
	eq(q.coins, 77)
	eq(q.completed, p.completed)
	eq(q.highest_unlocked, p.highest_unlocked)
	eq(q.current_level, 2)
	check(q.tutorial_done)
	check(q.seen_intros.has(1))
	eq(q.settings["music"], false)
	p.free()
	q.free()


func test_corrupted_save_falls_back_to_defaults() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{not json at all")
	f.close()
	var p = _new_progress()
	p.load_data()
	eq(p.load_status, "reset_corrupt")
	eq(p.coins, ProgressScript.STARTING_COINS)
	eq(p.highest_unlocked, 1)
	p.free()


func test_corrupted_save_recovers_from_backup() -> void:
	var p = _new_progress()
	p.coins = 55
	p.save()   # first write
	p.coins = 60
	p.save()   # second write: previous file becomes .bak
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("garbage")
	f.close()
	var q = _new_progress()
	q.load_data()
	eq(q.load_status, "recovered_backup")
	eq(q.coins, 55, "restored previous good save")
	p.free()
	q.free()


func test_invalid_fields_are_sanitised() -> void:
	var p = _new_progress(10)
	var ok: bool = p.apply_dict({"version": 1, "coins": -500, "highest_unlocked": 999,
		"current_level": "x", "completed": {"3": 9, "bad": 2, "99": 1, "4": "no"},
		"settings": {"sound": "yes", "music": false}, "tutorial_done": "true"})
	check(ok)
	eq(p.coins, 0, "negative coins clamped")
	eq(p.highest_unlocked, 10)
	eq(p.completed.keys(), [3], "only valid completed entries kept")
	eq(p.completed[3], 3, "stars clamped")
	eq(p.settings["sound"], true, "wrong-typed setting ignored")
	eq(p.settings["music"], false)
	check(not p.tutorial_done, "non-bool flag ignored")
	p.free()


func test_unknown_or_missing_version_is_rejected() -> void:
	var p = _new_progress()
	p.coins = 42
	check(not p.apply_dict({"coins": 1}), "no version")
	check(not p.apply_dict({"version": 99, "coins": 1}), "future version")
	check(not p.apply_dict([1, 2]), "not a dictionary")
	check(not p.apply_dict(null))
	eq(p.coins, 42, "state untouched by rejected data")
	p.free()


func test_completed_levels_imply_unlock() -> void:
	var p = _new_progress(10)
	p.apply_dict({"version": 1, "coins": 5, "highest_unlocked": 1, "completed": {"4": 2}})
	check(p.is_unlocked(5), "level after a completed one is unlocked")
	p.free()


func test_suspend_flushes_and_resume_restores_session() -> void:
	var lv := tiny_level({"id": 2, "max_moves": 30})
	var s := GameSession.new(lv)
	s.try_move(0, 2)
	s.try_move(1, 0)
	var p = _new_progress()
	p.save_session(s.to_dict())
	p.mark_intro_seen(2)   # dirty, not yet saved
	p._notification(Node.NOTIFICATION_APPLICATION_PAUSED)  # app suspended
	var q = _new_progress()
	q.load_data()
	check(q.seen_intros.has(2), "pause flushed pending changes")
	var s2 := GameSession.new(lv)
	check(s2.restore_from(q.session), "session restored after resume")
	eq(s2.board.snapshot(), s.board.snapshot())
	eq(s2.history.size(), 2)
	check(s2.undo())
	check(s2.undo())
	eq(s2.board.moves, 0)
	p.free()
	q.free()


func test_session_restore_rejects_bad_data() -> void:
	var lv := tiny_level({"id": 2})
	var s := GameSession.new(lv)
	var before := s.board.snapshot()
	check(not s.restore_from(null))
	check(not s.restore_from({"level": 5, "state": before, "history": []}), "wrong level")
	check(not s.restore_from({"level": 2, "state": {"stacks": [[0, 0, 0, 0, 0]], "moves": 0, "cleared": 0}, "history": []}), "wrong shape")
	check(not s.restore_from({"level": 2, "state": {"stacks": [[9], [], []], "moves": 0, "cleared": 0}, "history": []}), "type out of range")
	check(not s.restore_from({"level": 2, "state": before, "history": "x"}))
	eq(s.board.snapshot(), before, "failed restores leave the session untouched")


func test_restore_does_not_refire_terminal_signals() -> void:
	var lv := tiny_level({"id": 2, "max_moves": 1})
	var s := GameSession.new(lv)
	s.try_move(0, 2)  # fails (limit)
	var saved := s.to_dict()
	var s2 := GameSession.new(lv)
	var fired := [0]
	s2.failed.connect(func(): fired[0] += 1)
	check(s2.restore_from(saved))
	eq(s2.status, GameSession.Status.FAILED)
	eq(fired[0], 0)
