class_name UI
extends RefCounted
## Design tokens + small factory helpers shared by every screen.
## Palette is deliberately small: warm neutral paper, deep indigo ink, one accent.

const BG := Color("f3f0ea")
const BG_DARK := Color("e7e2d8")
const PANEL := Color("ffffff")
const TRAY := Color("e1dccf")
const TRAY_EDGE := Color("cfc8b7")
const INK := Color("2b2f4a")
const INK_SOFT := Color("6b6f8a")
const ACCENT := Color("ff6b5b")
const ACCENT_DARK := Color("e24f3f")
const GOOD := Color("2fbf71")
const WARN := Color("f4b400")
const ICE := Color("bfe6fa")

## Object palette: one colour AND one distinct shape per type (non-colour cue).
const TYPE_COLORS := [
	Color("ef5b5b"), Color("2e9be6"), Color("f5b400"), Color("2fbf71"),
	Color("8e5cf5"), Color("f06bb5"), Color("10a9a0"), Color("f2792b"),
]
const SHAPE_NAMES := ["circle", "square", "triangle", "hexagon", "diamond", "star", "pentagon", "cross"]

const SCALE_FONT_TITLE := 64
const FONT_H1 := 44
const FONT_H2 := 34
const FONT_BODY := 28
const FONT_SMALL := 22
const MIN_TOUCH := 88  # logical px (>= 48dp on every common phone at 720 wide)


static func box(color: Color, radius: int = 24, border: Color = Color(0, 0, 0, 0), border_w: int = 0, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if shadow:
		sb.shadow_color = Color(0.17, 0.18, 0.29, 0.18)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
	return sb


static func label(text: String, size: int = FONT_BODY, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, size: int = FONT_BODY, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## Rounded button. kind: "primary" | "secondary" | "ghost" | "danger"
static func button(text: String, kind: String = "primary", font_size: int = FONT_H2) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, MIN_TOUCH)
	b.add_theme_font_size_override("font_size", font_size)
	var fill := ACCENT
	var down := ACCENT_DARK
	var fg := Color.WHITE
	match kind:
		"secondary":
			fill = PANEL
			down = BG_DARK
			fg = INK
		"ghost":
			fill = Color(0, 0, 0, 0)
			down = Color(0, 0, 0, 0.06)
			fg = INK
		"danger":
			fill = Color("d94a4a")
			down = Color("b83a3a")
	var n := box(fill, 30, TRAY_EDGE if kind == "secondary" else Color(0, 0, 0, 0), 2 if kind == "secondary" else 0, kind != "ghost")
	var p := box(down, 30)
	n.content_margin_left = 28
	n.content_margin_right = 28
	p.content_margin_left = 28
	p.content_margin_right = 28
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("focus", n)
	var dis := box(Color(fill, 0.35), 30)
	b.add_theme_stylebox_override("disabled", dis)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.55))
	return b


## Insets (in logical viewport px) to keep clear of system bars / cutouts.
static func safe_insets(vp: Viewport) -> Vector4:  # left, top, right, bottom
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return Vector4.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var vs := vp.get_visible_rect().size
	var sx := vs.x / win.x
	var sy := vs.y / win.y
	return Vector4(safe.position.x * sx, safe.position.y * sy,
		(win.x - safe.end.x) * sx, (win.y - safe.end.y) * sy).max(Vector4.ZERO)
