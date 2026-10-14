class_name GameSession
extends RefCounted
## One play-through of one level: wraps the authoritative BoardState and adds
## undo history, restart, and the PLAYING/WON/FAILED status machine.
## Emits signals; never touches UI or storage.

signal moved(result: Dictionary)
signal undone
signal restarted
signal won
signal failed

enum Status { PLAYING, WON, FAILED }

const MAX_HISTORY := 400

var level: Dictionary
var board: BoardState
var status: int = Status.PLAYING
var history: Array = []  # snapshots taken BEFORE each applied move
var _initial: Dictionary
var _terminal_emitted := false


func _init(level_dict: Dictionary) -> void:
	level = level_dict
	board = BoardState.from_level(level_dict)
	_initial = board.snapshot()


func has_progress() -> bool:
	return board.moves > 0


## Attempts a move. Illegal moves return {ok:false, reason} and change nothing.
func try_move(from: int, to: int) -> Dictionary:
	if status != Status.PLAYING:
		return {"ok": false, "reason": BoardState.Reason.GAME_OVER}
	var snap := board.snapshot()
	var result := board.apply_move(from, to)
	if not result["ok"]:
		return result
	history.append(snap)
	if history.size() > MAX_HISTORY:
		history.pop_front()
	moved.emit(result)
	_update_status()
	return result


func _update_status() -> void:
	if board.is_won():
		status = Status.WON
		if not _terminal_emitted:
			_terminal_emitted = true
			won.emit()
	elif board.is_failed():
		status = Status.FAILED
		if not _terminal_emitted:
			_terminal_emitted = true
			failed.emit()


func can_undo() -> bool:
	return status != Status.WON and not history.is_empty()


## Restores the exact previous state (tray contents, moves, cleared set).
func undo() -> bool:
	if not can_undo():
		return false
	board.restore(history.pop_back())
	status = Status.PLAYING
	_terminal_emitted = false
	undone.emit()
	return true


func restart() -> void:
	board.restore(_initial)
	history.clear()
	status = Status.PLAYING
	_terminal_emitted = false
	restarted.emit()


# ------------------------------------------------------------- persistence

func to_dict() -> Dictionary:
	return {"level": int(level["id"]), "state": board.snapshot(), "history": history.duplicate(true)}


## Restores from a saved dict; returns false (leaving the session untouched)
## if the data does not fit this level.
func restore_from(d: Variant) -> bool:
	if not (d is Dictionary) or int(d.get("level", -1)) != int(level["id"]):
		return false
	if not board.snapshot_is_valid(d.get("state")):
		return false
	var hist = d.get("history", [])
	if not (hist is Array) or hist.size() > MAX_HISTORY:
		return false
	for h in hist:
		if not board.snapshot_is_valid(h):
			return false
	board.restore(d["state"])
	history.clear()
	for h in hist:
		var s := {"stacks": h["stacks"], "moves": int(h["moves"]), "cleared": int(h["cleared"])}
		history.append(s)
	status = Status.PLAYING
	_terminal_emitted = true  # restoring never re-fires win/fail signals
	_update_status()
	return true
