# Save format

File: `user://unjam_save.json` (Android: app-private storage). A previous good copy
is kept as `unjam_save.json.bak`; writes go to `.tmp` and are renamed into place.

```json
{
  "version": 1,
  "coins": 85,
  "highest_unlocked": 11,
  "current_level": 11,
  "completed": { "1": 3, "2": 2 },
  "tutorial_done": true,
  "seen_intros": [1, 5],
  "settings": { "sound": true, "music": true, "reduce_motion": false },
  "session": { "level": 11, "state": { "stacks": [[...]], "moves": 3, "cleared": 0 }, "history": [ ...snapshots... ] }
}
```
`completed` maps level id → best stars (1–3). `session` is the in-progress level
(`null` when none) and includes the undo history so Undo survives an app restart.

## Validation on load
* Unparseable / non-object / missing or unknown `version` → rejected (nothing applied).
* Otherwise each field is sanitised: numbers clamped (coins ≥ 0, unlocked 1..N, stars
  1..3), wrong types fall back to defaults, completed ids outside the campaign are
  dropped, completed levels imply the next one is unlocked.
* `session` is only restored if `GameSession.restore_from` accepts it for that level
  (shape, tray sizes, type ranges, move counts); otherwise it is discarded.
* Load order: main file → `.bak` → defaults. `Progress.load_status` is `new`, `ok`,
  `recovered_backup` or `reset_corrupt`; the menu tells the player when a backup was
  used or the save was reset.

## When it is written
On level completion, coin spend, setting change, tutorial completion, after each
valid move (session), restart/undo, and on `APPLICATION_PAUSED` /
`FOCUS_OUT` / close request (flush of pending flags). Never per frame.

## Versioning
`version` is an integer. To change the schema: bump `SAVE_VERSION`, keep reading the
old shape in `apply_dict` (migrate inside the `ver` branch), and add a round-trip test
for the old fixture. A save from a *newer* app than the one reading it is rejected
rather than guessed at.
