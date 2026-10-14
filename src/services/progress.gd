extends Node
## Autoload "Progress": persistent progress, coin economy, settings, and the
## saved in-progress session. Save format is documented in docs/SAVE_FORMAT.md.

signal coins_changed(balance: int)
signal progress_changed
signal settings_changed

const SAVE_VERSION := 1
const STARTING_COINS := 30
const HINT_COST := 15
const REWARD_BASE := 15
const REWARD_PER_STAR := 5
const MAX_COINS := 1000000

var save_path := "user://unjam_save.json"
var level_count := 40  # set from the campaign by Main

var coins := STARTING_COINS
var highest_unlocked := 1
var current_level := 1
var completed := {}  # level id (int) -> best stars (1..3)
var tutorial_done := false
var seen_intros := {}  # level id (int) -> true
var settings := {"sound": true, "music": true, "reduce_motion": false}
var session: Variant = null  # saved in-progress session dict or null
var load_status := "new"  # new | ok | recovered_backup | reset_corrupt

var _dirty := false


func _ready() -> void:
	load_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		flush()


# ------------------------------------------------------------------ economy

## Stars from moves used vs. par (length of the validated solution).
static func stars_for(moves: int, par: int) -> int:
	if moves <= ceili(par * 1.25):
		return 3
	if moves <= ceili(par * 1.75):
		return 2
	return 1


## Record a level completion. Rewards coins ONLY the first time a level is
## completed (replays update best stars but never pay). Idempotent per level.
## Returns {first_time, coins_awarded, stars, new_best, unlocked_next}.
func complete_level(id: int, moves: int, par: int) -> Dictionary:
	var stars := stars_for(moves, par)
	var first := not completed.has(id)
	var res := {"first_time": first, "coins_awarded": 0, "stars": stars,
		"new_best": false, "unlocked_next": false}
	if id < 1 or id > level_count:
		return res
	if first:
		completed[id] = stars
		res["coins_awarded"] = REWARD_BASE + REWARD_PER_STAR * stars
		coins = mini(coins + int(res["coins_awarded"]), MAX_COINS)
		res["new_best"] = true
	elif stars > int(completed[id]):
		completed[id] = stars
		res["new_best"] = true
	if id + 1 <= level_count and highest_unlocked < id + 1:
		highest_unlocked = id + 1
		res["unlocked_next"] = true
	session = null
	current_level = mini(id + 1, level_count)
	save()
	coins_changed.emit(coins)
	progress_changed.emit()
	return res


func can_afford(amount: int) -> bool:
	return amount > 0 and coins >= amount


## Spends coins; false (and no change) if the balance is insufficient.
func spend_coins(amount: int) -> bool:
	if not can_afford(amount):
		return false
	coins -= amount
	save()
	coins_changed.emit(coins)
	return true


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins = mini(coins + amount, MAX_COINS)
	save()
	coins_changed.emit(coins)


# ------------------------------------------------------------------ progress

func is_unlocked(id: int) -> bool:
	return id >= 1 and id <= highest_unlocked and id <= level_count


func is_completed(id: int) -> bool:
	return completed.has(id)


func stars_of(id: int) -> int:
	return int(completed.get(id, 0))


func total_stars() -> int:
	var n := 0
	for k in completed:
		n += int(completed[k])
	return n


## The level the Play/Continue button should open.
func continue_level() -> int:
	return clampi(current_level, 1, mini(highest_unlocked, level_count))


func set_current_level(id: int) -> void:
	if is_unlocked(id):
		current_level = id
		_dirty = true


func mark_intro_seen(id: int) -> void:
	seen_intros[id] = true
	_dirty = true


func set_tutorial_done() -> void:
	tutorial_done = true
	save()


func set_setting(key: String, value: bool) -> void:
	if settings.has(key):
		settings[key] = value
		save()
		settings_changed.emit()


func save_session(d: Variant) -> void:
	session = d
	save()


func clear_session() -> void:
	if session != null:
		session = null
		save()


func reset_all() -> void:
	_set_defaults()
	save()
	coins_changed.emit(coins)
	progress_changed.emit()
	settings_changed.emit()


# ------------------------------------------------------------------ persistence

func _set_defaults() -> void:
	coins = STARTING_COINS
	highest_unlocked = 1
	current_level = 1
	completed = {}
	tutorial_done = false
	seen_intros = {}
	settings = {"sound": true, "music": true, "reduce_motion": false}
	session = null


func to_dict() -> Dictionary:
	var comp := {}
	for k in completed:
		comp[str(k)] = completed[k]
	var intros := []
	for k in seen_intros:
		intros.append(int(k))
	return {
		"version": SAVE_VERSION,
		"coins": coins,
		"highest_unlocked": highest_unlocked,
		"current_level": current_level,
		"completed": comp,
		"tutorial_done": tutorial_done,
		"seen_intros": intros,
		"settings": settings.duplicate(),
		"session": session,
	}


## Validates & applies untrusted data. Returns false (state unchanged) if it
## is structurally unusable. Individual bad fields fall back to defaults.
func apply_dict(d: Variant) -> bool:
	if not (d is Dictionary):
		return false
	if not (d.get("version") is float or d.get("version") is int):
		return false
	var ver := int(d["version"])
	if ver < 1 or ver > SAVE_VERSION:
		return false  # unknown/future format: never guess
	_set_defaults()
	var c = d.get("coins")
	if c is float or c is int:
		coins = clampi(int(c), 0, MAX_COINS)
	var comp = d.get("completed")
	if comp is Dictionary:
		for k in comp:
			var id := int(str(k)) if str(k).is_valid_int() else -1
			var st = comp[k]
			if id >= 1 and id <= level_count and (st is float or st is int):
				completed[id] = clampi(int(st), 1, 3)
	var hu = d.get("highest_unlocked")
	if hu is float or hu is int:
		highest_unlocked = clampi(int(hu), 1, level_count)
	for id in completed:  # completed levels imply their successor is unlocked
		highest_unlocked = maxi(highest_unlocked, mini(int(id) + 1, level_count))
	var cl = d.get("current_level")
	if cl is float or cl is int:
		current_level = clampi(int(cl), 1, highest_unlocked)
	tutorial_done = d.get("tutorial_done") is bool and d["tutorial_done"]
	var si = d.get("seen_intros")
	if si is Array:
		for x in si:
			if x is float or x is int:
				seen_intros[int(x)] = true
	var st = d.get("settings")
	if st is Dictionary:
		for k in settings.keys():
			if st.get(k) is bool:
				settings[k] = st[k]
	if d.get("session") is Dictionary:
		session = d["session"]  # structurally verified by GameSession.restore_from
	return true


func save() -> bool:
	_dirty = false
	var text := JSON.stringify(to_dict())
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Progress: cannot write save (%d)" % FileAccess.get_open_error())
		return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	return DirAccess.rename_absolute(tmp, save_path) == OK


func flush() -> void:
	if _dirty:
		save()


func load_data() -> void:
	for candidate in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var f := FileAccess.open(candidate, FileAccess.READ)
		if f == null:
			continue
		var json := JSON.new()
		var parsed = json.data if json.parse(f.get_as_text()) == OK else null
		if apply_dict(parsed):
			load_status = "ok" if candidate == save_path else "recovered_backup"
			return
	_set_defaults()
	load_status = "reset_corrupt" if FileAccess.file_exists(save_path) else "new"
