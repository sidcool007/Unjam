class_name GameScreen
extends Control
## Gameplay screen: HUD + BoardView + flows (hint, undo, restart, win, fail).
## Rules live in GameSession/BoardState; this screen only wires input to them.

var main  # Main (screen host)
var level_id := 1
var session: GameSession
var board_view: BoardView

var _level_label: Label
var _sub_label: Label
var _coins_label: Label
var _moves_chip: Label
var _free_chip: Label
var _undo_btn: IconButton
var _hint_btn: IconButton
var _restart_btn: IconButton
var _toast: Label
var _toast_tween: Tween
var _coach: Label
var _modal_open := 0
var _terminal_handled := false
var _reward_done := false
var _tutorial := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var lv: Dictionary = Levels.get_level(level_id)
	session = GameSession.new(lv)
	_restore_saved_session()
	_build_ui(lv)
	board_view.reduce_motion = bool(Progress.settings["reduce_motion"])
	board_view.setup(session)
	board_view.tray_tapped.connect(_on_tray_tapped)
	board_view.busy_changed.connect(_on_busy_changed)
	Progress.coins_changed.connect(func(_c): _update_hud())
	Progress.set_current_level(level_id)
	_update_hud()
	_tutorial = level_id == 1 and not Progress.tutorial_done
	_after_enter.call_deferred()


func _restore_saved_session() -> void:
	var s = Progress.session
	if s is Dictionary and int(s.get("level", -1)) == level_id:
		if not session.restore_from(s):
			Progress.clear_session()


func _after_enter() -> void:
	if session.status != GameSession.Status.PLAYING:
		return
	var intro: String = str(session.level.get("intro", ""))
	if intro != "" and not Progress.seen_intros.has(level_id) and not session.has_progress():
		Progress.mark_intro_seen(level_id)
		_show_intro(intro)
	_update_coach()


# ------------------------------------------------------------------ UI

func _build_ui(lv: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ins := UI.safe_insets(get_viewport())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(maxf(20, ins.x)))
	margin.add_theme_constant_override("margin_right", int(maxf(20, ins.z)))
	margin.add_theme_constant_override("margin_top", int(maxf(18, ins.y + 8)))
	margin.add_theme_constant_override("margin_bottom", int(maxf(18, ins.w + 8)))
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	# top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)
	var pause := IconButton.make("pause", "", Vector2(UI.MIN_TOUCH, UI.MIN_TOUCH))
	pause.pressed.connect(_on_pause)
	top.add_child(pause)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	_level_label = UI.label("Level %d" % level_id, UI.FONT_H1)
	_sub_label = UI.label(str(lv.get("name", "")), UI.FONT_SMALL, UI.INK_SOFT)
	titles.add_child(_level_label)
	titles.add_child(_sub_label)
	top.add_child(titles)
	var coin_chip := PanelContainer.new()
	coin_chip.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 30, UI.TRAY_EDGE, 2))
	coin_chip.custom_minimum_size = Vector2(150, UI.MIN_TOUCH)
	var ch := HBoxContainer.new()
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_theme_constant_override("separation", 8)
	coin_chip.add_child(ch)
	var coin_icon := Control.new()
	coin_icon.custom_minimum_size = Vector2(36, 36)
	coin_icon.draw.connect(func(): Shapes.draw_icon(coin_icon, "coin", Vector2(18, 18), 16, UI.WARN))
	coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ch.add_child(coin_icon)
	_coins_label = UI.label("0", UI.FONT_H2)
	ch.add_child(_coins_label)
	top.add_child(coin_chip)

	# info chips
	var info := HBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 14)
	vb.add_child(info)
	_moves_chip = _chip(info)
	_free_chip = _chip(info)

	# coach text (tutorial)
	_coach = UI.wrap_label("", UI.FONT_BODY, UI.INK)
	_coach.visible = false
	_coach.custom_minimum_size = Vector2(0, 76)
	vb.add_child(_coach)

	board_view = BoardView.new()
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(board_view)

	# bottom bar
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	vb.add_child(bottom)
	_undo_btn = IconButton.make("undo", "Undo")
	_undo_btn.pressed.connect(_on_undo)
	bottom.add_child(_undo_btn)
	_hint_btn = IconButton.make("hint", "Hint")
	_hint_btn.pressed.connect(_on_hint)
	bottom.add_child(_hint_btn)
	_restart_btn = IconButton.make("restart", "Restart")
	_restart_btn.pressed.connect(_on_restart)
	bottom.add_child(_restart_btn)

	_toast = UI.label("", UI.FONT_BODY, Color.WHITE)
	_toast.add_theme_stylebox_override("normal", UI.box(Color(UI.INK, 0.92), 28))
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.custom_minimum_size = Vector2(560, 64)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position = Vector2(80, 1010)
	_toast.modulate.a = 0.0
	_toast.z_index = 20
	add_child(_toast)


