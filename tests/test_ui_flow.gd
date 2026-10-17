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


func _open(level: int, dismiss_dialogs: bool = true) -> void:
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
	if dismiss_dialogs:
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


func test_modal_button_callback_runs_once_on_double_press() -> void:
	await _open(1)
	var count := [0]
	var m := Modal.make("t")
	var b := m.add_button("Go", "primary", func(): count[0] += 1)
	_screen.add_child(m)
	await tree.process_frame
	b.pressed.emit()
	b.pressed.emit()          # second tap lands before the dialog is freed
	eq(count[0], 1, "callback executed once")
	await _close()


func test_double_tapping_undo_in_fail_dialog_undoes_only_one_move() -> void:
	await _open(11)
	# play until the move limit is reached (always a legal random-ish move)
	var guard := 0
	while _screen.session.status == GameSession.Status.PLAYING and guard < 80:
		guard += 1
		await _wait_idle()
		var lm: Array = _screen.session.board.legal_moves()
		if lm.is_empty():
			break
		var mv: Array = lm[guard % lm.size()]
		_screen._on_tray_tapped(mv[0])
		_screen._on_tray_tapped(mv[1])
	await _wait_idle()
	await tree.process_frame
	await tree.process_frame
	eq(_screen.session.status, GameSession.Status.FAILED)
	var moves_at_fail: int = _screen.session.board.moves
	var fail_modal: Modal = null
	for ch in _screen.get_children():
		if ch is Modal:
			fail_modal = ch
	check(fail_modal != null, "failure dialog shown")
	var undo_btn: Button = fail_modal._buttons.get_child(0)
	undo_btn.pressed.emit()
	undo_btn.pressed.emit()
	await _wait_idle()
	eq(_screen.session.board.moves, moves_at_fail - 1, "exactly one move undone")
	await _close()


func test_restored_failed_session_shows_failure_dialog() -> void:
	var lv: Dictionary = Levels.get_level(11)
	var s := GameSession.new(lv)
	var guard := 0
	while s.status == GameSession.Status.PLAYING and guard < 80:
		guard += 1
		var lm: Array = s.board.legal_moves()
		if lm.is_empty():
			break
		var mv: Array = lm[guard % lm.size()]
		s.try_move(mv[0], mv[1])
	eq(s.status, GameSession.Status.FAILED)
	Progress.session = s.to_dict()    # e.g. app killed on the failure screen
	await _open(11, false)
	await tree.process_frame
	var found := false
	for ch in _screen.get_children():
		if ch is Modal:
			found = true
	check(found, "failure dialog offered after restoring a failed session")
	await _close()


func test_rapid_shakes_and_selection_never_leave_things_off_grid() -> void:
	await _open(1)
	var bv := _screen.board_view
	for k in 6:
		bv.shake(0)
		bv.shake(1)
		await tree.process_frame
	bv.select(1)
	bv.deselect()
	bv.select(1)
	bv.shake(2)
	bv.deselect()
	for k in 40:
		await tree.process_frame
	check(bv.settled())
	for i in bv.trays.size():
		check(absf(bv.trays[i].position.x - bv._tray_base_x[i]) < 0.01, "tray %d back on its column" % i)
		for j in bv.objs[i].size():
			check((bv.objs[i][j] as ObjectView).position.distance_to(bv._slot_pos(i, j)) < 0.5, "object %d/%d on its slot" % [i, j])
	await _close()


func _play_level1_to_win() -> void:
	var sol: Array = Levels.get_level(1)["solution"]
	for mv in sol:
		await _wait_idle()
		_screen._on_tray_tapped(mv[0])
		_screen._on_tray_tapped(mv[1])
	await _wait_idle()
	for i in 4:
		await tree.process_frame


func _find_label_starting(prefix: String) -> Label:
	for l in _screen.find_children("*", "Label", true, false):
		if (l as Label).text.begins_with(prefix):
			return l
	return null


