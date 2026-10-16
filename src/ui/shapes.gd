class_name Shapes
extends RefCounted
## Procedural drawing of the 8 object shapes and small icons (no image assets).


static func polygon_points(shape: String, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"triangle":
			for i in 3:
				var a := -PI / 2.0 + i * TAU / 3.0
				pts.append(c + Vector2(cos(a), sin(a)) * r * 1.12 + Vector2(0, r * 0.12))
		"hexagon":
			for i in 6:
				var a := i * TAU / 6.0
				pts.append(c + Vector2(cos(a), sin(a)) * r * 1.04)
		"diamond":
			pts = PackedVector2Array([c + Vector2(0, -r * 1.15), c + Vector2(r * 0.95, 0), c + Vector2(0, r * 1.15), c + Vector2(-r * 0.95, 0)])
		"star":
			for i in 10:
				var a := -PI / 2.0 + i * TAU / 10.0
				var rr := r * 1.15 if i % 2 == 0 else r * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
		"pentagon":
			for i in 5:
				var a := -PI / 2.0 + i * TAU / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * r * 1.08)
		"cross":
			var w := r * 0.42
			var l := r * 1.0
			pts = PackedVector2Array([
				c + Vector2(-w, -l), c + Vector2(w, -l), c + Vector2(w, -w), c + Vector2(l, -w),
				c + Vector2(l, w), c + Vector2(w, w), c + Vector2(w, l), c + Vector2(-w, l),
				c + Vector2(-w, w), c + Vector2(-l, w), c + Vector2(-l, -w), c + Vector2(-w, -w)])
	return pts


## Draws one game object (body, rim, sheen) centred at c with radius r.
static func draw_object(ci: CanvasItem, type: int, c: Vector2, r: float, alpha: float = 1.0) -> void:
	var col: Color = UI.TYPE_COLORS[type % UI.TYPE_COLORS.size()]
	col.a = alpha
	var dark := col.darkened(0.36)  # stronger rim keeps light shapes (amber) readable on the tray
	dark.a = alpha
	var light := col.lightened(0.38)
	light.a = alpha * 0.85
	var shape: String = UI.SHAPE_NAMES[type % UI.SHAPE_NAMES.size()]
	# soft shadow (flat ellipse under the object)
	ci.draw_set_transform(c + Vector2(0, r * 0.86), 0.0, Vector2(1.0, 0.32))
	ci.draw_circle(Vector2.ZERO, r * 0.85, Color(0.17, 0.18, 0.29, 0.16 * alpha))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match shape:
		"circle":
			ci.draw_circle(c, r, dark)
			ci.draw_circle(c + Vector2(0, -r * 0.06), r * 0.9, col)
		"square":
			var s := r * 0.92
			_rounded_rect(ci, Rect2(c - Vector2(s, s), Vector2(s, s) * 2.0), r * 0.3, dark)
			var s2 := s * 0.9
			_rounded_rect(ci, Rect2(c - Vector2(s2, s2 + r * 0.05), Vector2(s2, s2) * 2.0), r * 0.26, col)
		_:
			var pts := polygon_points(shape, c, r)
			ci.draw_colored_polygon(pts, dark)
			var inner := polygon_points(shape, c + Vector2(0, -r * 0.05), r * 0.88)
			ci.draw_colored_polygon(inner, col)
	# sheen
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.34), r * 0.17, light)


