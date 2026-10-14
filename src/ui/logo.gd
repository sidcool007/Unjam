class_name Logo
extends Control
## Original wordmark: five shapes "UNJAM" with the last slot left open.


func _draw() -> void:
	var cx := size.x / 2.0
	# a tray with a tangle of shapes and one dashed empty slot
	var tray := Rect2(Vector2(cx - 250, 40), Vector2(500, 190))
	draw_style_box(UI.box(UI.TRAY, 56, UI.TRAY_EDGE, 4), tray)
	var r := 54.0
	var xs := [-170.0, -57.0, 57.0]
	for i in 3:
		Shapes.draw_object(self, [0, 1, 2][i], Vector2(cx + xs[i], 135), r * 0.82)
	var c4 := Vector2(cx + 170.0, 135)
	for i in 12:  # dashed ring: "the last slot"
		draw_arc(c4, r * 0.9, i * TAU / 12.0, i * TAU / 12.0 + TAU / 20.0, 6, UI.INK, 6.0, true)
	var f: Font = UI.bold()
	_centered(f, "UNJAM", cx, 360, 128, UI.INK)
	_centered(f, "THE LAST SLOT", cx, 430, 38, UI.ACCENT_DARK)


func _centered(f: Font, text: String, cx: float, y: float, fs: int, col: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(cx - w / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