func test_reward_animation_ends_on_the_exact_values() -> void:
	Progress.settings["reduce_motion"] = false
	await _open(1)
	await _play_level1_to_win()
	var want := "+%d coins" % (Progress.REWARD_BASE + 3 * Progress.REWARD_PER_STAR)
	var n := 0
	var lbl := _find_label_starting("+")
	while (lbl == null or lbl.text != want) and n < 240:
		await tree.process_frame
		lbl = _find_label_starting("+")
		n += 1
	check(lbl != null and lbl.text == want, "count-up ends on %s (got %s)" % [want, lbl.text if lbl else "none"])
	eq(Progress.coins, Progress.STARTING_COINS + Progress.REWARD_BASE + 3 * Progress.REWARD_PER_STAR, "balance paid once")
	await _close()


func test_reduce_motion_shows_final_reward_immediately() -> void:
	await _open(1)
	Progress.settings["reduce_motion"] = true
	_screen.board_view.reduce_motion = true
	await _play_level1_to_win()
	var want := "+%d coins" % (Progress.REWARD_BASE + 3 * Progress.REWARD_PER_STAR)
	var lbl := _find_label_starting("+")
	check(lbl != null and lbl.text == want, "no count-up with reduced motion")
	Progress.settings["reduce_motion"] = false
	await _close()


func test_restart_is_not_next_to_hint() -> void:
	await _open(1)
	var r := _screen._restart_btn.get_index()
	var u := _screen._undo_btn.get_index()
	var h := _screen._hint_btn.get_index()
	check(r < u and u < h, "order is Restart, Undo, Hint (indexes %d %d %d)" % [r, u, h])
	await _close()


func _modal_count() -> int:
	var n := 0
	for ch in _screen.get_children():
		if ch is Modal and not ch.is_queued_for_deletion():
			n += 1
	return n


func test_intro_card_shows_once_then_never_interrupts_again() -> void:
	Progress.seen_intros = {}
	Progress.highest_unlocked = Levels.count()
	await _open(15, false)
	await tree.process_frame
	eq(_modal_count(), 1, "intro card shown the first time")
	for ch in _screen.get_children():
		if ch is Modal:
			ch.close()
	await _close()
	check(Progress.seen_intros.has(15), "remembered")
	await _open(15, false)
	await tree.process_frame
	eq(_modal_count(), 0, "no interruption on later visits")
	await _close()


func _hint_flags(bv: BoardView) -> int:
	var n := 0
	for t in bv.trays:
		if t.hint_target:
			n += 1
	return n


func test_hint_highlight_persists_until_the_next_interaction() -> void:
	await _open(2)
	Progress.coins = 60
	_screen._apply_hint(HintService.get_hint(_screen.session))
	var bv := _screen.board_view
	check(_hint_flags(bv) >= 1, "hint highlight shown")
	for i in 40:
		await tree.process_frame
	check(_hint_flags(bv) >= 1, "still shown after 40 frames (no timeout)")
	_screen._on_tray_tapped(0)     # any next interaction clears it
	eq(_hint_flags(bv), 0, "cleared by the next tap")
	await _close()


func test_undo_and_restart_leave_no_stale_hint() -> void:
	await _open(2)
	Progress.coins = 90
	var mv: Array = Levels.get_level(2)["solution"][0]
	_screen._on_tray_tapped(mv[0])
	_screen._on_tray_tapped(mv[1])
	await _wait_idle()
	_screen._apply_hint(HintService.get_hint(_screen.session))
	check(_hint_flags(_screen.board_view) >= 1)
	_screen._on_undo()
	await _wait_idle()
	eq(_hint_flags(_screen.board_view), 0, "undo clears the hint")
	for ov in _screen.board_view.objs[mv[0]]:
		eq((ov as ObjectView).scale, Vector2.ONE, "no object left pulsed")
	_screen._apply_hint(HintService.get_hint(_screen.session))
	check(_hint_flags(_screen.board_view) >= 1)
	_screen.session.try_move(mv[0], mv[1])   # make restart meaningful
	_screen._do_restart()
	await _wait_idle()
	eq(_hint_flags(_screen.board_view), 0, "restart clears the hint")
	await _close()