static func _rounded_rect(ci: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	ci.draw_style_box(sb, rect)


## Padlock badge, drawn within a box of size s at p (top-left).
## key_type >= 0 shows the shape that opens it; < 0 draws a plain keyhole.
static func draw_lock(ci: CanvasItem, p: Vector2, s: float, key_type: int) -> void:
	var cx := p.x + s / 2.0
	var body := Rect2(p + Vector2(0, s * 0.42), Vector2(s, s * 0.58))
	var sw := maxf(2.5, s * 0.13)
	var sh_w := s * 0.28
	var sh_top := p.y + s * 0.06
	ci.draw_polyline(PackedVector2Array([Vector2(cx - sh_w, body.position.y + 2), Vector2(cx - sh_w, sh_top + sh_w), Vector2(cx - sh_w * 0.4, sh_top + sh_w * 0.15), Vector2(cx + sh_w * 0.4, sh_top + sh_w * 0.15), Vector2(cx + sh_w, sh_top + sh_w), Vector2(cx + sh_w, body.position.y + 2)]), UI.INK, sw, true)
	_rounded_rect(ci, body, s * 0.16, UI.INK)
	if key_type >= 0:
		draw_object(ci, key_type, body.get_center() + Vector2(0, s * 0.01), s * 0.2)
	else:
		ci.draw_circle(body.get_center() + Vector2(0, -s * 0.04), s * 0.1, Color.WHITE)
		ci.draw_rect(Rect2(body.get_center() + Vector2(-s * 0.03, -s * 0.02), Vector2(s * 0.06, s * 0.2)), Color.WHITE)


static func draw_snow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for i in 3:
		var a := i * PI / 3.0
		var d := Vector2(cos(a), sin(a)) * r
		ci.draw_line(c - d, c + d, col, maxf(2.0, r * 0.18), true)


# ---------------------------------------------------------------- icons

## icon names: undo hint restart pause back coin star sound sound_off music music_off check close home play
static func draw_icon(ci: CanvasItem, name: String, c: Vector2, r: float, col: Color) -> void:
	var w := maxf(3.0, r * 0.16)
	match name:
		"undo":
			ci.draw_arc(c + Vector2(r * 0.05, r * 0.1), r * 0.62, PI * 1.15, PI * 2.55, 20, col, w, true)
			var tip := c + Vector2(-r * 0.58, -r * 0.18)
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-r * 0.32, r * 0.12), tip + Vector2(r * 0.34, -r * 0.06), tip + Vector2(r * 0.12, r * 0.42)]), col)
		"restart":
			ci.draw_arc(c, r * 0.62, -PI * 0.25, PI * 1.45, 24, col, w, true)
			var tip2 := c + Vector2(r * 0.44, -r * 0.44)
			ci.draw_colored_polygon(PackedVector2Array([tip2 + Vector2(r * 0.34, r * 0.0), tip2 + Vector2(-r * 0.1, -r * 0.34), tip2 + Vector2(-r * 0.2, r * 0.3)]), col)
		"hint":
			ci.draw_circle(c + Vector2(0, -r * 0.16), r * 0.5, col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.22, r * 0.28), Vector2(r * 0.44, r * 0.22)), col)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.16, r * 0.56), Vector2(r * 0.32, r * 0.12)), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.42, -r * 0.5), Vector2(r * 0.28, r)), col)
			ci.draw_rect(Rect2(c + Vector2(r * 0.14, -r * 0.5), Vector2(r * 0.28, r)), col)
		"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.2, -r * 0.55), c + Vector2(-r * 0.35, 0), c + Vector2(r * 0.2, r * 0.55)]), col, w, true)
		"coin":
			ci.draw_circle(c, r, Color("c98a00"))
			ci.draw_circle(c, r * 0.86, UI.WARN)
			ci.draw_arc(c, r * 0.55, 0, TAU, 20, Color("c98a00"), maxf(2.0, r * 0.14), true)
		"star", "star_off":
			var pts := polygon_points("star", c, r * 0.9)
			var fill := UI.WARN if name == "star" else Color("d8d2c4")
			ci.draw_colored_polygon(pts, fill)
		"sound", "sound_off":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.25), c + Vector2(-r * 0.3, -r * 0.25), c + Vector2(r * 0.15, -r * 0.65), c + Vector2(r * 0.15, r * 0.65), c + Vector2(-r * 0.3, r * 0.25), c + Vector2(-r * 0.7, r * 0.25)]), col)
			if name == "sound":
				ci.draw_arc(c + Vector2(r * 0.1, 0), r * 0.45, -PI * 0.3, PI * 0.3, 10, col, w, true)
				ci.draw_arc(c + Vector2(r * 0.1, 0), r * 0.8, -PI * 0.3, PI * 0.3, 10, col, w, true)
			else:
				ci.draw_line(c + Vector2(r * 0.35, -r * 0.4), c + Vector2(r * 0.85, r * 0.4), col, w, true)
				ci.draw_line(c + Vector2(r * 0.85, -r * 0.4), c + Vector2(r * 0.35, r * 0.4), col, w, true)
		"music", "music_off":
			ci.draw_circle(c + Vector2(-r * 0.3, r * 0.45), r * 0.3, col)
			ci.draw_line(c + Vector2(-r * 0.02, r * 0.45), c + Vector2(-r * 0.02, -r * 0.6), col, w)
			ci.draw_line(c + Vector2(-r * 0.02, -r * 0.6), c + Vector2(r * 0.5, -r * 0.35), col, w * 1.4)
			if name == "music_off":
				ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.7, -r * 0.7), UI.ACCENT, w, true)
		"lock":
			draw_lock(ci, c - Vector2(r * 0.5, r * 0.6), r, -1)
		"out":
			ci.draw_line(c + Vector2(0, r * 0.55), c + Vector2(0, -r * 0.5), col, w * 1.3, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, -r * 0.1), c + Vector2(0, -r * 0.6), c + Vector2(r * 0.45, -r * 0.1)]), col, w * 1.3, true)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.5, 0), c + Vector2(-r * 0.12, r * 0.4), c + Vector2(r * 0.55, -r * 0.4)]), col, w * 1.2, true)
		"close":
			ci.draw_line(c + Vector2(-r * 0.45, -r * 0.45), c + Vector2(r * 0.45, r * 0.45), col, w, true)
			ci.draw_line(c + Vector2(r * 0.45, -r * 0.45), c + Vector2(-r * 0.45, r * 0.45), col, w, true)
