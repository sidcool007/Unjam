class_name SplashScreen
extends Control

var main


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var logo := Logo.new()
	logo.custom_minimum_size = Vector2(620, 480)
	center.add_child(logo)
	var msg := UI.label("Loading…", UI.FONT_BODY, UI.INK_SOFT)
	msg.anchor_left = 0.1
	msg.anchor_right = 0.9
	msg.anchor_top = 1.0
	msg.anchor_bottom = 1.0
	msg.offset_top = -200
	msg.offset_bottom = -140
	add_child(msg)
	if Levels.count() == 0:
		msg.text = "Could not load levels:\n" + Levels.load_error
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.add_theme_color_override("font_color", UI.ACCENT_DARK)
		return
	logo.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 0.35)
	tw.tween_interval(0.5)
	tw.tween_callback(func(): main.open_menu())