func test_stale_hint_is_never_charged() -> void:
	await _open(2)
	Progress.coins = 50
	var stale := {"kind": HintService.Kind.MOVE, "from": 0, "to": 0, "message": ""}  # illegal now
	_screen._apply_hint(stale)
	eq(Progress.coins, 50, "an illegal/stale hint costs nothing")
	eq(_hint_flags(_screen.board_view), 0, "and shows nothing")
	await _close()


func test_double_pressing_the_hint_confirmation_charges_once() -> void:
	await _open(2)
	Progress.coins = 60
	_screen._on_hint()
	await tree.process_frame
	var modal: Modal = null
	for ch in _screen.get_children():
		if ch is Modal and not ch.is_queued_for_deletion():
			modal = ch
	check(modal != null, "confirmation dialog")
	var btn: Button = modal._buttons.get_child(0)
	btn.pressed.emit()
	btn.pressed.emit()
	eq(Progress.coins, 60 - Progress.HINT_COST, "charged exactly once")
	await _close()


func _primary_buttons(modal: Modal) -> int:
	var n := 0
	for b in modal.find_children("*", "Button", true, false):
		var sb = (b as Button).get_theme_stylebox("normal")
		if sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.is_equal_approx(UI.ACCENT):
			n += 1
	return n


func _top_modal() -> Modal:
	var m: Modal = null
	for ch in _screen.get_children():
		if ch is Modal and not ch.is_queued_for_deletion():
			m = ch
	return m


func _audit_top_dialog(name: String, expect_danger: bool = false) -> void:
	var m := _top_modal()
	check(m != null, "%s dialog opened" % name)
	if m == null:
		return
	var primaries := _primary_buttons(m)
	check(primaries <= 1, "%s dialog has %d coral primary buttons (max 1)" % [name, primaries])
	if expect_danger:
		var danger := false
		for b in m.find_children("*", "Button", true, false):
			var sb = (b as Button).get_theme_stylebox("normal")
			if sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.is_equal_approx(UI.DANGER):
				danger = true
		check(danger, "%s: the destructive action uses the danger style, not coral" % name)
	m.close()


func test_each_dialog_has_at_most_one_coral_primary_and_results_are_not_dismissible() -> void:
	Progress.settings["reduce_motion"] = true
	await _open(2)
	Progress.coins = 90
	_screen._on_pause()
	await tree.process_frame
	_audit_top_dialog("pause")
	await tree.process_frame
	_screen._show_rules()
	await tree.process_frame
	_audit_top_dialog("rules")
	await tree.process_frame
	_screen._on_hint()
	await tree.process_frame
	_audit_top_dialog("hint confirmation")
	await tree.process_frame
	Progress.coins = 3
	_screen._on_hint()
	await tree.process_frame
	_audit_top_dialog("insufficient coins")
	await tree.process_frame
	Progress.coins = 90
	var mv: Array = Levels.get_level(2)["solution"][0]
	_screen._on_tray_tapped(mv[0])
	_screen._on_tray_tapped(mv[1])
	await _wait_idle()
	_screen._on_restart()
	await tree.process_frame
	_audit_top_dialog("restart confirmation", true)
	await _close()
	Progress.settings["reduce_motion"] = false
	# result dialogs: win and fail must not be dismissible and have one primary
	await _open(1)
	await _play_level1_to_win()
	var win := _top_modal()
	check(win != null and not win.dismissible, "win dialog is not dismissible")
	check(win != null and _primary_buttons(win) <= 1, "win dialog has at most one primary")
	await _close()
	await _open(11)
	var guard := 0
	while _screen.session.status == GameSession.Status.PLAYING and guard < 80:
		guard += 1
		await _wait_idle()
		var lm: Array = _screen.session.board.legal_moves()
		if lm.is_empty():
			break
		var m2: Array = lm[guard % lm.size()]
		_screen._on_tray_tapped(m2[0])
		_screen._on_tray_tapped(m2[1])
	await _wait_idle()
	for i in 4:
		await tree.process_frame
	var fail := _top_modal()
	check(fail != null and not fail.dismissible, "fail dialog is not dismissible")
	check(fail != null and _primary_buttons(fail) <= 1, "fail dialog has at most one primary")
	await _close()
