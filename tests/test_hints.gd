extends TestCase


func test_hint_is_always_a_legal_move_and_wins() -> void:
	var lv := tiny_level({"solution": []})
	lv["trays"] = [{"cap": 3, "items": [0, 1, 0]}, {"cap": 3, "items": [1, 0, 1]},
		{"cap": 3, "items": []}, {"cap": 3, "items": []}]
	var s := GameSession.new(lv)
	var guard := 0
	while s.status == GameSession.Status.PLAYING and guard < 40:
		guard += 1
		var h := HintService.get_hint(s)
		eq(h["kind"], HintService.Kind.MOVE)
		if h["kind"] != HintService.Kind.MOVE:
			return
		var r := s.try_move(h["from"], h["to"])
		check(r["ok"], "hint move accepted by the real rules")
		if not r["ok"]:
			return
	eq(s.status, GameSession.Status.WON, "following hints solves the level")


func test_hint_detects_unwinnable_position() -> void:
	# one tray can never clear: type 1 has 2 objects but all trays have cap 3
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 3, "items": [0, 1, 0]}, {"cap": 3, "items": [1, 0]}, {"cap": 3, "items": []}],
		"solution": []}
	var s := GameSession.new(lv)
	var h := HintService.get_hint(s)
	eq(h["kind"], HintService.Kind.UNSOLVABLE, "exhaustive search proves no solution")
	check(String(h["message"]) != "")


func test_hint_after_mistake_still_valid_or_reports_dead_end() -> void:
	var lv := {"id": 1, "types": 2, "trays": [
		{"cap": 3, "items": [0, 1, 0]}, {"cap": 3, "items": [1, 0, 1]}, {"cap": 3, "items": []}],
		"solution": []}
	var s := GameSession.new(lv)
	s.try_move(0, 2)
	s.try_move(1, 0)   # exposes shape-1 on tray 0? whatever: arbitrary legal moves
	var h := HintService.get_hint(s)
	if h["kind"] == HintService.Kind.MOVE:
		eq(s.board.check_move(h["from"], h["to"]), BoardState.Reason.OK)
	else:
		check(h["kind"] == HintService.Kind.UNSOLVABLE)


func test_hint_not_available_after_finish() -> void:
	var lv := {"id": 1, "types": 1, "trays": [{"cap": 2, "items": [0]}, {"cap": 2, "items": [0]}], "solution": []}
	var s := GameSession.new(lv)
	s.try_move(0, 1)
	eq(s.status, GameSession.Status.WON)
	eq(HintService.get_hint(s)["kind"], HintService.Kind.UNAVAILABLE)
