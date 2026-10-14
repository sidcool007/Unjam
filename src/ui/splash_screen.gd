class_name SplashScreen
extends Control

var main


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var logo := Logo.new()
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.custom_minimum_size = Vector2(620, 520)
	logo.size = Vector2(620, 520)
	logo.position = Vector2(50, 300)
	add_child(logo)
	var msg := UI.label("Loading…", UI.FONT_BODY, UI.INK_SOFT)
	msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	msg.position = Vector2(260, 1000)
	msg.size = Vector2(200, 40)
	add_child(msg)
	if Levels.count() == 0:
		msg.text = "Could not load levels:\n" + Levels.load_error
		msg.add_theme_color_override("font_color", UI.ACCENT_DARK)
		return
	logo.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(logo, "modulate:a", 1.0, 0.35)
	tw.tween_interval(0.5)
	tw.tween_callback(func(): main.open_menu())