func _chip(parent: Control) -> Label:
	var l := UI.label("", UI.FONT_BODY, UI.INK)
	l.add_theme_stylebox_override("normal", _chip_style(UI.PANEL))
	l.custom_minimum_size = Vector2(250, 56)
	parent.add_child(l)
	return l


func _chip_style(fill: Color) -> StyleBoxFlat:
	var sb := UI.box(fill, 28, UI.TRAY_EDGE, 2)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	return sb


func _update_hud() -> void:
	if session == null or _coins_label == null:
		return
	var b := session.board
	_coins_label.text = str(Progress.coins)
	if b.max_moves > 0:
		var left := b.moves_left()
		_moves_chip.text = "Moves left: %d" % left
		_moves_chip.add_theme_stylebox_override("normal", _chip_style(Color("ffd9d3") if left <= 3 else UI.PANEL))
	else:
		_moves_chip.text = "Moves: %d" % b.moves
		_moves_chip.add_theme_stylebox_override("normal", _chip_style(UI.PANEL))
	var free := b.free_slots()
	_free_chip.text = "Last slot!" if free == 1 else "Free slots: %d" % free
	_free_chip.add_theme_stylebox_override("normal", _chip_style(Color("ffe9a8") if free <= 1 else UI.PANEL))
	var playing := session.status == GameSession.Status.PLAYING
	var idle := playing and not board_view.busy and _modal_open == 0
	_undo_btn.disabled = not (session.can_undo() and not board_view.busy)
	_hint_btn.disabled = not idle
	_restart_btn.disabled = board_view.busy
	_hint_btn.refresh("%d" % Progress.HINT_COST)
	_undo_btn.queue_redraw()
	_restart_btn.queue_redraw()


func _show_toast(text: String) -> void:
	if text == "":
		return
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.9)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)


# ------------------------------------------------------------------ input / moves

func _on_tray_tapped(i: int) -> void:
	if board_view.busy or _modal_open > 0 or session.status != GameSession.Status.PLAYING:
		return
	board_view.clear_hint()
	var sel := board_view.selected_tray
	if sel < 0:
		var pick := session.board.check_pick(i)
		if pick == BoardState.Reason.OK:
			Audio.play("select")
			board_view.select(i)
		else:
			Audio.play("invalid")
			board_view.shake(i)
			_show_toast(CampaignText.reason_text(pick))
		_update_coach()
		return
	if sel == i:
		Audio.play("tap")
		board_view.deselect()
		_update_coach()
		return
	var res := session.try_move(sel, i)
	if res["ok"]:
		Audio.play("clear" if res["cleared"] else "move")
		board_view.animate_move(res)
		_after_move()
	else:
		Audio.play("invalid")
		board_view.shake(i)
		_show_toast(CampaignText.reason_text(res["reason"]))


func _after_move() -> void:
	_update_hud()
	if session.status == GameSession.Status.PLAYING:
		Progress.save_session(session.to_dict())
	_update_coach()


func _on_busy_changed(is_busy: bool) -> void:
	_update_hud()
	if not is_busy:
		_check_terminal()
		_update_coach()


