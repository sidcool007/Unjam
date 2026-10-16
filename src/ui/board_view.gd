class_name BoardView
extends Control
## Renders a GameSession's board and animates changes. The BoardState inside the
## session is the single source of truth: this view only mirrors it, and is
## rebuilt from it whenever it could drift (undo / restart / restore).
## Input is locked (`busy`) while animations run.

signal tray_tapped(index: int)
signal busy_changed(is_busy: bool)

var session: GameSession
var trays: Array[TrayView] = []
var objs: Array = []  # per tray: Array[ObjectView], bottom -> top
var busy := false:
	set(v):
		if busy != v:
			busy = v
			if not v and _relayout_pending:
				_relayout_pending = false
				rebuild(false)
			busy_changed.emit(v)
var reduce_motion := false
var selected_tray := -1
var _hint_from := -1
var _hint_to := -1
var _hint_tween: Tween
var _slot := 80.0
var _lift := 56.0
var _layer: Control  # objects live above trays so they can travel across
var _tray_base_x: Array = []  # canonical x of each tray (shake always returns here)
var _relayout_pending := false


func _ready() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_PASS


func setup(s: GameSession) -> void:
	session = s
	rebuild(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and session != null:
		if busy:
			_relayout_pending = true  # applied as soon as the animation ends
		else:
			rebuild(false)


# ---------------------------------------------------------------- layout

func _compute_layout() -> Dictionary:
	var b := session.board
	var n := b.tray_count()
	var cols := n if n <= 4 else (3 if n <= 6 else (4 if n <= 8 else 5))
	var rows := ceili(float(n) / cols)
	var maxcap := 0
	for c in b.caps:
		maxcap = maxi(maxcap, c)
	var gap := 40.0  # room for the rule-tag badge that straddles each tray's top edge
	var cell_w := size.x / cols
	var by_h := (size.y - (rows - 1) * gap) / (rows * (maxcap + 0.3) + 0.7)
	var by_w := (cell_w - 16.0) / 1.3
	var slot := clampf(minf(by_h, by_w), 36.0, 112.0)
	return {"cols": cols, "rows": rows, "maxcap": maxcap, "gap": gap, "cell_w": cell_w, "slot": slot}


func rebuild(animate: bool) -> void:
	if session == null or size.x < 10.0:
		return
	clear_hint()
	for t in trays:
		t.queue_free()
	trays.clear()
	if _layer != null:
		_layer.queue_free()
	objs.clear()
	_layer = Control.new()
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var b := session.board
	var lay := _compute_layout()
	_slot = lay["slot"]
	_lift = _slot * 0.7
	_tray_base_x.clear()
	var rows: int = lay["rows"]
	var cols: int = lay["cols"]
	var row_h: float = (lay["maxcap"] + 0.3) * _slot
	var total_h: float = rows * row_h + (rows - 1) * float(lay["gap"]) + _lift
	var y0 := maxf(0.0, size.y - total_h) * 0.58 + _lift  # sit slightly low: nearer the thumb, less dead space under the HUD
	for i in b.tray_count():
		var tv := TrayView.new()
		tv.configure(i, b.caps[i], _slot, b.accepts[i], b.source_only[i] == 1, lay["cell_w"])
		var r: int = i / cols
		var c: int = i % cols
		var in_row: int = mini(cols, b.tray_count() - r * cols)
		var x_off: float = (cols - in_row) * lay["cell_w"] / 2.0
		tv.position = Vector2(x_off + c * lay["cell_w"], y0 + r * (row_h + lay["gap"]) + (row_h - tv.size.y))
		_tray_base_x.append(tv.position.x)
		tv.tapped.connect(func(idx): tray_tapped.emit(idx))
		add_child(tv)
		trays.append(tv)
	add_child(_layer)
	for i in b.tray_count():
		var list: Array = []
		var st: PackedInt32Array = b.stacks[i]
		for j in st.size():
			var ov := ObjectView.new()
			ov.setup(st[j], _slot)
			ov.position = _slot_pos(i, j)
			_layer.add_child(ov)
			list.append(ov)
		objs.append(list)
	selected_tray = -1
	_hint_from = -1
	_hint_to = -1
	refresh()
	if animate and not reduce_motion:
		busy = true
		var tw := _layer.create_tween().set_parallel(true)
		for list in objs:
			for ov: ObjectView in list:
				ov.scale = Vector2(0.4, 0.4)
				ov.modulate.a = 0.0
				tw.tween_property(ov, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(ov, "modulate:a", 1.0, 0.14)
		tw.chain().tween_callback(func(): busy = false)


## Top-left position of the object view for slot j of tray i.
func _slot_pos(i: int, j: int) -> Vector2:
	var tv := trays[i]
	return Vector2(_tray_base_x[i], tv.position.y) + tv.slot_center(j) - Vector2(_slot, _slot) / 2.0


func _lift_pos(i: int) -> Vector2:
	var tv := trays[i]
	return Vector2(_tray_base_x[i], tv.position.y) + Vector2(tv.size.x / 2.0 - _slot / 2.0, -_slot * 0.95)


# ---------------------------------------------------------------- state mirroring

## Pushes lock / frozen / selection state from the model into every visual.
func refresh() -> void:
	var b := session.board
	for i in objs.size():
		var list: Array = objs[i]
		for j in list.size():
			var ov: ObjectView = list[j]
			var o := ov.code
			ov.set_state(b.is_locked(o), b.thaw_in(o), selected_tray == i and j == list.size() - 1)
	for i in trays.size():
		var valid := false
		if selected_tray >= 0 and i != selected_tray:
			valid = b.check_move(selected_tray, i) == BoardState.Reason.OK
		trays[i].set_flags(valid, i == selected_tray, i == _hint_to or (i == _hint_from and selected_tray != i))


func select(tray: int) -> void:
	clear_hint()
	selected_tray = tray
	var list: Array = objs[tray]
	if not list.is_empty():
		var ov: ObjectView = list[list.size() - 1]
		var target := _slot_pos(tray, list.size() - 1) + Vector2(0, -_slot * 0.45)
		_tween_to(ov, target, 0.1)
	refresh()


func deselect() -> void:
	if selected_tray < 0:
		return
	var t := selected_tray
	selected_tray = -1
	var list: Array = objs[t]
	if not list.is_empty():
		_tween_to(list[list.size() - 1], _slot_pos(t, list.size() - 1), 0.1)
	refresh()


## Every node has at most ONE running position tween. Starting a new one kills
## the old, so overlapping select/deselect/shake/move can never leave a node
## stranded at an in-between position.
func _kill_pos_tween(node: Control) -> void:
	if node.has_meta("pos_tween"):
		var old = node.get_meta("pos_tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
		node.remove_meta("pos_tween")


func _pos_tween(node: Control) -> Tween:
	_kill_pos_tween(node)
	var tw := node.create_tween()
	node.set_meta("pos_tween", tw)
	return tw


func _tween_to(node: Control, pos: Vector2, dur: float) -> void:
	if reduce_motion:
		_kill_pos_tween(node)
		node.position = pos
		return
	_pos_tween(node).tween_property(node, "position", pos, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## True when no move/shake/lift tween is still running on any tray or object.
func settled() -> bool:
	if busy:
		return false
	var nodes: Array = []
	nodes.append_array(trays)
	for list in objs:
		nodes.append_array(list)
	for n in nodes:
		if n.has_meta("pos_tween"):
			var tw = n.get_meta("pos_tween")
			if tw is Tween and (tw as Tween).is_valid() and (tw as Tween).is_running():
				return false
	return true


# ---------------------------------------------------------------- animations

## The model has ALREADY applied the move (result). Mirror it visually.
func animate_move(result: Dictionary) -> void:
	clear_hint()
	var from: int = result["from"]
	var to: int = result["to"]
	selected_tray = -1
	var src_list: Array = objs[from]
	if src_list.is_empty():
		rebuild(false)  # drifted: recover from the authoritative model
		return
	refresh()  # selection is over: drop destination highlights immediately
	var ov: ObjectView = src_list.pop_back()
	var dst_list: Array = objs[to]
	var landing := _slot_pos(to, dst_list.size())
	dst_list.append(ov)
	busy = true
	ov.z_index = 5
	var cleared: bool = result["cleared"]
	if reduce_motion:
		_tween_to(ov, landing, 0.0)
		_finish_move(ov, to, cleared)
		return
	var tw := _pos_tween(ov)
	tw.tween_property(ov, "position", _lift_pos(from), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ov, "position", _lift_pos(to), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(ov, "position", landing, 0.10).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _finish_move(ov, to, cleared))


func _finish_move(ov: ObjectView, to: int, cleared: bool) -> void:
	ov.z_index = 0
	refresh()
	if not cleared:
		busy = false
		return
	# tray complete: celebratory pop, then remove the objects
	var list: Array = objs[to]
	var tv := trays[to]
	if reduce_motion:
		for x: ObjectView in list:
			x.queue_free()
		list.clear()
		refresh()
		busy = false
		return
	var tw := create_tween().set_parallel(true)
	for x: ObjectView in list:
		tw.tween_property(x, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(x, "modulate:a", 0.0, 0.2).set_delay(0.12)
	tw.tween_method(tv.set_flash, 1.0, 0.0, 0.4)
	tw.chain().tween_callback(func():
		for x: ObjectView in list:
			x.queue_free()
		list.clear()
		refresh()
		busy = false)


func shake(tray: int) -> void:
	if reduce_motion or tray < 0 or tray >= trays.size():
		return
	var tv := trays[tray]
	var base_x: float = _tray_base_x[tray]
	var tw := _pos_tween(tv)
	for d in [8.0, -8.0, 5.0, -5.0, 0.0]:
		tw.tween_property(tv, "position:x", base_x + d, 0.04)
	var list: Array = objs[tray]
	if not list.is_empty() and selected_tray != tray:
		var top: ObjectView = list[list.size() - 1]
		var base := _slot_pos(tray, list.size() - 1)
		var tw2 := _pos_tween(top)
		for d in [8.0, -8.0, 5.0, -5.0, 0.0]:
			tw2.tween_property(top, "position", base + Vector2(d, 0), 0.04)


# ---------------------------------------------------------------- hint

## Highlights a suggested move. from < 0 shows only the destination tray; to < 0 only the source.
func show_hint(from: int, to: int) -> void:
	clear_hint()
	if from >= 0:
		deselect()
	_hint_from = from
	_hint_to = to
	refresh()
	if from < 0 or objs[from].is_empty():
		return
	var ov: ObjectView = objs[from][objs[from].size() - 1]
	ov.set_state(ov.locked, ov.frozen_left, true)
	if not reduce_motion:
		_hint_tween = ov.create_tween().set_loops()
		_hint_tween.tween_property(ov, "scale", Vector2(1.15, 1.15), 0.4)
		_hint_tween.tween_property(ov, "scale", Vector2.ONE, 0.4)


func clear_hint() -> void:
	if _hint_tween != null:
		_hint_tween.kill()
		_hint_tween = null
	if _hint_from >= 0 and _hint_from < objs.size():
		for ov in objs[_hint_from]:
			(ov as ObjectView).scale = Vector2.ONE
	var had := _hint_from >= 0 or _hint_to >= 0
	_hint_from = -1
	_hint_to = -1
	if had and session != null:
		refresh()
