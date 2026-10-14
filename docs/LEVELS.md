# Levels

## Format (`levels/campaign.json`)

```json
{ "format": 1, "levels": [ {
  "id": 15, "name": "Padlock", "stage": 4, "intro": "lock",
  "types": 3, "max_moves": 14,
  "trays": [
    {"cap": 3, "items": [0, {"t": 1, "lock": 0}, 2]},
    {"cap": 3, "items": [], "accepts": 1},
    {"cap": 3, "items": [1], "source_only": true}
  ],
  "solution": [[0, 3], [1, 2]],
  "par": 8, "seed": 15001
} ] }
```

* `items` are listed **bottom → top**. A plain integer is an object type;
  `{"t":type, "lock":keyType, "ice":thawAtMove}` adds a padlock and/or ice.
* `accepts` (reserved tray) and `source_only` (one-way tray) are optional.
* `max_moves` is optional (omit/0 = no limit).
* `solution` is a recorded winning move list `[from, to]`; it is replayed by the
  validator and used as a hint fallback. `par` = its length (proven shortest).
* `intro` names a card in `CampaignText.INTROS` shown the first time the level opens.
* Each type's object count must equal the capacity of some tray that can clear it
  (a tray clears when full and uniform).

## Authoring
Levels are **generated once at development time, then frozen** as data:

1. Edit `tools/level_specs.gd` (type counts, tray capacities, empties, mechanics,
   allowed shortest-solution band, move-limit slack).
2. `godot --headless --path . --script res://tools/generate_levels.gd [-- first last]`
   tries seeded random layouts until BFS proves the layout solvable with a shortest
   solution inside the band; it records that solution. Output is written
   incrementally. Move limit = par + max(slack, 45 % of par).
3. `godot --headless --path . --script res://tools/validate_levels.gd` must report
   0 errors. Hand-authored levels use the same file format.

Nothing is random at play time, so there is no unfair board generation.

## Validator checks
Missing fields; type/capacity ranges; object over capacity; type with no objects or
no tray able to clear it; lock key referring to a missing type or to the object's own
type; starting full-and-uniform trays; already-solved or no-legal-move starts;
recorded solution replays to a win and fits `max_moves`; exhaustive BFS finds a
solution (or proves none exists) and the recorded one is not wildly longer; duplicate
ids / identical layouts (canonical key) / ≥85 % similar neighbouring levels; mechanic
debut order and difficulty ramp (in `tests/test_campaign.gd`).

## Curve
Stage 1 Basics (1–4) · 2 Tight trays (5–10) · 3 Move limits (11–14) · 4 Locks (15–20)
· 5 Reserved/one-way trays (21–26) · 6 Ice (27–32) · 7 Mastery (33–40). Every
mechanic debuts on its own level with an intro card; see `docs/validation_report.txt`.
