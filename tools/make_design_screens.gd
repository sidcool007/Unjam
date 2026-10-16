extends SceneTree
## DEV TOOL: renders every screen/state of the real game into docs/design/screens/
## (desktop GL, 1080x1920 = 720x1280 logical x1.5). Used for the UI/UX spec.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1080x1920 \
##       --script res://tools/make_design_screens.gd

var P
var L
var m
const OUT := "res://docs/design/screens/"


func _initialize() -> void:
	await process_frame
	P = root.get_node("Progress")
	L = root.get_node("Levels")
	P.save_path = "user://design_save.json"
	P.level_count = L.count()
	_state_new_player()
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await _w(0.35)
	_shot("01_splash")
	await _w(1.6)
	_shot("02_menu_new_player")

	# ---- menu with progress
	_state_progress()
	m.open_menu()
	await _w(1.0)
	_shot("03_menu_with_progress")
	var scr = m.get_child(0)
	scr._open_settings()
	await _w(0.6)
	_shot("04_settings_dialog")
	for c in scr.get_children():
		if c.has_method("add_content"):
			c.close()
	scr._confirm_reset()
	await _w(0.6)
	_shot("05_reset_progress_confirm")
	for c in scr.get_children():
		if c.has_method("add_content"):
			c.close()

	# ---- level select
	m.open_levels()
	await _w(1.0)
	_shot("06_level_select_top")
	var ls = m.get_child(0)
	ls._show_toast("Clear level 15 to unlock this one.")
	await _w(0.3)
	_shot("07_level_select_locked_toast")
	m.open_credits()
	await _w(1.0)
	_shot("08_privacy_and_credits")

	# ---- tutorial level 1
	_state_progress()
	P.tutorial_done = false
	P.seen_intros = {}
	P.save()
	m.open_game(1)
	await _w(1.1)
	_shot("09_intro_card_how_to_play")
	await _close_modals()
	await _w(0.3)
	_shot("10_game_level1_initial_with_coach")
	var g = m.get_child(0)
	var sol = L.get_level(1)["solution"]
	g._on_tray_tapped(sol[0][0])
	await _w(0.5)
	_shot("11_game_selected_object_and_targets")
	# invalid drop: first non-legal tray
	var b = g.session.board
	for t in b.tray_count():
		if t != sol[0][0] and b.check_move(sol[0][0], t) != 0:
			g._on_tray_tapped(t)
			break
	await _w(0.12)
	_shot("12_invalid_move_toast_and_shake")
	await _w(0.5)
	g._on_tray_tapped(sol[0][1])
	await _w(0.13)
	_shot("13_move_in_flight")
	await _w(0.8)
	_shot("14_after_move_undo_enabled")
	g._on_restart()
	await _w(0.5)
	_shot("15_restart_confirmation")
	await _close_modals()
	P.tutorial_done = true
	P.save()

	# ---- hint flows (level 2)
	P.coins = 85
	m.open_game(2)
	await _w(1.0)
	await _close_modals()
	g = m.get_child(0)
	g._on_hint()
	await _w(0.5)
	_shot("16_hint_confirm_dialog")
	await _close_modals()
	g._apply_hint(load("res://src/core/hint_service.gd").get_hint(g.session))
	await _w(0.5)
	_shot("17_hint_highlight_source_and_target")
	P.coins = 5
	g._on_hint()
	await _w(0.5)
	_shot("18_hint_not_enough_coins")
	await _close_modals()
	P.coins = 85

	# ---- mechanics levels
	for spec in [[11, "19_level11_move_limit_intro", true, "keep"], [15, "20_level15_padlocks", false, "sel"], [21, "21_level21_reserved_trays", false, "plain"],
			[24, "22_level24_one_way_tray", false, "plain"], [29, "23_level29_ice_frozen_objects", false, "sel"], [40, "24_level40_dense_mastery", false, "plain"]]:
		_state_progress()
		P.highest_unlocked = 40
		P.seen_intros = {}
		P.save()
		m.open_game(spec[0])
		await _w(1.1)
		if spec[2]:
			_shot(spec[1])
			await _close_modals()
		else:
			await _close_modals()
			await _w(0.2)
			g = m.get_child(0)
			if spec[3] == "sel":
				var mv = L.get_level(spec[0])["solution"][0]
				g._on_tray_tapped(mv[0])
				await _w(0.5)
			_shot(spec[1])

	# ---- pause, rules
	m.open_game(15)
	await _w(1.0)
	await _close_modals()
	g = m.get_child(0)
	g._on_pause()
	await _w(0.5)
	_shot("25_pause_menu")
	await _close_modals()
	g._show_rules()
	await _w(0.5)
	_shot("26_how_to_play_rules_dialog")
	await _close_modals()

	# ---- win (level 2, first completion) and fail (level 11)
	_state_progress()
	P.highest_unlocked = 40
	P.completed.erase(2)
	P.seen_intros = {}
	P.save()
	m.open_game(2)
	await _w(1.0)
	await _close_modals()
	g = m.get_child(0)
	for mv in L.get_level(2)["solution"]:
		while g.board_view.busy:
			await process_frame
		g._on_tray_tapped(mv[0])
		g._on_tray_tapped(mv[1])
	await _w(0.5)
	_shot("27_clear_flash_before_win_dialog")
	await _w(1.6)
	_shot("28_level_complete_dialog")
	m.open_game(11)
	await _w(1.0)
	await _close_modals()
	g = m.get_child(0)
	var guard := 0
	while g.session.status == 0 and guard < 60:
		guard += 1
		while g.board_view.busy:
			await process_frame
		var lm = g.session.board.legal_moves()
		if lm.is_empty():
			break
		var mv2 = lm[guard % lm.size()]
		g._on_tray_tapped(mv2[0])
		g._on_tray_tapped(mv2[1])
	await _w(1.8)
	_shot("29_level_failed_dialog")
	quit()


func _state_new_player() -> void:
	P.reset_all()
	P.tutorial_done = false
	P.save()


func _state_progress() -> void:
	P.reset_all()
	P.highest_unlocked = 16
	for i in range(1, 15):
		P.completed[i] = 3 if i % 3 else 2
	P.current_level = 15
	P.coins = 120
	P.tutorial_done = true
	P.seen_intros = {1: true, 5: true, 11: true, 15: true, 21: true, 24: true, 27: true, 33: true}
	P.save()


func _w(sec: float) -> void:
	await create_timer(sec).timeout


func _close_modals() -> void:
	for c in m.get_child(0).get_children():
		if c.has_method("add_content") and c.has_method("close"):
			c.close()
	await _w(0.2)


func _shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
	print("wrote ", name)
