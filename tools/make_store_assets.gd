extends SceneTree
## DEV TOOL (needs a GL context, e.g. xvfb-run):  renders Play Store graphics into store/.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1080x1920 \
##       --script res://tools/make_store_assets.gd -- <icon|feature|shots>
## Screenshots are rendered by the real game screens on a desktop GL context
## (NOT captured from a physical device).

func _initialize() -> void:
	await process_frame
	var mode: String = OS.get_cmdline_user_args()[0]
	match mode:
		"icon":
			_icon()
		"feature":
			await _feature()
		"shots":
			await _shots()
	quit()


func _icon() -> void:
	var bg := Image.load_from_file("res://assets/icon_bg_432.png")
	var fg := Image.load_from_file("res://assets/icon_fg_432.png")
	bg.convert(Image.FORMAT_RGBA8)
	fg.convert(Image.FORMAT_RGBA8)
	bg.blend_rect(fg, Rect2i(0, 0, 432, 432), Vector2i.ZERO)
	bg.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	bg.save_png("res://store/icon_512.png")
	print("wrote store/icon_512.png ", bg.get_size())


func _feature() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED  # draw in real pixels
	root.size = Vector2i(1024, 500)
	var holder := Control.new()
	holder.size = Vector2(1024, 500)
	root.add_child(holder)
	var bgc := ColorRect.new()
	bgc.color = UI.BG
	bgc.size = Vector2(1024, 500)
	holder.add_child(bgc)
	var logo := Logo.new()
	logo.size = Vector2(620, 480)
	logo.scale = Vector2(0.98, 0.98)
	logo.position = Vector2((1024.0 - 620.0 * 0.98) / 2.0, 8)
	holder.add_child(logo)
	var tag := UI.label("A sorting puzzle about the last free slot", 28, UI.INK_SOFT)
	tag.size = Vector2(1024, 40)
	tag.position = Vector2(0, 440)
	holder.add_child(tag)
	await create_timer(0.5).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://store/feature_graphic_1024x500.png")
	print("wrote feature graphic ", img.get_size())


func _shots() -> void:
	var P = root.get_node("Progress")
	var L = root.get_node("Levels")
	P.save_path = "user://store_save.json"
	P.level_count = L.count()
	P.reset_all()
	P.highest_unlocked = 16
	for i in range(1, 15):
		P.completed[i] = 3 if i % 3 else 2
	P.current_level = 15
	P.coins = 120
	P.tutorial_done = true
	P.seen_intros = {1: true, 15: true, 23: true, 29: true}
	P.save()
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.4).timeout
	m.open_menu()
	await create_timer(1.0).timeout
	_save("01_menu")
	m.open_levels()
	await create_timer(1.0).timeout
	_save("02_levels")
	P.tutorial_done = false
	P.highest_unlocked = 40
	m.open_game(1)
	await create_timer(1.0).timeout
	var g = m.get_child(0)
	var mv = L.get_level(1)["solution"][0]
	g._on_tray_tapped(mv[0])
	await create_timer(0.5).timeout
	_save("03_tutorial_level1")
	P.tutorial_done = true
	P.highest_unlocked = 40
	for spec in [[15, "04_padlocks", true], [23, "05_reserved_trays", false], [29, "06_ice", true]]:
		m.open_game(spec[0])
		await create_timer(1.0).timeout
		g = m.get_child(0)
		if spec[2]:
			var mv2 = L.get_level(spec[0])["solution"][0]
			g._on_tray_tapped(mv2[0])
			await create_timer(0.5).timeout
		_save(spec[1])


func _save(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://store/screenshots/%s.png" % name)
	print("wrote ", name, " ", img.get_size())
