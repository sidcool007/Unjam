class_name Solver
extends RefCounted
## Search over BoardState using the real rules (no duplicated logic).
## Used by the level validator, the level generator, and the hint system.

## BFS: finds a shortest solution. Returns
## {found, moves:[[from,to]...], expanded, exhausted}. `exhausted` means the
## whole reachable space was searched (so found=false proves unsolvable).
static func solve_optimal(start: BoardState, node_budget: int = 400000) -> Dictionary:
	var frontier: Array = [start]
	var parents := {start.key(): null}
	var expanded := 0
	if start.is_won():
		return {"found": true, "moves": [], "expanded": 0, "exhausted": true}
	var depth := 0
	while not frontier.is_empty():
		var next: Array = []
		for st: BoardState in frontier:
			expanded += 1
			if expanded > node_budget:
				return {"found": false, "moves": [], "expanded": expanded, "exhausted": false}
			var pk := st.key()
			for mv in st.legal_moves():
				var c := st.clone()
				c.apply_move(mv[0], mv[1])
				var k := c.key()
				if parents.has(k):
					continue
				parents[k] = [pk, mv]
				if c.is_won():
					return {"found": true, "moves": _path(parents, k), "expanded": expanded,
						"exhausted": false}
				next.append(c)
		frontier = next
		depth += 1
	return {"found": false, "moves": [], "expanded": expanded, "exhausted": true}


static func _path(parents: Dictionary, k: String) -> Array:
	var out := []
	var cur = k
	while parents[cur] != null:
		var p: Array = parents[cur]
		out.push_front(p[1])
		cur = p[0]
	return out


## Weighted best-first search: finds *a* solution quickly (not shortest).
static func solve_fast(start: BoardState, node_budget: int = 60000, weight: float = 3.0) -> Dictionary:
	if start.is_won():
		return {"found": true, "moves": [], "expanded": 0, "exhausted": true}
	var states: Array = [start]
	var meta: Array = [null]  # [parent_index, move]
	var depth: PackedInt32Array = PackedInt32Array([0])
	var seen := {start.key(): true}
	var heap_p: Array = []  # priorities
	var heap_i: Array = []  # node indices
	_push(heap_p, heap_i, _h(start) * weight, 0)
	var expanded := 0
	while not heap_i.is_empty():
		var idx: int = _pop(heap_p, heap_i)
		var st: BoardState = states[idx]
		expanded += 1
		if expanded > node_budget:
			return {"found": false, "moves": [], "expanded": expanded, "exhausted": false}
		for mv in st.legal_moves():
			var c := st.clone()
			c.apply_move(mv[0], mv[1])
			var k := c.key()
			if seen.has(k):
				continue
			seen[k] = true
			states.append(c)
			meta.append([idx, mv])
			depth.append(depth[idx] + 1)
			var ni := states.size() - 1
			if c.is_won():
				var out := []
				var cur := ni
				while meta[cur] != null:
					out.push_front(meta[cur][1])
					cur = meta[cur][0]
				return {"found": true, "moves": out, "expanded": expanded, "exhausted": false}
			_push(heap_p, heap_i, depth[ni] + _h(c) * weight, ni)
	return {"found": false, "moves": [], "expanded": expanded, "exhausted": true}


## Heuristic: objects that are not part of their tray's bottom uniform run
## must move at least once; frozen/locked leftovers add a little.
static func _h(b: BoardState) -> float:
	var h := 0.0
	for s: PackedInt32Array in b.stacks:
		if s.is_empty():
			continue
		var base := BoardState.obj_type(s[0])
		var run := 0
		while run < s.size() and BoardState.obj_type(s[run]) == base:
			run += 1
		h += s.size() - run
	return h


static func _push(hp: Array, hi: Array, p: float, i: int) -> void:
	hp.append(p)
	hi.append(i)
	var n := hp.size() - 1
	while n > 0:
		var par := (n - 1) >> 1
		if hp[par] <= hp[n]:
			break
		var tp = hp[par]
		hp[par] = hp[n]
		hp[n] = tp
		var ti = hi[par]
		hi[par] = hi[n]
		hi[n] = ti
		n = par


static func _pop(hp: Array, hi: Array) -> int:
	var top: int = hi[0]
	var lp = hp.pop_back()
	var li = hi.pop_back()
	if not hp.is_empty():
		hp[0] = lp
		hi[0] = li
		var n := 0
		var size := hp.size()
		while true:
			var l := 2 * n + 1
			var r := l + 1
			var m := n
			if l < size and hp[l] < hp[m]:
				m = l
			if r < size and hp[r] < hp[m]:
				m = r
			if m == n:
				break
			var tp = hp[m]
			hp[m] = hp[n]
			hp[n] = tp
			var ti = hi[m]
			hi[m] = hi[n]
			hi[n] = ti
			n = m
	return top


## Replays a move list on a fresh board; returns {ok, moves_used, error}.
static func replay(level: Dictionary, moves: Array) -> Dictionary:
	var b := BoardState.from_level(level)
	for i in moves.size():
		var r := b.apply_move(int(moves[i][0]), int(moves[i][1]))
		if not r["ok"]:
			return {"ok": false, "error": "move %d (%s->%s) illegal: reason %d" % [i, moves[i][0], moves[i][1], r["reason"]]}
	if not b.is_won():
		return {"ok": false, "error": "solution does not finish the level"}
	return {"ok": true, "moves_used": b.moves}
