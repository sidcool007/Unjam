class_name SettingsPanel
extends VBoxContainer
## Sound / music / reduced-motion toggles bound to Progress.settings.


static func make() -> SettingsPanel:
	var p := SettingsPanel.new()
	p.add_theme_constant_override("separation", 12)
	for row in [["Sound effects", "sound"], ["Music", "music"], ["Reduce motion", "reduce_motion"], ["Colour-blind colours", "colorblind"]]:
		var key: String = row[1]
		var t := ToggleRow.make(row[0], bool(Progress.settings[key]))
		t.toggled.connect(func(on): Progress.set_setting(key, on))
		p.add_child(t)
	p.add_child(_language_row())
	return p


static func _language_row() -> Control:
	var r := PanelContainer.new()
	r.custom_minimum_size = Vector2(0, UI.MIN_TOUCH)
	r.add_theme_stylebox_override("panel", UI.box(UI.BG, 26))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_child(h)
	r.add_child(pad)
	var lbl := UI.label("Language", UI.FONT_BODY, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	var b := UI.button(I18n.option_label(Progress.language), "secondary", UI.FONT_BODY)
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.pressed.connect(func():
		var i := (I18n.LANGUAGES.find(Progress.language) + 1) % I18n.LANGUAGES.size()
		Progress.set_language(I18n.LANGUAGES[i])
		b.text = I18n.option_label(Progress.language))
	h.add_child(b)
	return r
