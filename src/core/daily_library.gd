class_name DailyLibrary
extends RefCounted
## Daily puzzle: a shipped pool of pre-verified levels (res://levels/daily.json), picked by local date.
## Nothing is generated at runtime. The pool is ordered so that index % 7 is the weekday
## (0 = Monday, easiest ... 6 = Sunday, hardest); pool size is a multiple of 7.

const POOL_PATH := "res://levels/daily.json"
const EPOCH_Y := 1970

static var _pool: Array = []
static var _loaded := false


static func load_pool(path: String = POOL_PATH) -> bool:
	_pool = []
	_loaded = true
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary) or not (data.get("levels") is Array):
		return false
	for lv in data["levels"]:
		if lv is Dictionary:
			_pool.append(lv)
	return not _pool.is_empty()


static func pool() -> Array:
	if not _loaded:
		load_pool()
	return _pool


static func available() -> bool:
	return pool().size() >= 7


static func today_key() -> String:
	var d := Time.get_datetime_dict_from_system(false)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


## Whole days since 1970-01-01 for a "YYYY-MM-DD" key (-1 if malformed).
static func day_number(key: String) -> int:
	var parts := key.split("-")
	if parts.size() != 3 or not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()):
		return -1
	var t := Time.get_unix_time_from_datetime_dict({"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 0, "minute": 0, "second": 0})
	return int(floor(float(t) / 86400.0))


static func key_for_day(day: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(day * 86400)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


## 0 = Monday ... 6 = Sunday (1970-01-01 was a Thursday).
static func weekday(day: int) -> int:
	return posmod(day + 3, 7)


static func index_for_day(day: int) -> int:
	var n := pool().size()
	if n == 0:
		return -1
	var week := int(floor(float(day + 3) / 7.0))
	return posmod(week * 7 + weekday(day), n)


## Level dictionary for a date key, or {} if the pool is unavailable.
static func level_for(key: String) -> Dictionary:
	var day := day_number(key)
	var i := index_for_day(day) if day >= 0 else -1
	if i < 0:
		return {}
	return pool()[i]


static func par_of(lv: Dictionary) -> int:
	return (lv["solution"] as Array).size()
