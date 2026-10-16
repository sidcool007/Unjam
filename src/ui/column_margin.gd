class_name ColumnMargin
extends MarginContainer
## Full-screen margin container that (a) keeps content out of system bars and
## display cutouts and (b) limits content to a centred column, so landscape,
## tablet and foldable windows (which Android 16 no longer forces to portrait)
## look like the phone layout instead of stretching. Recomputes on every resize,
## so rotating the device re-flows an already-open screen.

var base := Vector4(24, 18, 24, 18)  # left, top, right, bottom minimum margins
var max_width := 780.0


static func make(min_left: int, min_top: int, min_right: int, min_bottom: int, max_w: float = 780.0) -> ColumnMargin:
	var c := ColumnMargin.new()
	c.base = Vector4(min_left, min_top, min_right, min_bottom)
	c.max_width = max_w
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


func _ready() -> void:
	apply()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		apply()


func apply() -> void:
	var ins := UI.safe_insets(get_viewport()) if is_inside_tree() else Vector4.ZERO
	var m := compute_margins(size.x, base, ins, max_width)
	add_theme_constant_override("margin_left", int(m.x))
	add_theme_constant_override("margin_top", int(m.y))
	add_theme_constant_override("margin_right", int(m.z))
	add_theme_constant_override("margin_bottom", int(m.w))


## Pure: margins (l, t, r, b) for a container `width` wide. Safe-area insets add
## to the minimum top/bottom, and win on the sides; extra width is split evenly.
static func compute_margins(width: float, base_m: Vector4, insets: Vector4, max_w: float) -> Vector4:
	var side := maxf(0.0, (width - max_w) / 2.0)
	return Vector4(
		maxf(maxf(base_m.x, insets.x), side),
		maxf(base_m.y, insets.y + 8.0),
		maxf(maxf(base_m.z, insets.z), side),
		maxf(base_m.w, insets.w + 8.0))
