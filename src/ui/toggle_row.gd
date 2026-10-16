class_name ToggleRow
extends PanelContainer
## A labelled on/off switch (settings). Emits toggled(on).

signal toggled(on: bool)

var on := false
var _knob_x := 0.0
var _track: Control


static func make(text: String, initial: bool, icon_on: String = "", icon_off: String = "") -> ToggleRow:
	var r := ToggleRow.new()
	r.on = initial
	r.custom_minimum_size = Vector2(0, UI.MIN_TOUCH)
	r.add_theme_stylebox_override("panel", UI.box(UI.BG, 26))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_child(h)
	r.add_child(pad)
	var lbl := UI.label(text, UI.FONT_BODY, UI.INK, HORIZONTAL_ALIGNMENT_LEFT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	var track := Control.new()
	track.custom_minimum_size = Vector2(96, 52)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(track)
	r._track = track
	track.draw.connect(r._draw_track)
	r.gui_input.connect(r._input_ev)
	return r


func _input_ev(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		on = not on
		_track.queue_redraw()
		toggled.emit(on)


func _draw_track() -> void:
	var t := _track
	var col := UI.GOOD_DARK if on else UI.SWITCH_OFF
	t.draw_style_box(UI.box(col, 26), Rect2(Vector2.ZERO, t.size))
	var kx := t.size.x - 26.0 if on else 26.0
	t.draw_circle(Vector2(kx, t.size.y / 2.0), 20.0, Color.WHITE)
	var f := ThemeDB.fallback_font
	var s := "ON" if on else "OFF"
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var tx := 12.0 if on else t.size.x - w - 12.0
	t.draw_string(f, Vector2(tx, t.size.y / 2.0 + 6.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