func _check_terminal() -> void:
	if _terminal_handled or board_view.busy:
		return
	if session.status == GameSession.Status.WON:
		_terminal_handled = true
		_handle_win.call_deferred()
	elif session.status == GameSession.Status.FAILED:
		_terminal_handled = true
		_handle_fail.call_deferred()


func _handle_win() -> void:
	if _reward_done:
		return
	_reward_done = true
	var par := Levels.par(level_id)
	var res := Progress.complete_level(level_id, session.board.moves, par)
	if _tutorial:
		Progress.set_tutorial_done()
	Audio.play("win")
	_update_hud()
	_coach.visible = false
	var m := Modal.make("Level %d clear!" % level_id, false)
	var stars := Control.new()
	stars.custom_minimum_size = Vector2(0, 110)
	var st: int = res["stars"]
	stars.draw.connect(func():
		for k in 3:
			Shapes.draw_icon(stars, "star" if k < st else "star_off", Vector2(stars.size.x / 2.0 + (k - 1) * 120.0, 58.0 - (14.0 if k == 1 else 0.0)), 52.0 if k == 1 else 44.0, UI.WARN))
	m.add_content(stars)
	m.add_text("Solved in %d moves (par %d)" % [session.board.moves, par], UI.INK_SOFT, UI.FONT_BODY)
	if res["coins_awarded"] > 0:
		m.add_text("+%d coins" % res["coins_awarded"], UI.INK, UI.FONT_H2)
		Audio.play("coin")
	else:
		m.add_text("Replay: no new coins", UI.INK_SOFT, UI.FONT_SMALL)
	var has_next := level_id < Levels.count()
	if has_next:
		m.add_button("Next level", "primary", func(): main.open_game(level_id + 1))
	else:
		m.add_text("You finished every level. Thanks for playing!", UI.INK, UI.FONT_BODY)
	m.add_button("Play again", "secondary", func(): main.open_game(level_id, true))
	m.add_button("Level select", "ghost", func(): main.open_levels())
	_open_modal(m)


func _handle_fail() -> void:
	Audio.play("fail")
	var out_of_moves := session.board.max_moves > 0 and session.board.moves >= session.board.max_moves
	var m := Modal.make("Out of moves" if out_of_moves else "No moves left", false)
	m.add_text("Every slot is blocked or the move limit is reached. Undo to try a different plan." if not out_of_moves else "You ran out of moves. Undo to try a different plan, or restart the level.", UI.INK_SOFT)
	if session.can_undo():
		m.add_button("Undo last move", "primary", func(): _do_undo())
	m.add_button("Restart level", "secondary", func(): _do_restart())
	m.add_button("Level select", "ghost", func(): main.open_levels())
	_open_modal(m)


func _open_modal(m: Modal) -> void:
	_modal_open += 1
	add_child(m)
	_update_hud()
	m.closed.connect(func():
		_modal_open = maxi(0, _modal_open - 1)
		_update_hud()
		_update_coach())


# ------------------------------------------------------------------ buttons

func _on_undo() -> void:
	if board_view.busy or _modal_open > 0:
		return
	_do_undo()


func _do_undo() -> void:
	if board_view.busy:
		return
	if session.undo():
		Audio.play("undo")
		_terminal_handled = false
		board_view.clear_hint()
		board_view.rebuild(true)
		Progress.save_session(session.to_dict())
		_update_hud()
		_update_coach()


func _on_restart() -> void:
	if board_view.busy or _modal_open > 0:
		return
	if session.has_progress():
		var m := Modal.make("Restart level?")
		m.add_text("Your progress in this level will be lost.", UI.INK_SOFT)
		m.add_button("Restart", "danger", func(): _do_restart())
		m.add_button("Keep playing", "secondary")
		_open_modal(m)
	else:
		_do_restart()


func _do_restart() -> void:
	session.restart()
	_terminal_handled = false
	board_view.clear_hint()
	board_view.rebuild(true)
	Progress.clear_session()
	_update_hud()
	_update_coach()


