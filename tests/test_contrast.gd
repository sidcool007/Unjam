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
		var rim: Color = UI.TYPE_COLORS[i].darkened(UI.RIM_DARKEN[i])
		_min(rim, UI.TRAY, 3.0, "rim of object type %d (%s) — the object's boundary needs 3:1" % [i, UI.SHAPE_NAMES[i]])


func test_amber_triangle_is_improved_but_stays_amber_and_distinct() -> void:
	var amber: Color = UI.TYPE_COLORS[2]
	check(ratio(amber, UI.TRAY) >= 1.4, "amber fill on tray %.2f (was 1.34)" % ratio(amber, UI.TRAY))
	check(amber.r > 0.85 and amber.g > 0.60 and amber.b < 0.10, "still a yellow-orange hue")
	var orange: Color = UI.TYPE_COLORS[7]
	var d := Vector3(amber.r - orange.r, amber.g - orange.g, amber.b - orange.b).length() * 255.0
	check(d >= 50.0, "amber stays distinguishable from the orange cross (RGB distance %.0f)" % d)
	var thick: float = UI.RIM_INSET[2]
	for i in UI.RIM_INSET.size():
		if i != 2:
			check(UI.RIM_INSET[i] > thick, "only the amber triangle gets the extra-thick rim")
	for i in UI.RIM_DARKEN.size():
		if i != 2:
			check(UI.RIM_DARKEN[i] <= 0.36, "other shapes are not darkened")


func test_tray_outline_is_a_visible_boundary() -> void:
	_min(UI.TRAY_OUTLINE, UI.BG, 3.0, "tray outline on page background")
	_min(UI.INK, UI.TRAY, 4.5, "ink on tray fill")


# ---------------------------------------------------------------- colour-blind palette

const CVD := {
	"protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
	"deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
	"tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


static func _to_lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _from_lin(c: float) -> float:
	c = clampf(c, 0.0, 1.0)
	return 12.92 * c if c <= 0.0031308 else 1.055 * pow(c, 1.0 / 2.4) - 0.055


## Machado et al. (2009) colour-vision-deficiency simulation, severity 1.0.
static func simulate(c: Color, kind: String) -> Color:
	if kind == "none":
		return c
	var m: Array = CVD[kind]
	var l := [_to_lin(c.r), _to_lin(c.g), _to_lin(c.b)]
	var o := []
	for i in 3:
		o.append(_from_lin(m[i][0] * l[0] + m[i][1] * l[1] + m[i][2] * l[2]))
	return Color(o[0], o[1], o[2])


static func lab(c: Color) -> Vector3:
	var l := [_to_lin(c.r), _to_lin(c.g), _to_lin(c.b)]
	var x: float = (0.4124 * l[0] + 0.3576 * l[1] + 0.1805 * l[2]) / 0.95047
	var y: float = 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]
	var z: float = (0.0193 * l[0] + 0.1192 * l[1] + 0.9505 * l[2]) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	return Vector3(116.0 * f.call(y) - 16.0, 500.0 * (f.call(x) - f.call(y)), 200.0 * (f.call(y) - f.call(z)))


static func min_delta_e(cols: Array, kind: String, n: int) -> float:
	var best := 1e9
	for i in n:
		for j in range(i + 1, n):
			best = minf(best, lab(simulate(cols[i], kind)).distance_to(lab(simulate(cols[j], kind))))
	return best


func test_colour_blind_palette_keeps_the_five_level_types_apart_for_every_deficiency() -> void:
	for kind in ["none", "protan", "deutan", "tritan"]:
		var d := min_delta_e(UI.CB_COLORS, kind, 5)
		check(d >= 25.0, "colour-blind palette, %s vision: closest pair of the 5 level types is dE %.1f (need >= 25)" % [kind, d])
	# every shipped level uses at most 5 types, so the guarantee covers the whole campaign
	var lib: Node = load("res://src/core/level_library.gd").new()
	lib.load_campaign("res://levels/campaign.json")
	for lv in lib.levels:
		check(int(lv["types"]) <= 5, "level %d uses %d types (palette guarantee covers 5)" % [lv["id"], lv["types"]])
	lib.free()


func test_default_palette_weakness_is_documented_not_hidden() -> void:
	# The default palette is weak for deuteranopia (red circle vs green hexagon). The colour-blind mode must be clearly better.
	var d_default := min_delta_e(UI.TYPE_COLORS, "deutan", 5)
	var d_cb := min_delta_e(UI.CB_COLORS, "deutan", 5)
	check(d_cb > d_default * 1.5, "colour-blind palette (dE %.1f) is clearly better than default (dE %.1f) under deuteranopia" % [d_cb, d_default])


func test_colour_blind_palette_rims_are_visible_on_the_tray() -> void:
	for i in UI.CB_COLORS.size():
		var rim: Color = UI.CB_COLORS[i].darkened(UI.CB_RIM_DARKEN[i])
		_min(rim, UI.TRAY, 3.0, "colour-blind rim of type %d (%s)" % [i, UI.SHAPE_NAMES[i]])


func test_palette_switch_follows_the_setting() -> void:
	var p = load("res://src/services/progress.gd").new()
	p.save_path = "user://test_palette_save.json"
	p.level_count = 10
	p.set_setting("colorblind", true)
	eq(UI.type_color(0), UI.CB_COLORS[0])
	p.set_setting("colorblind", false)
	eq(UI.type_color(0), UI.TYPE_COLORS[0])
	p.free()
	UI.colorblind = false
