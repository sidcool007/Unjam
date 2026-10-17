extends SceneTree
## DEV TOOL: renders every shape in every state on tray and page backgrounds (visual regression aid).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1080x1100 --script res://tools/make_object_states_sheet.gd -- <out.png>

func _initialize() -> void:
	await process_frame
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1080, 1100)
	var holder := Control.new()
	holder.size = Vector2(1080, 1100)
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.size = holder.size
	holder.add_child(bg)
	var slot := 110.0
	# row A: all 8 shapes on a tray strip; row B: amber in each state; row C: amber stacked + level-40 style column
	_strip(holder, Vector2(20, 20), UI.TYPE_COLORS.size(), slot, func(_k, parent):
		for i in UI.TYPE_COLORS.size():
			_obj(parent, BoardState.make_obj(i), Vector2(10 + i * 125, 10), slot, false, false, 0))
	var amber := 2
	var states := [["normal", BoardState.make_obj(amber), false, false, 0], ["selected", BoardState.make_obj(amber), true, false, 0],
		["locked (key: blue)", BoardState.make_obj(amber, 1), false, true, 0], ["frozen 4", BoardState.make_obj(amber, -1, 4), false, false, 4],
		["on page bg", BoardState.make_obj(amber), false, false, 0]]
	var x := 20.0
	for i in states.size():
		var st: Array = states[i]
		if st[0] == "on page bg":
			_obj(holder, st[1], Vector2(x + 10, 250), slot, st[2], st[3], st[4])
		else:
			_strip(holder, Vector2(x, 230), 1, slot, func(_k, parent):
				_obj(parent, st[1], Vector2(10, 10), slot, st[2], st[3], st[4]))
		var l := UI.label(st[0], 22, UI.INK)
		l.position = Vector2(x, 400)
		l.size = Vector2(190, 30)
		holder.add_child(l)
		x += 205.0
	# stacked column: amber between other shapes, one frozen, one locked (dense-level look)
	_strip(holder, Vector2(20, 460), 5, slot, func(_k, parent):
		var codes := [BoardState.make_obj(0), BoardState.make_obj(2, -1, 3), BoardState.make_obj(2), BoardState.make_obj(1, 2), BoardState.make_obj(2)]
		for i in 5:
			var c: int = codes[i]
			_obj(parent, c, Vector2(10, parent.size.y - 10 - slot * (i + 1)), slot, i == 4, i == 3, 3 if i == 1 else 0), true)
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()


func _strip(parent: Control, pos: Vector2, count: int, slot: float, fill: Callable, vertical := false) -> void:
	var p := Panel.new()
	var w := (count * 125.0 + 20.0) if not vertical else slot + 20.0
	var h := slot + 20.0 if not vertical else count * slot + 20.0
	p.position = pos
	p.size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", UI.box(UI.TRAY, int(slot * 0.34), UI.TRAY_OUTLINE, 4))
	parent.add_child(p)
	fill.call(0, p)


func _obj(parent: Control, code: int, pos: Vector2, slot: float, selected: bool, locked: bool, frozen: int) -> void:
	var ov := ObjectView.new()
	ov.setup(code, slot)
	ov.position = pos
	parent.add_child(ov)
	ov.set_state(locked, frozen, selected)
