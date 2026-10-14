extends TestCase
## Drives the real GameScreen with taps: input locking during animation and
## exactly-once rewards. Needs the autoloads (Progress/Levels/Audio).

var _screen: GameScreen
var _stub: Node


func before_each() -> void:
	Progress.save_path = "user://test_ui_save.json"
	Progress.level_count = Levels.count()
	Progress.reset_all()
	Progress.settings["reduce_motion"] = false


func _open(level: int) -> void:
	_stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(_stub)
	_screen = GameScreen.new()
	_screen.main = _stub
	_screen.level_id = level
	_screen.size = Vector2(720, 1280)
	tree.root.add_child(_screen)
	await tree.process_frame
	await tree.process_frame
	# dismiss any intro card so taps reach the board
	for ch in _screen.get_children():
		if ch is Modal:
			ch.close()
	await tree.process_frame


func _close() -> void:
	await _wait_idle()
	_screen.queue_free()
	_stub.queue_free()
	await tree.process_frame


func _wait_idle() -> void:
	var n := 0
	while _screen.board_view.busy and n < 300:
		await tree.process_frame
		n += 1


func test_repeated_taps_during_animation_apply_one_move() -> void:
	await _open(1)
	var sol: Array = Levels.get_level(1)["solution"]
	var from: int = sol[0][0]
	var to: int = sol[0][1]
	_screen._on_tray_tapped(from)
	_screen._on_tray_tapped(to)         # move starts, animation runs
	check(_screen.board_view.busy, "board is busy while animating")
	var snap := _screen.session.board.snapshot()
	# hammer the screen while the animation plays
	for i in 10:
		_screen._on_tray_tapped(to)
		_screen._on_tray_tapped(from)
		_screen._on_undo()
	eq(_screen.session.board.snapshot(), snap, "taps/undo during animation are ignored")
	eq(_screen.session.board.moves, 1)
	await _wait_idle()
	check(not _screen.board_view.busy)
	# view mirrors the model after the animation
	for i in _screen.session.board.tray_count():
		eq(_screen.board_view.objs[i].size(), _screen.session.board.stacks[i].size(), "tray %d view matches model" % i)
	await _close()


func test_full_playthrough_rewards_exactly_once() -> void:
	await _open(1)
	var coins0: int = Progress.coins
	var sol: Array = Levels.get_level(1)["solution"]
	for mv in sol:
		await _wait_idle()
		_screen._on_tray_tapped(mv[0])
		_screen._on_tray_tapped(mv[1])
	await _wait_idle()
	await tree.process_frame
	await tree.process_frame
	eq(_screen.session.status, GameSession.Status.WON)
	var gained: int = Progress.coins - coins0
	eq(gained, Progress.REWARD_BASE + 3 * Progress.REWARD_PER_STAR, "reward granted once")
	# extra callbacks must not pay again
	_screen._check_terminal()
	_screen._handle_win()
	await tree.process_frame
	eq(Progress.coins - coins0, gained, "no duplicate reward")
	check(Progress.is_completed(1))
	check(Progress.is_unlocked(2))
	check(Progress.tutorial_done, "tutorial marked complete after level 1")
	await _close()


func test_invalid_tap_does_not_change_state() -> void:
	await _open(1)
	var snap := _screen.session.board.snapshot()
	_screen._on_tray_tapped(99)  # nonsense tray index must not crash or change anything
	eq(_screen.session.board.snapshot(), snap)
	await _close()


func test_hint_charges_only_for_valid_hint_and_never_goes_negative() -> void:
	await _open(2)
	Progress.coins = 5
	_screen._on_hint()
	await tree.process_frame
	eq(Progress.coins, 5, "unaffordable hint charges nothing")
	for ch in _screen.get_children():
		if ch is Modal:
			ch.close()
	Progress.coins = 20
	var hint := HintService.get_hint(_screen.session)
	_screen._apply_hint(hint)
	eq(Progress.coins, 20 - Progress.HINT_COST)
	Progress.coins = 3
	_screen._apply_hint(hint)
	eq(Progress.coins, 3, "cannot overspend")
	await _close()


func test_restart_asks_for_confirmation_only_with_progress() -> void:
	await _open(1)
	var before := 0
	for ch in _screen.get_children():
		if ch is Modal:
			before += 1
	_screen._on_restart()   # no progress: restarts directly, no dialog
	await tree.process_frame
	await _wait_idle()
	var after := 0
	for ch in _screen.get_children():
		if ch is Modal:
			after += 1
	eq(after, before)
	var sol: Array = Levels.get_level(1)["solution"]
	_screen._on_tray_tapped(sol[0][0])
	_screen._on_tray_tapped(sol[0][1])
	await _wait_idle()
	_screen._on_restart()
	await tree.process_frame
	var dialogs := 0
	for ch in _screen.get_children():
		if ch is Modal:
			dialogs += 1
	eq(dialogs, before + 1, "confirmation dialog shown")
	eq(_screen.session.board.moves, 1, "nothing lost until confirmed")
	await _close()
