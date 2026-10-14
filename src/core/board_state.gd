class_name BoardState
extends RefCounted
## Authoritative game-state model and the ONLY implementation of the rules.
## No UI, no animation, no autoload access. See docs/RULES.md.
##
## Board: a list of trays. Each tray is a stack (index 0 = bottom, last = top)
## with a fixed capacity. Objects are packed ints:
##   bits 0-7   type id (0..N-1)
##   bits 8-15  lock: 0 = none, k+1 = unlocked when a tray of type k is cleared
##   bits 16-31 thaw: 0 = none, n = frozen until the move counter reaches n

enum Reason {
	OK,
	GAME_OVER,
	NO_MOVES_LEFT,
	SAME_TRAY,
	BAD_TRAY,
	EMPTY_SOURCE,
	LOCKED,
	FROZEN,
	SOURCE_ONLY,
	WRONG_TYPE_FOR_TRAY,
	FULL,
	TYPE_MISMATCH,
}

const ANY := -1

# Static per-level configuration (shared between clones).
var caps: PackedInt32Array
var accepts: PackedInt32Array  # ANY or required type for a tray
var source_only: PackedByteArray  # 1 = tray never receives objects
var max_moves: int = 0  # 0 = unlimited
var num_types: int = 0
var groups: Array = []  # interchangeable tray indices (for search symmetry)
var max_thaw: int = 0

# Mutable state.
var stacks: Array = []  # Array[PackedInt32Array]
var moves: int = 0
var cleared_mask: int = 0


static func make_obj(type: int, lock_key: int = -1, thaw_at: int = 0) -> int:
	return type | ((lock_key + 1) << 8) | (thaw_at << 16)


static func obj_type(o: int) -> int:
	return o & 0xFF


static func obj_lock(o: int) -> int:
	return ((o >> 8) & 0xFF) - 1  # -1 = none


static func obj_thaw(o: int) -> int:
	return (o >> 16) & 0xFFFF


func tray_count() -> int:
	return stacks.size()


func clone() -> BoardState:
	var c := BoardState.new()
	c.caps = caps
	c.accepts = accepts
	c.source_only = source_only
	c.max_moves = max_moves
	c.num_types = num_types
	c.groups = groups
	c.max_thaw = max_thaw
	c.moves = moves
	c.cleared_mask = cleared_mask
	c.stacks.resize(stacks.size())
	for i in stacks.size():
		c.stacks[i] = (stacks[i] as PackedInt32Array).duplicate()  # explicit copy: Variant-held packed arrays alias
	return c


## Build from a validated level dictionary (see LevelData.parse).
static func from_level(level: Dictionary) -> BoardState:
	var b := BoardState.new()
	var trays: Array = level["trays"]
	b.caps.resize(trays.size())
	b.accepts.resize(trays.size())
	b.source_only.resize(trays.size())
	b.stacks.resize(trays.size())
	b.max_moves = int(level.get("max_moves", 0))
	b.num_types = int(level["types"])
	for i in trays.size():
		var t: Dictionary = trays[i]
		b.caps[i] = int(t["cap"])
		b.accepts[i] = int(t.get("accepts", ANY))
		b.source_only[i] = 1 if bool(t.get("source_only", false)) else 0
		var s := PackedInt32Array()
		for it in t["items"]:
			var o: int
			if it is Dictionary:
				o = make_obj(int(it["t"]), int(it.get("lock", -1)), int(it.get("ice", 0)))
			else:
				o = make_obj(int(it))
			b.max_thaw = maxi(b.max_thaw, obj_thaw(o))
			s.append(o)
		b.stacks[i] = s
	b._build_groups()
	return b


func _build_groups() -> void:
	var by_cfg := {}
	for i in caps.size():
		var k := "%d/%d/%d" % [caps[i], accepts[i], source_only[i]]
		if not by_cfg.has(k):
			by_cfg[k] = []
		by_cfg[k].append(i)
	groups = by_cfg.values()


# ---------------------------------------------------------------- queries

func top_of(tray: int) -> int:
	var s: PackedInt32Array = stacks[tray]
	return s[s.size() - 1]


func is_locked(o: int) -> bool:
	var k := obj_lock(o)
	return k >= 0 and (cleared_mask >> k) & 1 == 0


func is_frozen(o: int) -> bool:
	return moves < obj_thaw(o)


## Moves remaining until a frozen object thaws (0 when not frozen).
func thaw_in(o: int) -> int:
	return maxi(0, obj_thaw(o) - moves)


func moves_left() -> int:
	return -1 if max_moves == 0 else maxi(0, max_moves - moves)


func is_won() -> bool:
	return _all_empty()


func _all_empty() -> bool:
	for s in stacks:
		if (s as PackedInt32Array).size() > 0:
			return false
	return true


func free_slots() -> int:
	var n := 0
	for i in stacks.size():
		n += caps[i] - (stacks[i] as PackedInt32Array).size()
	return n


func object_count() -> int:
	var n := 0
	for s in stacks:
		n += (s as PackedInt32Array).size()
	return n


## Can the top object of `tray` be picked up? Returns a Reason.
func check_pick(tray: int) -> int:
	if tray < 0 or tray >= stacks.size():
		return Reason.BAD_TRAY
	var s: PackedInt32Array = stacks[tray]
	if s.is_empty():
		return Reason.EMPTY_SOURCE
	var o := s[s.size() - 1]
	if is_locked(o):
		return Reason.LOCKED
	if is_frozen(o):
		return Reason.FROZEN
	return Reason.OK


