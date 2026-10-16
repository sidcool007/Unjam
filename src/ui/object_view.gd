class_name ObjectView
extends Control
## Visual for one game object. Pure presentation: state is pushed in from the
## board model by BoardView.refresh(); this node never decides anything.

var code: int = 0  # packed BoardState object
var selected := false
var locked := false
var frozen_left := 0
var ghost := false  # drawn faint (hint / transition)


func setup(object_code: int, slot: float) -> void:
	code = object_code
	custom_minimum_size = Vector2(slot, slot)
	size = Vector2(slot, slot)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(is_locked: bool, frozen: int, is_selected: bool) -> void:
	if is_locked != locked or frozen != frozen_left or is_selected != selected:
		locked = is_locked
		frozen_left = frozen
		selected = is_selected
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := size.x * 0.40
	var type := BoardState.obj_type(code)
	if selected:
		draw_circle(c, r * 1.32, Color(1, 1, 1, 0.95))
		draw_arc(c, r * 1.32, 0, TAU, 32, UI.ACCENT, maxf(3.0, size.x * 0.05), true)
	# the object keeps its own shape clearly visible; status is shown by a pill below it
	var alpha := 0.72 if locked else (0.9 if frozen_left > 0 else 1.0)
	Shapes.draw_object(self, type, c, r, alpha)
	if frozen_left > 0 and not locked:
		draw_arc(c, r * 1.12, 0, TAU, 32, Color("7cc3e8"), maxf(2.5, size.x * 0.05), true)
		_draw_pill(true)
	elif locked:
		_draw_pill(false)


## Status pill straddling the object's lower edge.
## locked: [padlock] + the SHAPE that opens it · frozen: [snowflake] + moves left.
func _draw_pill(ice: bool) -> void:
	var w := size.x * (0.84 if not ice else 0.72)
	var h := size.x * 0.38
	var rect := Rect2(Vector2((size.x - w) / 2.0, size.y * 0.5 + size.x * 0.17), Vector2(w, h))
	var fill := UI.ICE if ice else Color.WHITE
	draw_style_box(UI.box(Color(0.17, 0.18, 0.29, 0.20), int(h / 2.0)), Rect2(rect.position + Vector2(0, 2), rect.size))
	draw_style_box(UI.box(fill, int(h / 2.0), UI.INK, maxi(2, int(size.x * 0.03))), rect)
	var cy := rect.get_center().y
	if ice:
		Shapes.draw_snow(self, Vector2(rect.position.x + h * 0.55, cy), h * 0.30, UI.INK)
		var f := ThemeDB.fallback_font
		var fs := int(h * 0.82)
		var txt := str(frozen_left)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(rect.end.x - h * 0.45 - tw, cy + fs * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)
	else:
		Shapes.draw_lock(self, Vector2(rect.position.x + h * 0.28, rect.position.y + h * 0.10), h * 0.80, -1)
		Shapes.draw_object(self, BoardState.obj_lock(code), Vector2(rect.end.x - h * 0.62, cy), h * 0.36)
