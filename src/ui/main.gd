extends Control
## Screen host: owns navigation, fade transitions and the safe area.

var _current: Control
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Progress.level_count = Levels.count()
	Progress.load_data()
	Audio.start_music()
	_fade = ColorRect.new()
	_fade.color = UI.BG
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 100
	_fade.modulate.a = 0.0
	add_child(_fade)
	_show(_make_splash())


func _make_splash() -> Control:
	var s := SplashScreen.new()
	s.main = self
	return s


func open_menu() -> void:
	_go(func():
		var s := MenuScreen.new()
		s.main = self
		return s)


func open_levels() -> void:
	_go(func():
		var s := LevelSelectScreen.new()
		s.main = self
		return s)


func open_credits() -> void:
	_go(func():
		var s := CreditsScreen.new()
		s.main = self
		return s)


func open_game(id: int, fresh: bool = false) -> void:
	if not Levels.has_level(id) or not Progress.is_unlocked(id):
		open_levels()
		return
	if fresh:
		Progress.clear_session()
	_go(func():
		var s := GameScreen.new()
		s.main = self
		s.level_id = id
		return s)


func _go(factory: Callable) -> void:
	if _busy:
		return
	_busy = true
	var dur := 0.0 if Progress.settings["reduce_motion"] else 0.14
	if dur > 0.0:
		var tw := create_tween()
		tw.tween_property(_fade, "modulate:a", 1.0, dur)
		await tw.finished
	_show(factory.call())
	if dur > 0.0:
		var tw2 := create_tween()
		tw2.tween_property(_fade, "modulate:a", 0.0, dur)
		await tw2.finished
	_busy = false


func _show(screen: Control) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	add_child(screen)
	move_child(screen, 0)
