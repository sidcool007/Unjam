extends RefCounted
## Spec table for the daily-puzzle pool (levels/daily.json). 112 specs = 16 weeks x 7 weekdays;
## index % 7 is the weekday (0 = Monday, easiest ... 6 = Sunday, hardest). Same format and
## generator as tools/level_specs.gd; every puzzle is proven solvable by the real rules engine.

const WEEKS := 16

# One template per weekday. Seeds differ per spec so every puzzle is a distinct layout.
const TIERS := [
	{"counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "lo": 7, "hi": 13},
	{"counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lo": 11, "hi": 18},
	{"counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lo": 14, "hi": 22},
	{"counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lock": 1, "lo": 13, "hi": 21},
	{"counts": [3, 3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3, 3], "empties": 2, "ice": 2, "ice_min": 3, "ice_max": 7, "limit": 3, "lo": 12, "hi": 20},
	{"counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lock": 1, "ice": 1, "ice_min": 3, "ice_max": 8, "lo": 18, "hi": 27},
	{"counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 1, "ice": 2, "ice_min": 3, "ice_max": 8, "limit": 3, "lo": 20, "hi": 29},
]

static func specs() -> Array:
	var out: Array = []
	for w in WEEKS:
		for d in 7:
			var s: Dictionary = (TIERS[d] as Dictionary).duplicate(true)
			s["name"] = "Daily"
			s["stage"] = 1
			s["seed0"] = 900000 + (w * 7 + d) * 1000
			s["budget"] = 250000
			s["time_limit_s"] = 120
			out.append(s)
	return out
