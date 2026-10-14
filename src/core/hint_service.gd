class_name HintService
extends RefCounted
## Hints always come from the real rules: search from the player's CURRENT
## board for a winning continuation; if the search budget runs out, fall back
## to the level's validated authored solution when the player's history is
## still on that path. A move is only recommended if check_move() accepts it.

enum Kind { MOVE, UNSOLVABLE, UNAVAILABLE }


## Returns {kind, from, to, message}.
static func get_hint(session: GameSession) -> Dictionary:
	var b := session.board
	if session.status != GameSession.Status.PLAYING:
		return _none("There is nothing to hint right now.")
	var res := Solver.solve_fast(b, 40000, 3.0)
	if res["found"]:
		var mv: Array = res["moves"][0]
		if b.check_move(mv[0], mv[1]) == BoardState.Reason.OK:
			return {"kind": Kind.MOVE, "from": mv[0], "to": mv[1], "message": ""}
	elif res["exhausted"]:
		return {"kind": Kind.UNSOLVABLE,
			"message": "This arrangement can't be finished any more. Undo a few moves or restart."}
	# Budget exhausted: use the authored solution if the player is still on it.
	var sol: Array = session.level.get("solution", [])
	var played := session.board.moves
	if played < sol.size() and _on_authored_path(session, sol):
		var mv: Array = sol[played]
		if b.check_move(int(mv[0]), int(mv[1])) == BoardState.Reason.OK:
			return {"kind": Kind.MOVE, "from": int(mv[0]), "to": int(mv[1]), "message": ""}
	return _none("No reliable hint is available for this position. Try Undo or Restart. You weren't charged.")


static func _on_authored_path(session: GameSession, sol: Array) -> bool:
	var probe := BoardState.from_level(session.level)
	for i in session.board.moves:
		if i >= sol.size():
			return false
		probe.apply_move(int(sol[i][0]), int(sol[i][1]))
	return probe.snapshot() == session.board.snapshot()


static func _none(msg: String) -> Dictionary:
	return {"kind": Kind.UNAVAILABLE, "message": msg}
