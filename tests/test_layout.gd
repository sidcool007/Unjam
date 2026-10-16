extends TestCase
## Safe-area / cutout maths and responsive column. These SIMULATE device
## geometry (no physical device): they prove the arithmetic, not the OS values.


func test_no_cutout_gives_zero_insets() -> void:
	var v := UI.insets_from_rects(Rect2(0, 0, 1080, 2400), Vector2(1080, 2400), Vector2(720, 1600))
	eq(v, Vector4.ZERO)


func test_cutout_and_nav_bar_scale_into_logical_pixels() -> void:
	# 1080x2400 phone: 96 px status bar/notch on top, 48 px gesture bar below, rounded sides 12 px.
	var v := UI.insets_from_rects(Rect2(12, 96, 1056, 2256), Vector2(1080, 2400), Vector2(720, 1600))
	check(absf(v.x - 8.0) < 0.01, "left %s" % v.x)
	check(absf(v.y - 64.0) < 0.01, "top %s" % v.y)
	check(absf(v.z - 8.0) < 0.01, "right %s" % v.z)
	check(absf(v.w - 32.0) < 0.01, "bottom %s" % v.w)


func test_degenerate_inputs_never_produce_negative_or_nan() -> void:
	eq(UI.insets_from_rects(Rect2(0, 0, 0, 0), Vector2(1080, 2400), Vector2(720, 1600)), Vector4.ZERO)
	eq(UI.insets_from_rects(Rect2(0, 0, 1080, 2400), Vector2(0, 0), Vector2(720, 1600)), Vector4.ZERO)
	var v := UI.insets_from_rects(Rect2(-5, -5, 2000, 3000), Vector2(1080, 2400), Vector2(720, 1600))
	check(v.x >= 0.0 and v.y >= 0.0 and v.z >= 0.0 and v.w >= 0.0)


func test_column_margins_keep_phone_layout_and_clear_system_bars() -> void:
	var base := Vector4(20, 18, 20, 18)
	# phone width: base margins only (plus top/bottom insets)
	var m := ColumnMargin.compute_margins(720, base, Vector4(0, 64, 0, 32), 780)
	eq(m, Vector4(20, 72, 20, 40))
	# wide landscape viewport: content centred in a 780 column
	var w := ColumnMargin.compute_margins(2275, base, Vector4.ZERO, 780)
	check(absf(w.x - 747.5) < 0.01 and absf(w.z - 747.5) < 0.01)
	# a side cutout larger than the column margin still wins
	var c := ColumnMargin.compute_margins(800, base, Vector4(60, 0, 60, 0), 780)
	eq(c.x, 60.0)


func test_game_board_stays_inside_the_column_on_a_wide_window() -> void:
	Progress.save_path = "user://test_layout_save.json"
	Progress.level_count = Levels.count()
	Progress.reset_all()
	Progress.tutorial_done = true
	Progress.seen_intros = {40: true}
	Progress.highest_unlocked = 40
	var stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(stub)
	var s := GameScreen.new()
	s.main = stub
	s.level_id = 40
	s.size = Vector2(2275, 1280)   # landscape tablet / foldable viewport
	tree.root.add_child(s)
	for i in 4:
		await tree.process_frame
	var bv := s.board_view
	check(bv.size.x <= 780.5, "board width %.0f must stay within the column" % bv.size.x)
	check(bv.size.x > 300.0, "board has real width")
	for t in bv.trays:
		check(t.position.x >= -1.0 and t.position.x + t.size.x <= bv.size.x + 1.0, "tray inside board")
	s.queue_free()
	stub.queue_free()
	await tree.process_frame


func _screen_rect_ok(node: Control, vp: Vector2, what: String) -> void:
	var r := node.get_global_rect()
	check(r.position.x >= -1.0 and r.position.y >= -1.0 and r.end.x <= vp.x + 1.0 and r.end.y <= vp.y + 1.0,
		"%s %s must lie inside the %s viewport" % [what, str(r), str(vp)])


func test_splash_logo_is_centred_inside_the_viewport() -> void:
	tree.root.size = Vector2i(720, 1280)
	await tree.process_frame
	var stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(stub)
	var s := SplashScreen.new()
	s.main = stub
	s.size = Vector2(720, 1280)
	tree.root.add_child(s)
	for i in 3:
		await tree.process_frame
	var logo: Logo = null
	for n in s.find_children("*", "Logo", true, false):
		logo = n
	check(logo != null)
	if logo != null:
		_screen_rect_ok(logo, Vector2(720, 1280), "splash logo")
		check(absf(logo.get_global_rect().get_center().x - 360.0) < 2.0, "logo horizontally centred")
	s.queue_free()
	stub.queue_free()
	await tree.process_frame


func test_every_dialog_fits_on_screen_with_its_buttons() -> void:
	# Opens each menu/pause dialog and checks the whole card (incl. buttons) is inside a 720x1280 viewport.
	tree.root.size = Vector2i(720, 1280)
	await tree.process_frame
	Progress.save_path = "user://test_layout_save.json"
	Progress.level_count = Levels.count()
	Progress.reset_all()
	var stub = load("res://tests/stub_main.gd").new()
	tree.root.add_child(stub)
	var menu := MenuScreen.new()
	menu.main = stub
	menu.size = Vector2(720, 1280)
	tree.root.add_child(menu)
	for i in 3:
		await tree.process_frame
	var cases := {"settings": menu._open_settings, "rules": menu._show_rules, "reset": menu._confirm_reset}
	for k in cases:
		cases[k].call()
		for i in 3:
			await tree.process_frame
		var modal: Modal = null
		for c in menu.get_children():
			if c is Modal and not c.is_queued_for_deletion():
				modal = c
		check(modal != null, "%s dialog opened" % k)
		if modal != null:
			_screen_rect_ok(modal._card, Vector2(720, 1280), "%s dialog card" % k)
			modal.close()
		await tree.process_frame
	menu.queue_free()
	stub.queue_free()
	await tree.process_frame
