# Architecture

```
src/core/      rules + data, no UI, no autoloads (fully unit-testable)
  board_state.gd     BoardState   authoritative model; the ONLY rule implementation
  game_session.gd    GameSession  undo history, restart, PLAYING/WON/FAILED, (de)serialisation
  solver.gd          Solver       BFS (optimal) + weighted best-first search over BoardState
  hint_service.gd    HintService  hint = search from the *current* position; validated authored path as fallback
  level_validator.gd LevelValidator  structural checks, replay of recorded solution, exhaustive proof, duplicate detection
  level_library.gd   (autoload Levels) loads levels/campaign.json
  campaign_text.gd   player-facing rule text / intro cards
src/services/  (autoloads except the provider interface)
  progress.gd        (Progress) saves, unlocks, coins, settings, saved session
  audio.gd           (Audio) procedurally synthesised SFX + loop
  ad_service.gd      (Ads) gate in front of an optional RewardedAdProvider
  rewarded_ad_provider.gd  interface for a future ad SDK (no provider ships)
src/ui/        screens built in code: main (host), splash, menu, level select,
               game (HUD + flows), credits; components: board/tray/object views,
               modal, icon button, toggle row, settings panel, vector icons/shapes
levels/campaign.json   40 levels (data only)
tools/         level generator, validator CLI, icon rasteriser (dev only)
tests/         headless test runner + test files
```

## Key decisions

* **One source of truth.** `BoardState` holds all game state and rules. `BoardView`
  mirrors it and is rebuilt from it whenever it might drift (undo, restart, restore).
  The model is updated *immediately* on a valid tap; the animation only catches the
  view up. While animating, `BoardView.busy` locks input (taps, undo, hint, restart).
* **Objects are packed ints** (type | lock | thaw) so states are cheap to copy and
  hash for search. Trays with identical configuration are interchangeable in the
  search key (symmetry reduction).
* **Locks/ice are derived**: a lock opens when its key type is in `cleared_mask`; ice
  thaws when `moves >= thaw`. Because both derive from state already in snapshots,
  undo restores them exactly with no extra bookkeeping.
* **Rewards are idempotent** in two layers: the screen processes a win once, and
  `Progress.complete_level` pays only when the level is not yet in `completed`.
* **Hints reuse the rules.** A hint is the first move of a real solution found from
  the player's current board, re-validated by `check_move` before it is shown and
  before coins are charged. Dead ends (exhausted search) are reported honestly and free.
* **Monetisation is isolated.** `RewardedAdProvider` is an interface only; nothing
  in gameplay references a network SDK. With no provider, `Ads.request()` returns
  false and the UI offers no ad.
* **UI in code, one scene.** `scenes/main.tscn` hosts `main.gd`; screens are scripts.
  This keeps the project diff-friendly and avoids scene/script drift.
* Autoloads: `Progress`, `Audio`, `Levels`, `Ads` (all used as read-mostly services).

## Gotchas learned
* Packed arrays stored inside an `Array` alias on assignment in Godot 4.3; `clone()`
  copies explicitly (regression test `test_clone_is_independent`).
* `Control.set_anchors_preset` alone does not size a control created in code; use
  `set_anchors_and_offsets_preset`.
