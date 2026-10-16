class_name LevelSelectScreen
extends Control

var main
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := ColumnMargin.make(24, 18, 24, 18, 900.0)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)
	var back := IconButton.make("back", "", Vector2(UI.MIN_TOUCH, UI.MIN_TOUCH))
	back.pressed.connect(func():
		Audio.play("tap")
		main.open_menu())
	top.add_child(back)
	var t := UI.label("Levels", UI.FONT_H1)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	top.add_child(UI.label("★ %d" % Progress.total_stars(), UI.FONT_H2, UI.INK_SOFT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 24  # a tap that wobbles slightly must not become a scroll
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var current_stage := -1
	var grid: GridContainer = null
	for id in range(1, Levels.count() + 1):
		var lv: Dictionary = Levels.get_level(id)
		var stage := int(lv.get("stage", 1))
		if stage != current_stage:
			current_stage = stage
			var head := UI.label("Stage %d · %s" % [stage, CampaignText.STAGES.get(stage, "")], UI.FONT_BODY, UI.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT)
			list.add_child(head)
			grid = GridContainer.new()
			grid.columns = 4
			grid.add_theme_constant_override("h_separation", 14)
			grid.add_theme_constant_override("v_separation", 14)
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_child(grid)
		grid.add_child(_tile(id))
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 30)
	list.add_child(pad)

	_toast = UI.label("", UI.FONT_BODY, Color.WHITE)
	_toast.add_theme_stylebox_override("normal", UI.box(Color(UI.INK, 0.92), 28))
	_toast.anchor_left = 0.1
	_toast.anchor_right = 0.9
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_top = -120
	_toast.offset_bottom = -50
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_toast.z_index = 20
	add_child(_toast)

	# scroll the current level into view
	var cur := Progress.continue_level()
	_scroll_to.call_deferred(scroll, cur)


func _scroll_to(scroll: ScrollContainer, id: int) -> void:
	var row := (id - 1) / 4
	scroll.scroll_vertical = maxi(0, row * 160 - 200)


func _tile(id: int) -> Control:
	var unlocked := Progress.is_unlocked(id)
	var done := Progress.is_completed(id)
	var cur := id == Progress.continue_level()
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 146)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := UI.PANEL if unlocked else Color("dcd6c7")
	var border := UI.ACCENT if cur else UI.TRAY_EDGE
	b.add_theme_stylebox_override("normal", UI.box(fill, 30, border, 5 if cur else 2, unlocked))
	b.add_theme_stylebox_override("hover", UI.box(fill, 30, border, 5 if cur else 2, unlocked))
	b.add_theme_stylebox_override("pressed", UI.box(UI.BG_DARK, 30, border, 3))
	b.add_theme_stylebox_override("focus", UI.box(fill, 30, border, 2))
	b.draw.connect(func():
		var f := ThemeDB.fallback_font
		var txt := str(id)
		var fs := 44
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := UI.INK if unlocked else Color("7d7863")
		b.draw_string(f, Vector2((b.size.x - w) / 2.0, 70), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if unlocked:
			var st := Progress.stars_of(id)
			for k in 3:
				Shapes.draw_icon(b, "star" if k < st else "star_off", Vector2(b.size.x / 2.0 + (k - 1) * 36.0, 112), 14.0, UI.WARN)
		else:
			Shapes.draw_lock(b, Vector2(b.size.x / 2.0 - 17, 82), 34.0, -1)
	)
	b.pressed.connect(func():
		if unlocked:
			Audio.play("tap")
			main.open_game(id)
		else:
			Audio.play("invalid")
			_show_toast("Clear level %d to unlock this one." % (Progress.highest_unlocked)))
	return b


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)
