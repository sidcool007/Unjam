extends Node
## Stand-in for the screen host in UI tests.
var calls: Array = []
func open_game(id: int, fresh: bool = false) -> void:
	calls.append(["game", id, fresh])
func open_levels() -> void:
	calls.append(["levels"])
func open_menu() -> void:
	calls.append(["menu"])
func open_credits() -> void:
	calls.append(["credits"])
