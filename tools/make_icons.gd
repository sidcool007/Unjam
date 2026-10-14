extends SceneTree
## DEV TOOL: rasterises assets/icon*.svg into the PNGs used by the Android export.
##   godot --headless --path . --script res://tools/make_icons.gd

func _initialize() -> void:
	_render("res://assets/icon.svg", "res://assets/icon_192.png", 192, 512)
	_render("res://assets/icon_fg.svg", "res://assets/icon_fg_432.png", 432, 432)
	_render("res://assets/icon_bg.svg", "res://assets/icon_bg_432.png", 432, 432)
	quit()


func _render(svg: String, png: String, out_px: int, svg_px: int) -> void:
	var f := FileAccess.open(svg, FileAccess.READ)
	var img := Image.new()
	var err := img.load_svg_from_string(f.get_as_text(), float(out_px) / float(svg_px))
	if err != OK:
		printerr("failed to render " + svg)
		return
	img.save_png(png)
	print("wrote %s (%dx%d)" % [png, img.get_width(), img.get_height()])
