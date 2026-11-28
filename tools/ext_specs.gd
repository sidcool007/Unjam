extends RefCounted
## Specs for campaign levels 81-200 (stages 11-16): bigger boards, more mechanics at once, fewer empty trays,
## tight move limits, and a trap filter (max_trap = highest % of random-tap rollouts allowed to win).
## Same generator and same solver proof as tools/level_specs.gd. Ids continue from the base table (80).

const STAGES := [
	{"stage": 11, "name": "Relentless", "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "ice": 2, "lo": 24, "hi": 36, "max_trap": 40},
	{"stage": 12, "name": "Labyrinth", "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lock": 2, "ice": 2, "accepts": 1, "lo": 26, "hi": 40, "max_trap": 35},
	{"stage": 13, "name": "Gauntlet", "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "ice": 2, "accepts": 1, "source_only": 1, "lo": 28, "hi": 42, "max_trap": 35},
	{"stage": 14, "name": "Summit", "counts": [5, 5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5, 5], "empties": 2, "lock": 1, "ice": 1, "lo": 30, "hi": 46, "max_trap": 30, "budget": 400000, "time_limit_s": 240},
	{"stage": 15, "name": "Apex", "counts": [6, 6, 6, 6], "caps": [6, 6, 6, 6, 6, 6], "empties": 2, "lock": 2, "ice": 2, "lo": 28, "hi": 44, "max_trap": 30, "budget": 400000, "time_limit_s": 240},
	{"stage": 16, "name": "Legend", "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 1, "lock": 3, "ice": 2, "accepts": 1, "source_only": 1, "lo": 30, "hi": 46, "max_trap": 30, "budget": 400000, "time_limit_s": 240},
]
const PER_STAGE := 20


static func specs() -> Array:
	var out: Array = []
	for s in STAGES:
		for k in PER_STAGE:
			var d: Dictionary = (s as Dictionary).duplicate(true)
			d["name"] = "%s %d" % [s["name"], k + 1]
			d["ice_min"] = 3
			d["ice_max"] = 8
			d["limit"] = 3
			d["limit_frac"] = 0.2
			if not d.has("budget"):
				d["budget"] = 250000
			if not d.has("time_limit_s"):
				d["time_limit_s"] = 150
			# vary the mix a little inside a stage so levels do not all feel alike
			if k % 4 == 1 and d.has("lock"):
				d["lock"] = maxi(1, int(d["lock"]) - 1)
			if k % 4 == 2 and d.has("ice"):
				d["ice"] = int(d["ice"]) + 1
			if k % 5 == 3:
				d["lo"] = int(d["lo"]) + 2
			out.append(d)
	return out
