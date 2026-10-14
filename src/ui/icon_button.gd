class_name IconButton
extends Button
## Square-ish touch button with a vector icon, caption and optional badge.

var icon_name := "undo"
var caption := ""
var badge := ""
var icon_color := UI.INK
var icon_scale := 1.0


static func make(icon: String, text: String, min_size: Vector2 = Vector2(150, 112), kind: String = "secondary") -> IconButton:
	var b := IconButton.new()
	b.icon_name = icon
	b.caption = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	var n := UI.box(UI.PANEL if kind == "secondary" else Color(0, 0, 0, 0), 30, UI.TRAY_EDGE if kind == "secondary" else Color(0, 0, 0, 0), 2 if kind == "secondary" else 0, kind == "secondary")
	var p := UI.box(UI.BG_DARK, 30)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("focus", n)
	b.add_theme_stylebox_override("disabled", UI.box(Color(UI.PANEL, 0.5), 30, Color(UI.TRAY_EDGE, 0.5), 2))
	return b


func _draw() -> void:
	var col := icon_color if not disabled else Color(icon_color, 0.35)
	var has_caption := caption != ""
	var c := Vector2(size.x / 2.0, size.y * (0.38 if has_caption else 0.5))
	Shapes.draw_icon(self, icon_name, c, minf(size.x, size.y) * 0.2 * icon_scale, col)
	var f := ThemeDB.fallback_font
	if has_caption:
		var fs := UI.FONT_SMALL
		var w := f.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(f, Vector2((size.x - w) / 2.0, size.y * 0.86), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if badge != "":
		var fs2 := 20
		var bw := f.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x + 18.0
		var r := Rect2(Vector2(size.x - bw - 6.0, 6.0), Vector2(bw, 30.0))
		draw_style_box(UI.box(UI.WARN, 15), r)
		draw_string(f, r.position + Vector2(9.0, 22.0), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, UI.INK)


func refresh(new_badge: String = badge) -> void:
	badge = new_badge
	queue_redraw()
