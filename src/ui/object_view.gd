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
	var alpha := 0.55 if (locked or frozen_left > 0) else 1.0
	Shapes.draw_object(self, type, c, r, alpha)
	if frozen_left > 0:
		draw_circle(c, r * 1.05, Color(UI.ICE, 0.62))
		draw_arc(c, r * 1.05, 0, TAU, 28, Color("7cc3e8"), maxf(2.0, size.x * 0.04), true)
		Shapes.draw_snow(self, c + Vector2(0, -r * 0.1), r * 0.5, Color("4aa3d6"))
		var f := ThemeDB.fallback_font
		var fs := int(size.x * 0.3)
		var txt := str(frozen_left)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(f, c + Vector2(-w / 2.0, r * 0.78), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)
	if locked:
		var key := BoardState.obj_lock(code)
		var s := size.x * 0.46
		var p := c + Vector2(size.x * 0.02, size.x * 0.0)
		draw_circle(p + Vector2(s * 0.5, s * 0.55), s * 0.72, Color(1, 1, 1, 0.9))
		Shapes.draw_lock(self, p, s, key)
