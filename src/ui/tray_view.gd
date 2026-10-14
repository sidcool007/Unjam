class_name TrayView
extends Control
## One tray. Draws itself and reports taps. The control rect is the whole
## column cell (generous touch target); the visible tray is centred inside it.

signal tapped(index: int)

var index := 0
var cap := 3
var slot := 80.0
var accepts := -1
var source_only := false
var valid_target := false  # soft highlight: legal destination for the current selection
var is_source := false
var hint_target := false
var flash := 0.0  # 0..1 completion flash


func configure(i: int, capacity: int, slot_size: float, accepts_type: int, src_only: bool, cell_w: float) -> void:
	index = i
	cap = capacity
	slot = slot_size
	accepts = accepts_type
	source_only = src_only
	size = Vector2(cell_w, tray_height())
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP


func tray_height() -> float:
	return cap * slot + slot * 0.3


func tray_rect() -> Rect2:
	var w := slot + slot * 0.3
	return Rect2(Vector2((size.x - w) / 2.0, 0), Vector2(w, size.y))


## Local centre of slot `i` (0 = bottom).
func slot_center(i: int) -> Vector2:
	var tr := tray_rect()
	return Vector2(tr.get_center().x, tr.end.y - slot * 0.15 - slot * (i + 0.5))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		tapped.emit(index)


func set_flags(valid: bool, src: bool, hint: bool) -> void:
	if valid != valid_target or src != is_source or hint != hint_target:
		valid_target = valid
		is_source = src
		hint_target = hint
		queue_redraw()


func set_flash(v: float) -> void:
	flash = v
	queue_redraw()


func _draw() -> void:
	var tr := tray_rect()
	var base := UI.TRAY
	if source_only:
		base = base.darkened(0.08)
	var sb := UI.box(base, int(slot * 0.34), UI.TRAY_EDGE, 3)
	draw_style_box(sb, tr)
	if flash > 0.0:
		draw_style_box(UI.box(Color(UI.GOOD, 0.55 * flash), int(slot * 0.34)), tr)
	if valid_target:
		draw_style_box(UI.box(Color(UI.GOOD, 0.12), int(slot * 0.34), UI.GOOD, 5), tr)
	if is_source:
		draw_style_box(UI.box(Color(0, 0, 0, 0), int(slot * 0.34), UI.ACCENT, 5), tr)
	if hint_target:
		draw_style_box(UI.box(Color(UI.WARN, 0.25), int(slot * 0.34), UI.WARN, 6), tr)
	# slot guides (capacity cue that does not rely on colour)
	for i in cap:
		var c := slot_center(i)
		draw_arc(c, slot * 0.34, 0, TAU, 24, Color(UI.TRAY_EDGE, 0.9), 2.0, true)
	if accepts >= 0:
		# reserved tray: faint outline of the only type it takes + a corner tag
		var c0 := slot_center(cap - 1) + Vector2(0, -slot * 0.0)
		Shapes.draw_object(self, accepts, c0, slot * 0.30, 0.38)
		draw_arc(c0, slot * 0.42, 0, TAU, 28, Color(UI.INK, 0.5), 2.5, true)
	if source_only:
		var a := Vector2(tr.get_center().x, tr.position.y + slot * 0.12)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-slot * 0.2, slot * 0.1), a + Vector2(slot * 0.2, slot * 0.1), a + Vector2(0, -slot * 0.12)]), Color(UI.INK, 0.55))
