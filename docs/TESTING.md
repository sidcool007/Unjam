# Testing

## Automated (all run headless, no device needed)

```bash
godot --headless --path . --script res://tests/test_runner.gd     # exit code 1 on failure
godot --headless --path . --script res://tools/validate_levels.gd # exhaustive level proof
```
`tests/test_runner.gd` discovers `tests/test_*.gd`; each `test_*` method may `await`
frames. UI tests drive the real `GameScreen` with taps.

### Latest results (Godot 4.7.1.stable, 2026-10-16; also green on 4.6 and 4.3)
* **91 tests, 91 passed, 0 failed** (exit code 0)
  * `test_board_rules` (14): legal/illegal moves, match rule, full trays, clear rule,
    reserved & one-way trays, locks (unlock on clear), ice (thaw by move count), move
    limit failure, deadlock failure, exact undo, undo after failure, restart, clone independence.
  * `test_progress` (15): defaults, reward exactly once, replay pays nothing but can
    raise stars, unlock chain, bad level ids, coin spending never negative, save/load
    round trip, corrupted file, backup recovery, field sanitising, version rejection,
    completed⇒unlocked, **suspend flush + resume restore of an in-progress session**,
    rejection of mismatched session data, no re-fired win/fail signals on restore.
  * `test_hints` (4) + `test_hints_campaign` (1): hints are always legal, following hints wins,
    dead ends are detected without charging, no hint after finishing; hint-following wins
    **all 40 levels** (worst first-hint time ≈70–80 ms on desktop).
  * `test_campaign` (12): ≥30 levels, every level validates and its solution replays, no
    duplicates/near-duplicates, move limits feasible, mechanics debut one at a time with an
    intro card, difficulty ramp, ids/stages ordered, level 1 trivial, recorded solutions of
    levels 1–10 optimal, validator rejects bad levels.
  * `test_ui_flow` (5): **repeated taps/undo during an animation change nothing**, full play-through
    pays the reward once (extra win callbacks pay nothing), bad tray index harmless,
    hint charging rules (never overspends), restart asks for confirmation only with progress.
  * `test_fuzz` (4): 31 200 random taps/moves/undos/restarts over all 40 levels with invariants after every
    action (capacity, object conservation, status vs model, exact undo, restart, legal-move enumeration
    vs `check_move`, blocked objects never pickable); win on the final allowed move; undo across clears/locks/ice.
  * `test_ui_fuzz` (4): random taps (also hammering during animations), undo, restart, hint and pause on 7
    levels; after every idle point the view must mirror the model exactly (objects, positions, highlights, dialogs).
  * `test_layout` (9): safe-area/cutout arithmetic, responsive column, splash centred, dialogs fit, rule tags never collide with the tray above, board + action buttons + trays fit on 5:3, 16:9, 20:9 and 21:9 windows with ≥96 px buttons and no overlapping trays (SIMULATED geometry, not a device).
  * `test_contrast` (4): WCAG ratios of the real design tokens (text ≥ 4.5:1, coral graphics ≥ 3:1, tray outline ≥ 2.5:1, every object rim ≥ 2.0:1 on the tray).
  * `test_release_config` (4): identity/version consistent across presets and project, 0 permissions, no credentials in tracked config, AAB preset sane.
  * `test_campaign` also checks that each intro card's promised mechanic really exists on the level that shows it (+2 tests).
  * `test_ui_flow` also covers: reward animation ends on the exact values, Reduce motion shows them at once, Restart is not adjacent to Hint, intro cards show once and never again, double-pressed dialog buttons run once.
  * `test_progress` also covers all three settings persisting across a restart.
  * `test_services` (4): ad gate grants at most once, never without a request, never faked;
    audio safe with unknown/disabled sounds.
* **Level validator:** 40 levels, **0 errors, 0 warnings**; exhaustive BFS proved every
  recorded solution is the shortest (see `validation_report.txt`).
* **Runtime log** of a 400-frame launch under Xvfb: no script errors or warnings other than
  the sandbox having no audio device / vsync.
* Screens (menu, levels, gameplay on several levels, hint, win, fail, pause, settings,
  intro) were rendered under Xvfb at 720×1280 and inspected visually.

## What was NOT tested
* No physical device or Android emulator was available (the SDK/system images could not be
  downloaded in this environment). The debug APK builds, signs and its manifest was
  inspected (portrait, zero permissions), but it has **never been launched**.
* Audio was synthesised and checked only for build/play calls — nobody has listened to it.
* Real touch input, haptics-free feedback, display cutouts/safe-area insets, back button,
  suspend/resume on a real OS and low-end performance are untested on hardware.
* Human playtesting of difficulty (the ramp is verified by solver metrics only).

## Device testing
See **`docs/DEVICE_TEST_PLAN.md`** (full matrix, adb commands, results table — every row currently NOT RUN) and
**`docs/PLAYTEST_PLAN.md`** (human playtest, levels 1–10, not run).

## Manual device test procedure (short form)
1. `adb install -r build/unjam-debug.apk`; launch *Unjam*. Confirm portrait lock (rotate device).
2. Airplane mode ON; play level 1 with the tutorial coach; confirm win dialog, +30 coins.
3. Tap rapidly during a move: no double moves, undo disabled while animating.
4. Settings (pause menu): sound/music/reduce-motion toggles work immediately.
5. Mid-level, press Home, swipe the app away, relaunch: *Continue* resumes the same board, move count and Undo history.
6. Complete levels 1–4 and verify the next level unlocks; locked tiles show a padlock and a toast.
7. Level 15 (padlock) and 27 (ice): read the intro cards; verify lock opens on clearing the named shape, ice counts down.
8. Hint with <15 coins → "Not enough coins", no charge; with coins → highlights source and destination, coins −15.
9. Back button: closes dialogs, game → pause menu, level select → menu, menu → exits.
10. Check a notched/cutout device: top bar and bottom buttons not obscured.
11. `adb logcat -s godot` for errors during the above.