func _on_hint() -> void:
	if board_view.busy or _modal_open > 0 or session.status != GameSession.Status.PLAYING:
		return
	var hint := HintService.get_hint(session)
	match hint["kind"]:
		HintService.Kind.MOVE:
			if not Progress.can_afford(Progress.HINT_COST):
				var m := Modal.make("Not enough coins")
				m.add_text("A hint costs %d coins and you have %d. Complete levels to earn more." % [Progress.HINT_COST, Progress.coins], UI.INK_SOFT)
				m.add_button("OK", "primary")
				_open_modal(m)
				return
			var m2 := Modal.make("Need a hint?")
			m2.add_text("Show a good next move for %d coins? You have %d." % [Progress.HINT_COST, Progress.coins], UI.INK_SOFT)
			m2.add_button("Show hint (%d)" % Progress.HINT_COST, "primary", func(): _apply_hint(hint))
			m2.add_button("Not now", "secondary")
			_open_modal(m2)
		HintService.Kind.UNSOLVABLE:
			var m3 := Modal.make("This can't be finished")
			m3.add_text(str(hint["message"]) + "\n\nNo coins were charged.", UI.INK_SOFT)
			if session.can_undo():
				m3.add_button("Undo last move", "primary", func(): _do_undo())
			m3.add_button("Restart level", "secondary", func(): _do_restart())
			m3.add_button("Close", "ghost")
			_open_modal(m3)
		_:
			var m4 := Modal.make("No hint right now")
			m4.add_text(str(hint["message"]), UI.INK_SOFT)
			m4.add_button("OK", "primary")
			_open_modal(m4)


func _apply_hint(hint: Dictionary) -> void:
	# Re-validate with the real rules and charge only for a legal move.
	if session.board.check_move(hint["from"], hint["to"]) != BoardState.Reason.OK:
		_show_toast("That hint is no longer valid. You weren't charged.")
		return
	if not Progress.spend_coins(Progress.HINT_COST):
		_show_toast("Not enough coins.")
		return
	Audio.play("coin")
	board_view.show_hint(hint["from"], hint["to"])
	_update_hud()


func _on_pause() -> void:
	if board_view.busy or _modal_open > 0:
		return
	var m := Modal.make("Paused")
	m.add_content(SettingsPanel.make())
	m.add_button("Resume", "primary")
	m.add_button("How to play", "secondary", func(): _show_rules())
	m.add_button("Level select", "ghost", func(): main.open_levels())
	_open_modal(m)


func _show_rules() -> void:
	var m := Modal.make("How to play")
	m.add_text(CampaignText.RULES_TEXT, UI.INK, UI.FONT_SMALL + 2)
	m.add_button("Got it", "primary")
	_open_modal(m)


func _show_intro(key: String) -> void:
	if not CampaignText.INTROS.has(key):
		return
	var data: Array = CampaignText.INTROS[key]
	var m := Modal.make(data[0], false)
	m.add_text(data[1], UI.INK)
	m.add_button("Let's go", "primary")
	_open_modal(m)


# ------------------------------------------------------------------ tutorial coach

func _update_coach() -> void:
	if not _tutorial or Progress.tutorial_done or session.status != GameSession.Status.PLAYING:
		_coach.visible = false
		return
	if board_view.busy or _modal_open > 0:
		return
	var hint := HintService.get_hint(session)
	if hint["kind"] != HintService.Kind.MOVE:
		_coach.visible = false
		return
	_coach.visible = true
	if board_view.selected_tray < 0:
		_coach.text = "Tap the glowing tray to lift its top object."
		board_view.show_hint(hint["from"], -1)
	elif board_view.selected_tray == hint["from"]:
		_coach.text = "Now tap the highlighted tray to drop it there."
		board_view.show_hint(-1, hint["to"])
	else:
		_coach.text = "Tap the lifted tray again to put it back, then try the glowing one."
