extends TestCase
## Locks the accessibility contrast of the real design tokens (WCAG 2.x ratios).
## Thresholds: 4.5 normal text, 3.0 large text and graphical UI parts.


static func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)


static func lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


static func ratio(a: Color, b: Color) -> float:
	var la := lum(a)
	var lb := lum(b)
	if la < lb:
		var t := la
		la = lb
		lb = t
	return (la + 0.05) / (lb + 0.05)


func _min(a: Color, b: Color, need: float, what: String) -> void:
	var r := ratio(a, b)
	check(r >= need, "%s: contrast %.2f:1 is below %.1f:1" % [what, r, need])


func test_body_and_secondary_text_pass_aa() -> void:
	_min(UI.INK, UI.BG, 7.0, "ink on background")
	_min(UI.INK, UI.PANEL, 7.0, "ink on white")
	_min(UI.INK, UI.TRAY, 4.5, "ink on tray")
	_min(UI.INK_SOFT, UI.BG, 4.5, "soft text on background")
	_min(UI.INK_SOFT, UI.PANEL, 4.5, "soft text on white")
	_min(UI.ACCENT_DARK, UI.BG, 4.5, "tagline on background")


func test_buttons_and_toggles_pass_aa_for_their_text() -> void:
	_min(Color.WHITE, UI.ACCENT, 4.5, "white on primary button")
	_min(Color.WHITE, UI.ACCENT_DARK, 4.5, "white on pressed primary")
	_min(Color.WHITE, UI.DANGER, 4.5, "white on danger button")
	_min(Color.WHITE, UI.DANGER_DARK, 4.5, "white on pressed danger")
	_min(Color.WHITE, UI.GOOD_DARK, 4.5, "ON label on switch")
	_min(Color.WHITE, UI.SWITCH_OFF, 4.5, "OFF label on switch")
	_min(Color.WHITE, UI.INK, 7.0, "toast text")
	_min(UI.INK, UI.WARN, 4.5, "hint cost badge")


func test_graphical_parts_meet_3_to_1_where_they_carry_meaning() -> void:
	_min(UI.ACCENT, UI.BG, 3.0, "selection ring / current tile / progress fill on background")
	_min(UI.ACCENT, UI.PANEL, 3.0, "current-tile border on white tile")
	_min(UI.TRAY_EDGE, UI.BG, 2.5, "tray outline on background")


func test_every_object_rim_is_visible_on_the_tray() -> void:
	for i in UI.TYPE_COLORS.size():
		var rim: Color = UI.TYPE_COLORS[i].darkened(0.36)
		_min(rim, UI.TRAY, 2.0, "rim of object type %d (%s)" % [i, UI.SHAPE_NAMES[i]])
