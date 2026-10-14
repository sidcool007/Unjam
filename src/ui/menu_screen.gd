class_name MenuScreen
extends Control

var main


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ins := UI.safe_insets(get_viewport())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(maxf(40, ins.x)))
	margin.add_theme_constant_override("margin_right", int(maxf(40, ins.z)))
	margin.add_theme_constant_override("margin_top", int(maxf(24, ins.y + 8)))
	margin.add_theme_constant_override("margin_bottom", int(maxf(24, ins.w + 8)))
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	margin.add_child(vb)

	# top row: coins
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(top)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 30, UI.TRAY_EDGE, 2))
	chip.custom_minimum_size = Vector2(150, 72)
	var ch := HBoxContainer.new()
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_theme_constant_override("separation", 8)
	chip.add_child(ch)
	var ci := Control.new()
	ci.custom_minimum_size = Vector2(36, 36)
	ci.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ci.draw.connect(func(): Shapes.draw_icon(ci, "coin", Vector2(18, 18), 16, UI.WARN))
	ch.add_child(ci)
	ch.add_child(UI.label(str(Progress.coins), UI.FONT_H2))
	top.add_child(chip)

	var logo := Logo.new()
	logo.custom_minimum_size = Vector2(0, 470)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(logo)

	# progress indicator
	var total := Levels.count()
	var done := Progress.completed.size()
	var prog := VBoxContainer.new()
	prog.add_theme_constant_override("separation", 8)
	vb.add_child(prog)
	prog.add_child(UI.label("%d / %d levels cleared   ·   %d stars" % [done, total, Progress.total_stars()], UI.FONT_SMALL + 2, UI.INK_SOFT))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.draw.connect(func():
		bar.draw_style_box(UI.box(UI.TRAY, 9), Rect2(Vector2.ZERO, bar.size))
		var frac := float(done) / maxf(1.0, float(total))
		if frac > 0.0:
			bar.draw_style_box(UI.box(UI.ACCENT, 9), Rect2(Vector2.ZERO, Vector2(maxf(18.0, bar.size.x * frac), bar.size.y))))
	prog.add_child(bar)

	var started := Progress.completed.size() > 0 or Progress.session != null or Progress.current_level > 1
	var cont := Progress.continue_level()
	var play := UI.button(("Continue · Level %d" % cont) if started else "Play", "primary", UI.FONT_H1)
	play.custom_minimum_size = Vector2(0, 112)
	play.pressed.connect(func():
		Audio.play("tap")
		main.open_game(cont))
	vb.add_child(play)
	var levels := UI.button("Levels", "secondary")
	levels.pressed.connect(func():
		Audio.play("tap")
		main.open_levels())
	vb.add_child(levels)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	var settings := UI.button("Settings", "ghost", UI.FONT_BODY)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(_open_settings)
	row.add_child(settings)
	var about := UI.button("Privacy & credits", "ghost", UI.FONT_BODY)
	about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	about.pressed.connect(func():
		Audio.play("tap")
		main.open_credits())
	row.add_child(about)

	if Progress.load_status == "recovered_backup" or Progress.load_status == "reset_corrupt":
		var warn := UI.wrap_label("Your save file could not be read. %s" % ("A backup was restored." if Progress.load_status == "recovered_backup" else "Starting fresh."), UI.FONT_SMALL, UI.ACCENT_DARK)
		vb.add_child(warn)


func _open_settings() -> void:
	Audio.play("tap")
	var m := Modal.make("Settings")
	m.add_content(SettingsPanel.make())
	m.add_text("How to play", UI.INK_SOFT, UI.FONT_SMALL)
	m.add_text(CampaignText.RULES_TEXT, UI.INK, UI.FONT_SMALL)
	var reset := m.add_button("Reset all progress", "ghost", func(): _confirm_reset(), false)
	m.add_button("Done", "primary")
	add_child(m)


func _confirm_reset() -> void:
	var m := Modal.make("Reset progress?")
	m.add_text("This erases completed levels, coins and settings on this device. It can't be undone.", UI.INK_SOFT)
	m.add_button("Erase everything", "danger", func():
		Progress.reset_all()
		main.open_menu())
	m.add_button("Cancel", "secondary")
	add_child(m)
