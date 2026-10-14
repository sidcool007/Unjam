extends RefCounted
## Difficulty/mechanic table for the campaign generator.
## counts = objects per type (each must equal some tray's capacity);
## caps = tray capacities; empties = trays that start empty;
## lo/hi = allowed shortest-solution length; limit = spare moves above the
## shortest solution (0 = no move limit); intro = card shown on first play.

const SPECS := [
	# ---- Stage 1: Basics
	{"name": "First Steps", "stage": 1, "counts": [3, 3], "caps": [3, 3, 3, 3], "empties": 2, "lo": 4, "hi": 6, "intro": "basics"},
	{"name": "Three Colours", "stage": 1, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 2, "lo": 6, "hi": 9},
	{"name": "Spare Room", "stage": 1, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 1, "lo": 8, "hi": 12},
	{"name": "Taller Trays", "stage": 1, "counts": [4, 4, 4], "caps": [4, 4, 4, 4, 4], "empties": 2, "lo": 9, "hi": 13},
	# ---- Stage 2: Tight trays (mixed capacities)
	{"name": "Mind the Gap", "stage": 2, "counts": [3, 4, 4], "caps": [3, 4, 3, 4, 4], "empties": 1, "lo": 9, "hi": 13, "intro": "capacity"},
	{"name": "Small and Large", "stage": 2, "counts": [3, 4, 4], "caps": [3, 4, 4, 4, 3], "empties": 1, "lo": 10, "hi": 14},
	{"name": "Four Kinds", "stage": 2, "counts": [3, 3, 4, 4], "caps": [3, 3, 4, 4, 4, 3], "empties": 2, "lo": 12, "hi": 16},
	{"name": "Squeeze", "stage": 2, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lo": 14, "hi": 18},
	{"name": "Odd One Out", "stage": 2, "counts": [3, 4, 4, 4], "caps": [3, 4, 4, 4, 4, 4], "empties": 1, "lo": 14, "hi": 19},
	{"name": "Crowded", "stage": 2, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lo": 17, "hi": 23},
	# ---- Stage 3: Buried objects + move limits
	{"name": "Deep Dive", "stage": 3, "counts": [5, 5, 5], "caps": [5, 5, 5, 5, 5], "empties": 2, "lo": 10, "hi": 16, "limit": 5, "intro": "limit"},
	{"name": "Under Pressure", "stage": 3, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lo": 16, "hi": 22, "limit": 4},
	{"name": "Careful Now", "stage": 3, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lo": 18, "hi": 24, "limit": 4},
	{"name": "Last Chance", "stage": 3, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 1, "lo": 20, "hi": 28, "limit": 3},
	# ---- Stage 4: Locks
	{"name": "Padlock", "stage": 4, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 2, "lock": 1, "lo": 6, "hi": 10, "intro": "lock"},
	{"name": "Two Locks", "stage": 4, "counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "lock": 2, "lo": 10, "hi": 14},
	{"name": "Key Order", "stage": 4, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "lo": 14, "hi": 20, "limit": 4},
	{"name": "Triple Lock", "stage": 4, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lock": 3, "lo": 16, "hi": 22, "limit": 3},
	{"name": "Locked In", "stage": 4, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 3, "lo": 20, "hi": 26, "limit": 4},
	{"name": "Vault", "stage": 4, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lock": 3, "lo": 22, "hi": 28, "limit": 3},
	# ---- Stage 5: Restricted trays
	{"name": "Reserved", "stage": 5, "counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "accepts": 1, "lo": 10, "hi": 14, "intro": "accepts"},
	{"name": "Two Reserved", "stage": 5, "counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "accepts": 2, "lo": 12, "hi": 16},
	{"name": "Assigned Seats", "stage": 5, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "accepts": 2, "lo": 14, "hi": 20, "limit": 4},
	{"name": "One Way", "stage": 5, "counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "source_only": 1, "lo": 10, "hi": 16, "intro": "source"},
	{"name": "Drain and Fill", "stage": 5, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "source_only": 1, "accepts": 1, "lo": 16, "hi": 22, "limit": 4},
	{"name": "Traffic Control", "stage": 5, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "accepts": 2, "source_only": 1, "lo": 20, "hi": 28, "limit": 4},
	# ---- Stage 6: Ice
	{"name": "Cold Snap", "stage": 6, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 2, "ice": 2, "ice_min": 2, "ice_max": 4, "lo": 8, "hi": 12, "intro": "ice"},
	{"name": "Slow Thaw", "stage": 6, "counts": [3, 3, 3, 3], "caps": [3, 3, 3, 3, 3, 3], "empties": 2, "ice": 3, "ice_min": 3, "ice_max": 6, "lo": 10, "hi": 16},
	{"name": "Frostbite", "stage": 6, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "ice": 3, "ice_min": 3, "ice_max": 7, "lo": 14, "hi": 20, "limit": 4},
	{"name": "Deep Freeze", "stage": 6, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "ice": 4, "ice_min": 4, "ice_max": 9, "lo": 16, "hi": 22, "limit": 3},
	{"name": "Glacier", "stage": 6, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "ice": 4, "ice_min": 4, "ice_max": 10, "lo": 20, "hi": 26, "limit": 4},
	{"name": "Whiteout", "stage": 6, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "ice": 4, "ice_min": 4, "ice_max": 10, "lo": 22, "hi": 28, "limit": 3},
	# ---- Stage 7: Mastery (mixed mechanics)
	{"name": "Thaw and Unlock", "stage": 7, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "ice": 2, "ice_min": 3, "ice_max": 6, "lo": 16, "hi": 22, "limit": 4, "intro": "mix"},
	{"name": "Triple Threat", "stage": 7, "counts": [4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "ice": 2, "accepts": 1, "ice_min": 3, "ice_max": 6, "lo": 16, "hi": 24, "limit": 4},
	{"name": "Rush Hour", "stage": 7, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 2, "ice": 2, "accepts": 1, "ice_min": 3, "ice_max": 8, "lo": 22, "hi": 30, "limit": 4},
	{"name": "Fortress", "stage": 7, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lock": 2, "ice": 2, "source_only": 1, "ice_min": 3, "ice_max": 8, "lo": 24, "hi": 32, "limit": 4},
	{"name": "Needle's Eye", "stage": 7, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 3, "ice": 3, "ice_min": 3, "ice_max": 8, "lo": 22, "hi": 32, "limit": 4, "budget": 200000},
	{"name": "Grand Puzzle", "stage": 7, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 2, "lock": 3, "ice": 2, "accepts": 1, "ice_min": 3, "ice_max": 8, "lo": 24, "hi": 40, "limit": 5, "budget": 200000},
	{"name": "Crosswinds", "stage": 7, "counts": [4, 4, 4, 4, 4], "caps": [4, 4, 4, 4, 4, 4, 4], "empties": 2, "lock": 3, "ice": 2, "accepts": 1, "source_only": 1, "ice_min": 3, "ice_max": 8, "lo": 24, "hi": 40, "limit": 5, "budget": 200000},
	{"name": "The Last Slot", "stage": 7, "counts": [5, 5, 5, 5], "caps": [5, 5, 5, 5, 5, 5], "empties": 1, "lock": 3, "ice": 3, "ice_min": 3, "ice_max": 8, "lo": 24, "hi": 44, "limit": 4, "budget": 400000, "time_limit_s": 240},
]
