extends RefCounted
## Difficulty/mechanic table for the campaign generator.
## counts = objects per type (each must equal some tray's capacity);
## caps = tray capacities; empties = trays that start empty;
## lo/hi = allowed shortest-solution length; limit = spare moves above the
## shortest solution (0 = no move limit); intro = card shown on first play.

const SPECS := [
	# ---- Stage 1: Basics
	{"name": "First Steps", "stage": 1, "counts": [3, 3], "caps": [3, 3, 3, 3], "empties": 2, "lo": 4, "hi": 6,
		"intro": "basics"},
	{"name": "Three Colours", "stage": 1, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 2, "lo": 6, "hi": 9},
	{"name": "Spare Room", "stage": 1, "counts": [3, 3, 3], "caps": [3, 3, 3, 3, 3], "empties": 1, "lo": 8, "hi": 12},
	{"name": "Taller Trays", "stage": 1, "counts": [4, 4, 4], "caps": [4, 4, 4, 4, 4], "empties": 2, "lo": 9, "hi": 13},
]
