extends TestCase
## Daily puzzle: date -> puzzle mapping, streak rules, persistence, and the screen flow
## (no coins, no campaign progress). Uses a synthetic pool built from campaign levels.

var _stub: Node
var _screen: GameScreen


func before_each() -> void:
	Progress.save_path = "user://test_daily_save.json"
	Progress.level_count = Levels.count()
	Progress.reset_all()
	Progress.settings["reduce_motion"] = true
	_fake_pool(14)


func after_each() -> void:
	DailyLibrary.load_pool()


func _fake_pool(n: int) -> void:
	var pool: Array = []
	for i in n:
		var lv: Dictionary = (Levels.get_level(1 + i % 5) as Dictionary).duplicate(true)
		lv["name"] = "pool %d" % i
		pool.append(lv)
	DailyLibrary._pool = pool
	DailyLibrary._loaded = true


func test_known_dates_map_to_the_right_weekday() -> void:
	eq(DailyLibrary.weekday(DailyLibrary.day_number("2025-01-06")), 0, "2025-01-06 is a Monday")
	eq(DailyLibrary.weekday(DailyLibrary.day_number("2025-01-12")), 6, "2025-01-12 is a Sunday")
	eq(DailyLibrary.weekday(DailyLibrary.day_number("1970-01-01")), 3, "1970-01-01 was a Thursday")
	eq(DailyLibrary.key_for_day(DailyLibrary.day_number("2026-02-28")), "2026-02-28", "key round-trips")
	eq(DailyLibrary.day_number("garbage"), -1)
	eq(DailyLibrary.day_number("2025-13"), -1)


func test_pool_index_matches_weekday_and_is_stable() -> void:
	var d0 := DailyLibrary.day_number("2025-03-03")  # a Monday
	for k in 60:
		var day := d0 + k
		eq(DailyLibrary.index_for_day(day) % 7, DailyLibrary.weekday(day), "tier = weekday on day %d" % k)
		eq(DailyLibrary.index_for_day(day), DailyLibrary.index_for_day(day), "stable")
	# a full pool cycle (14 days here) returns to the same puzzle
	eq(DailyLibrary.index_for_day(d0), DailyLibrary.index_for_day(d0 + 14))
	check(DailyLibrary.index_for_day(d0) != DailyLibrary.index_for_day(d0 + 7), "next Monday is a different puzzle")
	eq(DailyLibrary.level_for("2025-03-03")["name"], DailyLibrary.level_for("2025-03-03")["name"])
	eq(DailyLibrary.level_for("nonsense"), {})


func test_streak_counts_consecutive_days_and_resets_after_a_gap() -> void:
	var r1 := Progress.complete_daily("2025-03-03", 5, 4)
	eq(r1["streak"], 1)
	check(r1["first_today"])
	var again := Progress.complete_daily("2025-03-03", 4, 4)
	eq(again["streak"], 1, "same day does not extend the streak")
	check(not again["first_today"])
	eq(Progress.complete_daily("2025-03-04", 4, 4)["streak"], 2)
	eq(Progress.complete_daily("2025-03-05", 4, 4)["streak"], 3)
	eq(Progress.complete_daily("2025-03-08", 4, 4)["streak"], 1, "a missed day resets the streak")
	eq(Progress.daily_best, 3, "best streak is remembered")
	eq(Progress.coins, 30, "daily puzzles never award coins")


func test_daily_state_persists_and_bad_data_is_ignored() -> void:
	Progress.complete_daily("2025-03-03", 4, 4)
	Progress.complete_daily("2025-03-04", 4, 4)
	var d: Dictionary = JSON.parse_string(JSON.stringify(Progress.to_dict()))
	var q = load("res://src/services/progress.gd").new()
	q.save_path = "user://test_daily_save2.json"
	check(q.apply_dict(d))
	eq(q.daily_streak, 2)
	eq(q.daily_last, "2025-03-04")
	eq(q.daily_best, 2)
	var bad := d.duplicate(true)
	bad["daily"] = {"last": "not-a-date", "streak": -5, "best": "x"}
	var r = load("res://src/services/progress.gd").new()
	check(r.apply_dict(bad))
	eq(r.daily_streak, 0)
	eq(r.daily_last, "")
	var worse := d.duplicate(true)
	worse["daily"] = {"last": "2025-03-04", "streak": 99999999, "best": 1}
	var s = load("res://src/services/progress.gd").new()
	check(s.apply_dict(worse))
	check(s.daily_streak <= 100000 and s.daily_best >= s.daily_streak, "streak clamped, best never below streak")


func test_lapsed_streak_is_shown_as_zero() -> void:
	Progress.daily_last = DailyLibrary.key_for_day(DailyLibrary.day_number(DailyLibrary.today_key()) - 5)
	Progress.daily_streak = 7
	eq(Progress.daily_streak_now(), 0)
	Progress.daily_last = DailyLibrary.key_for_day(DailyLibrary.day_number(DailyLibrary.today_key()) - 1)
	eq(Progress.daily_streak_now(), 7, "yesterday still counts")
	check(not Progress.daily_done_today())
	Progress.daily_last = DailyLibrary.today_key()
	check(Progress.daily_done_today())


func test_daily_screen_win_gives_no_coins_and_leaves_the_campaign_untouched() -> void:
	_stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(_stub)
	_screen = GameScreen.new()
	_screen.main = _stub
	_screen.daily_date = DailyLibrary.today_key()
	_screen.size = Vector2(720, 1280)
	tree.root.add_child(_screen)
	await tree.process_frame
	await tree.process_frame
	check(_screen.is_daily())
	eq(Progress.current_level, 1, "campaign position untouched")
	var sol: Array = _screen.session.level["solution"]
	var coins0: int = Progress.coins
	for mv in sol:
		while _screen.board_view.busy:
			await tree.process_frame
		_screen._on_tray_tapped(mv[0])
		_screen._on_tray_tapped(mv[1])
	for i in 4:
		await tree.process_frame
	while _screen.board_view.busy:
		await tree.process_frame
	await tree.process_frame
	eq(_screen.session.status, GameSession.Status.WON)
	eq(Progress.coins, coins0, "no coins for the daily puzzle")
	check(Progress.daily_done_today())
	eq(Progress.daily_streak, 1)
	check(not Progress.is_completed(1), "campaign completion untouched")
	eq(Progress.highest_unlocked, 1, "no unlocks from the daily puzzle")
	check(Progress.session == null, "daily play never writes the campaign session")
	_screen.queue_free()
	_stub.queue_free()
	await tree.process_frame


func test_shipped_daily_pool_is_valid_and_ramps_through_the_week() -> void:
	check(DailyLibrary.load_pool(), "levels/daily.json loads")
	var pool := DailyLibrary.pool()
	check(pool.size() >= 7 and pool.size() % 7 == 0, "pool size is a whole number of weeks (%d)" % pool.size())
	var sums := [0, 0, 0, 0, 0, 0, 0]
	for i in pool.size():
		var lv: Dictionary = pool[i]
		var r := LevelValidator.validate(lv, false)
		check(r["errors"].is_empty(), "daily %d: %s" % [i + 1, str(r["errors"])])
		eq(int(lv["id"]), i + 1, "ids are positions")
		eq(DailyLibrary.par_of(lv), int(lv["par"]), "par = recorded solution length")
		sums[i % 7] += int(lv["par"])
	var weeks := pool.size() / 7
	check(float(sums[0]) / weeks < float(sums[6]) / weeks, "Monday is easier than Sunday on average")
	check(float(sums[1]) / weeks < float(sums[5]) / weeks, "Tuesday easier than Saturday")
