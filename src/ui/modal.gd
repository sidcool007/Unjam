class_name Modal
extends Control
## Centered card dialog over a dimmer. Build with Modal.make(), add content via
## add_content()/add_button(), then host.add_child(modal). Blocks input behind it.

signal closed

var title_text := ""
var dismissible := true
var _card: PanelContainer
var _box: VBoxContainer
var _buttons: VBoxContainer
var _done := false


static func make(title: String, can_dismiss: bool = true) -> Modal:
	var m := Modal.new()
	m.title_text = title
	m.dismissible = can_dismiss
	m._build()
	return m


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.11, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if dismissible and ev is InputEventMouseButton and ev.pressed:
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(600, 0)
	_card.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 40, Color(0, 0, 0, 0), 0, true))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_card)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	_card.add_child(margin)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 18)
	margin.add_child(_box)
	if title_text != "":
		_box.add_child(UI.label(title_text, UI.FONT_H1))
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	_box.add_child(_buttons)
	_card.pivot_offset = Vector2(300, 200)
	_card.scale = Vector2(0.92, 0.92)
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.12)


func add_content(c: Control) -> void:
	_box.add_child(c)
	_box.move_child(c, _box.get_child_count() - 2)  # keep buttons last


func add_text(text: String, color: Color = UI.INK, size: int = UI.FONT_BODY) -> void:
	add_content(UI.wrap_label(text, size, color))


## kind: primary | secondary | ghost | danger. Callback runs AFTER the modal closes.
func add_button(text: String, kind: String = "primary", callback: Callable = Callable(), close_after: bool = true) -> Button:
	var b := UI.button(text, kind)
	b.pressed.connect(func():
		Audio.play("tap")
		if close_after:
			close()
		if callback.is_valid():
			callback.call())
	_buttons.add_child(b)
	return b


func close() -> void:
	if _done:
		return
	_done = true
	closed.emit()
	queue_free()
