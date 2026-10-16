class_name CreditsScreen
extends Control

var main

const TEXT := "PRIVACY
Unjam keeps everything on your device. There is no account, no analytics, no advertising and no network access. The game asks for no Android permissions. Your progress, coins and settings are stored in a small local file that you can erase at any time from Settings > Reset all progress.

CREDITS
Game design, code, artwork and sound: original work created for this project. All shapes are drawn in code and all sounds are synthesised in code, so no third-party artwork, music or sound files are used.

OPEN SOURCE
Made with the Godot Engine (MIT licence, © Juan Linietsky, Ariel Manzur and contributors). Godot's full licence text is available at godotengine.org/license.

VERSION
%s"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := ColumnMargin.make(32, 18, 32, 18)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	margin.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)
	var back := IconButton.make("back", "", Vector2(UI.MIN_TOUCH, UI.MIN_TOUCH))
	back.pressed.connect(func():
		Audio.play("tap")
		main.open_menu())
	top.add_child(back)
	top.add_child(UI.label("Privacy & credits", UI.FONT_H1))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 24
	vb.add_child(scroll)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 30))
	scroll.add_child(card)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 28)
	card.add_child(m)
	var ver := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var l := UI.wrap_label(TEXT % ("Unjam: The Last Slot " + ver), UI.FONT_SMALL + 2, UI.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	m.add_child(l)
