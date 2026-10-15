extends TestCase
## Random taps against the real GameScreen, including taps while animating.
## After every idle point the view must mirror the model exactly.

var _screen: GameScreen
var _stub: Node


func before_each() -> void:
	Progress.save_path = "user://test_uifuzz_save.json"
	Progress.level_count = Levels.count()
	Progress.reset_all()
	Progress.highest_unlocked = Levels.count()
	Progress.tutorial_done = true
	Progress.seen_intros = {}
	Progress.settings["reduce_motion"] = false


func _modals() -> Array:
	var out := []
	for ch in _screen.get_children():
		if ch is Modal and not ch.is_queued_for_deletion():
			out.append(ch)
	return out


func _wait_idle() -> void:
	var n := 0
	while not _screen.board_view.settled() and n < 400:
		await tree.process_frame
		n += 1


func _verify(tag: String) -> bool:
	var bv := _screen.board_view
	var b := _screen.session.board
	if not bv.settled():
		return true
	for i in b.tray_count():
		var st: PackedInt32Array = b.stacks[i]
		var list: Array = bv.objs[i]
		if list.size() != st.size():
			failures.append("%s: tray %d view has %d objects, model %d" % [tag, i, list.size(), st.size()])
			return false
		for j in st.size():
			var ov: ObjectView = list[j]
			if ov.code != st[j]:
				failures.append("%s: tray %d slot %d shows a different object than the model" % [tag, i, j])
				return false
			var want := bv._slot_pos(i, j)
			var lifted := bv.selected_tray == i and j == st.size() - 1
			if not lifted and ov.position.distance_to(want) > 1.5:
				failures.append("%s: tray %d slot %d object is mispositioned by %.1f" % [tag, i, j, ov.position.distance_to(want)])
				return false
			if ov.scale != Vector2.ONE and not (bv._hint_tween != null):
				failures.append("%s: object left scaled %s" % [tag, str(ov.scale)])
				return false
			if ov.modulate.a < 0.99:
				failures.append("%s: object left transparent" % tag)
				return false
	if bv.selected_tray >= 0:
		if b.check_pick(bv.selected_tray) != BoardState.Reason.OK:
			failures.append("%s: selected tray is not pickable" % tag)
			return false
	var open := _modals().size()
	if open != _screen._modal_open:
		failures.append("%s: _modal_open=%d but %d dialogs exist" % [tag, _screen._modal_open, open])
		return false
	# nothing may be highlighted as a destination without a selection
	for i in bv.trays.size():
		var t: TrayView = bv.trays[i]
		if bv.selected_tray < 0 and t.valid_target:
			failures.append("%s: stale destination highlight on tray %d" % [tag, i])
			return false
		if bv.selected_tray >= 0 and t.valid_target != (i != bv.selected_tray and b.check_move(bv.selected_tray, i) == BoardState.Reason.OK):
			failures.append("%s: destination highlight on tray %d disagrees with the rules" % [tag, i])
			return false
	return true


func _random_play(level: int, steps: int, seed_v: int) -> void:
	_stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(_stub)
	_screen = GameScreen.new()
	_screen.main = _stub
	_screen.level_id = level
	_screen.size = Vector2(720, 1280)
	tree.root.add_child(_screen)
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := _screen.session.board.tray_count()
	for step in steps:
		var tag := "L%d seed %d step %d" % [level, seed_v, step]
		# dismiss dialogs sometimes (answering them is covered elsewhere)
		for m in _modals():
			if m.dismissible and rng.randf() < 0.6:
				m.close()
			elif not m.dismissible:
				m.close()
				_screen._modal_open = maxi(0, _screen._modal_open)  # closed signal decrements
		await tree.process_frame
		var r := rng.randf()
		if r < 0.72:
			_screen._on_tray_tapped(rng.randi_range(-1, n))
			if rng.randf() < 0.5:
				_screen._on_tray_tapped(rng.randi_range(0, n - 1))   # often forms a move
		elif r < 0.82:
			_screen._on_undo()
		elif r < 0.86:
			_screen._on_restart()
		elif r < 0.90:
			_screen._on_hint()
		elif r < 0.93:
			_screen._on_pause()
		else:
			# hammer: many taps in one frame while a move animates
			for k in 6:
				_screen._on_tray_tapped(rng.randi_range(0, n - 1))
		if rng.randf() < 0.6:
			await _wait_idle()
		else:
			await tree.process_frame
		if not _verify(tag):
			break
		if _screen.session.status == GameSession.Status.WON:
			break
	await _wait_idle()
	await tree.process_frame
	_verify("L%d end" % level)
	_screen.queue_free()
	_stub.queue_free()
	await tree.process_frame


func test_random_taps_level_1() -> void:
	for s in 4:
		await _random_play(1, 90, 10 + s)


func test_random_taps_limited_and_deep_level() -> void:
	await _random_play(11, 120, 21)
	await _random_play(12, 120, 22)


func test_random_taps_lock_and_ice_levels() -> void:
	await _random_play(15, 120, 31)
	await _random_play(29, 120, 32)


func test_random_taps_reserved_and_mastery_levels() -> void:
	await _random_play(23, 100, 41)
	await _random_play(24, 100, 42)
	await _random_play(40, 100, 43)