## The single canonical move validator. Returns a Reason (OK if legal).
func check_move(from: int, to: int) -> int:
	if _all_empty():
		return Reason.GAME_OVER
	if max_moves > 0 and moves >= max_moves:
		return Reason.NO_MOVES_LEFT
	if from < 0 or from >= stacks.size() or to < 0 or to >= stacks.size():
		return Reason.BAD_TRAY
	if from == to:
		return Reason.SAME_TRAY
	var pick := check_pick(from)
	if pick != Reason.OK:
		return pick
	if source_only[to] == 1:
		return Reason.SOURCE_ONLY
	var dst: PackedInt32Array = stacks[to]
	var type := obj_type(top_of(from))
	if accepts[to] != ANY and accepts[to] != type:
		return Reason.WRONG_TYPE_FOR_TRAY
	if dst.size() >= caps[to]:
		return Reason.FULL
	if not dst.is_empty() and obj_type(dst[dst.size() - 1]) != type:
		return Reason.TYPE_MISMATCH
	return Reason.OK


func legal_moves() -> Array:
	var out := []
	for f in stacks.size():
		if check_pick(f) != Reason.OK:
			continue
		for t in stacks.size():
			if check_move(f, t) == Reason.OK:
				out.append([f, t])
	return out


func has_legal_move() -> bool:
	for f in stacks.size():
		if check_pick(f) != Reason.OK:
			continue
		for t in stacks.size():
			if check_move(f, t) == Reason.OK:
				return true
	return false


## Failed = not won and no way to continue (move limit hit or deadlocked).
func is_failed() -> bool:
	if _all_empty():
		return false
	if max_moves > 0 and moves >= max_moves:
		return true
	return not has_legal_move()


## Apply a move. Returns {ok, reason, from, to, type, cleared (bool), unlocked (Array[int])}.
## Illegal moves leave the state completely untouched.
func apply_move(from: int, to: int) -> Dictionary:
	var reason := check_move(from, to)
	if reason != Reason.OK:
		return {"ok": false, "reason": reason}
	var src: PackedInt32Array = stacks[from]
	var o := src[src.size() - 1]
	src.resize(src.size() - 1)
	stacks[from] = src
	var dst: PackedInt32Array = stacks[to]
	dst.append(o)
	stacks[to] = dst
	moves += 1
	var type := obj_type(o)
	var result := {"ok": true, "reason": Reason.OK, "from": from, "to": to, "type": type,
		"cleared": false, "unlocked": []}
	if dst.size() == caps[to] and _is_uniform(dst):
		result["cleared"] = true
		var before_locked := _locked_objects()
		stacks[to] = PackedInt32Array()
		cleared_mask |= 1 << type
		var after_locked := _locked_objects()
		for x in before_locked:
			if not after_locked.has(x):
				result["unlocked"].append(x)
	return result


func _is_uniform(s: PackedInt32Array) -> bool:
	var t := obj_type(s[0])
	for o in s:
		if obj_type(o) != t:
			return false
	return true


func _locked_objects() -> Array:
	var out := []
	for i in stacks.size():
		var s: PackedInt32Array = stacks[i]
		for j in s.size():
			if is_locked(s[j]):
				out.append(i * 100 + j)
	return out


# ---------------------------------------------------------------- search key / save

## Canonical key for search: trays with identical configuration are
## interchangeable, so their contents are sorted.
func key() -> String:
	var parts := PackedStringArray()
	for g in groups:
		var strs := PackedStringArray()
		for i in g:
			strs.append((stacks[i] as PackedInt32Array).to_byte_array().hex_encode())
		strs.sort()
		parts.append(",".join(strs))
	return "|".join(parts) + "#" + str(cleared_mask) + "#" + str(mini(moves, max_thaw))


func snapshot() -> Dictionary:
	var st := []
	for s in stacks:
		st.append(Array(s as PackedInt32Array))
	return {"stacks": st, "moves": moves, "cleared": cleared_mask}


## Restore mutable state from a snapshot (exact inverse of snapshot()).
func restore(snap: Dictionary) -> void:
	moves = int(snap["moves"])
	cleared_mask = int(snap["cleared"])
	for i in stacks.size():
		stacks[i] = PackedInt32Array(snap["stacks"][i])


## Checks a snapshot is structurally compatible with this board's configuration.
func snapshot_is_valid(snap: Variant) -> bool:
	if not (snap is Dictionary):
		return false
	if not (snap.has("stacks") and snap.has("moves") and snap.has("cleared")):
		return false
	if not (snap["stacks"] is Array) or snap["stacks"].size() != stacks.size():
		return false
	if not (snap["moves"] is float or snap["moves"] is int) or snap["moves"] < 0:
		return false
	if not (snap["cleared"] is float or snap["cleared"] is int) or snap["cleared"] < 0:
		return false
	for i in stacks.size():
		var s = snap["stacks"][i]
		if not (s is Array) or s.size() > caps[i]:
			return false
		for o in s:
			if not (o is float or o is int):
				return false
			var t := obj_type(int(o))
			if t >= num_types:
				return false
	if max_moves > 0 and int(snap["moves"]) > max_moves:
		return false
	return true
