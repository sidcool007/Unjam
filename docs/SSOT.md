# UNJAM: THE LAST SLOT — Single Source of Truth (SSOT)

> **Purpose.** One place that states what the game *is*, what is *verified*, what is *not*, and
> where each fact lives. If another document disagrees with this one, **the code and tests win
> over this file, and this file wins over every other document** — then fix the other document.
>
> **Last verified:** 2026-10-16 · branch `claude/compassionate-goldberg-7e0tm0` · Godot 4.6.stable ·
> version 0.1.0 (code 1). Re-verify with the commands in §4 and update §1/§9 whenever they change.

---

## 1. Current state at a glance

| Item | State |
|------|-------|
| Overall | **Release candidate, desktop-verified. Not device-verified. Not release-signed.** |
| Gameplay | Complete: 40 levels, 7 mechanic stages, tutorial, undo/restart/hints/coins/save |
| Automated tests | **67 / 67 pass** (rules, 31 200-action fuzz, UI fuzz, progress/save, hints, campaign, ad gate) |
| Level validator | **40 levels, 0 errors, 0 warnings**; every recorded solution proven shortest by exhaustive search |
| Debug APK | Builds & signs (`build/unjam-debug.apk`, ≈55 MB, arm64-v8a + x86_64, min SDK 24, **target SDK 35**, portrait, **0 permissions**). Not committed (git-ignored). |
| Real device / emulator run | **Never done** (no Android system images obtainable in the build environment) |
| Release AAB | **Not built** (no full Android SDK, no release keystore — deliberately none created) |
| Store readiness | **Not ready** — see §8 blockers |

## 2. Identity and constraints (from the brief — fixed)

* Name: *Unjam: The Last Slot* · Engine **Godot 4.x, GDScript** · Android, **portrait**, 2D (GL Compatibility).
* Touch-first, mouse works on desktop. Local storage only. **No** paid engine/plugins/assets, accounts,
  backend, remote API, AI calls, or network dependency; plays in airplane mode. No live ads / IAP.
* Original identity, levels and art: all shapes/icons are drawn in code, all audio is synthesised in code.
* Application id: `com.unjam.thelastslot` (**placeholder** — replace before publishing).

## 3. Repository map (what owns what)

| Path | Owns |
|------|------|
| `src/core/board_state.gd` | **The only implementation of the rules** (`BoardState`) |
| `src/core/game_session.gd` | Undo history, restart, PLAYING/WON/FAILED, session (de)serialisation |
| `src/core/solver.gd`, `hint_service.gd` | BFS (optimal) + weighted best-first search; hints from the live position |
| `src/core/level_validator.gd`, `level_library.gd`, `campaign_text.gd` | Level checks · loader (autoload `Levels`) · player-facing rule text |
| `src/services/progress.gd` | Autoload `Progress`: save, unlocks, coins, settings, saved session |
| `src/services/audio.gd` | Autoload `Audio`: synthesised SFX + music loop |
| `src/services/ad_service.gd`, `rewarded_ad_provider.gd` | Autoload `Ads` gate + provider interface (no provider ships) |
| `src/ui/*` | Screens (built in code) and components; `scenes/main.tscn` is the only scene |
| `levels/campaign.json` | **The level data** (40 levels) |
| `tools/` | `generate_levels.gd`, `level_specs.gd`, `validate_levels.gd`, `make_icons.gd` (dev only) |
| `tests/` | Headless test runner + `test_*.gd` |
| `export_presets.cfg` | "Android Debug" and "Android Release (AAB)" presets |
| `docs/` | Detail docs (index in §10) |

## 4. How to verify (reproducible commands)

```bash
godot --headless --path . --import                                   # once / after file changes
godot --headless --path . --script res://tests/test_runner.gd        # expect: 67 tests, 67 passed
godot --headless --path . --script res://tools/validate_levels.gd    # expect: 40 levels, 0 errors, 0 warnings
godot --headless --path . --export-debug "Android Debug" build/unjam-debug.apk
aapt dump badging build/unjam-debug.apk | grep -E "targetSdk|uses-permission"   # expect target 35, no permissions
```
Toolchain used: Godot 4.6-stable + 4.6 export templates; JDK 21; `apksigner`/`zipalign`/`adb`/`aapt` from
Ubuntu packages in a minimal SDK folder (see `docs/ANDROID.md`). Also green on Godot 4.3.

## 5. Canonical game facts (constants — must equal the code)

Rules are specified in full in [`RULES.md`](RULES.md). Key facts duplicated here for lookup only:

* **Move:** one object per move, from the **top** of a tray; destination must be non-full, not `source_only`,
  satisfy `accepts` (if set), and be empty **or** have a top of the **same type**. Top object must not be
  **locked** (key type not yet cleared) or **frozen** (`moves < thaw`).
* **Clear:** a tray that becomes **full and single-typed** empties and marks that type cleared (opens its locks).
* **Win:** all trays empty. **Fail:** not won and (`moves ≥ max_moves` **or** no legal move). Undo recovers from fail.
* **Undo:** exact snapshot restore (stacks, move count, cleared set); history up to 400 moves. **Restart:** initial
  snapshot; UI confirms when `moves > 0`.
* **Economy** (`src/services/progress.gd`): start **30** coins · hint **15** · first completion pays
  **15 + 5 × stars** · replays pay **0** · stars: ≤ 125 % of par → 3, ≤ 175 % → 2, else 1 (par = shortest solution).
* **Levels:** 40; stages 1 Basics (1–4), 2 Tight trays (5–10), 3 Move limits (11–14), 4 Locks (15–20),
  5 Reserved/one-way trays (21–26), 6 Ice (27–32), 7 Mastery (33–40). Move limit = par + max(spec slack, 45 % of par).
* **Save:** `user://unjam_save.json` (+ `.bak`), `version: 1` — [`SAVE_FORMAT.md`](SAVE_FORMAT.md).
* **UI:** logical viewport 720×1280, stretch `canvas_items`, aspect `expand`; minimum touch target 96 logical px
  (= 48 dp on a 360 dp phone); Android back button handled (dialog → pause → previous screen → exit).

## 6. Requirement traceability (brief sections 1–19)

Legend: ✅ done & verified on desktop · 🟡 done, verification limited · ❌ not done.

| § | Requirement | Status | Evidence / note |
|---|-------------|:--:|----------------|
| 2 | Inspect environment first; preserve existing work | ✅ | Repo was empty; toolchain verified and documented (`ANDROID.md`) |
| 3 | Godot 4 / GDScript / Android portrait / local save / JSON levels / no paid or network deps | ✅ | `project.godot`; manifest has 0 permissions |
| 3 | Monetisation modular, no live ads/IAP | ✅ | `RewardedAdProvider` interface only; `test_services` |
| 4–5.1 | Board of trays/objects, distinct shapes+colours, blocked objects not movable | ✅ | `BoardState`, `Shapes`; fuzz proves blocked objects never pickable |
| 5.2 | One canonical move rule, documented before content | ✅ | `RULES.md`; single implementation; legal-move enumeration = `check_move` (fuzz) |
| 5.3 | Move limits, failure state, restart (+confirm), exact undo, victory, input lock during animation | ✅ | `test_board_rules`, `test_fuzz`, `test_ui_flow`, `test_ui_fuzz` |
| 5.4 | Mechanics introduced gradually, each in a safe level first | ✅ | `test_campaign` (debut order + intro card on each debut level) |
| 6 | Data-driven levels, persistent progress, replayable, locked levels distinct, level select, number/moves shown | ✅ | `campaign.json`, `LevelSelectScreen`, HUD |
| 6 | **30–50 levels, every one with a verified solution** | ✅ | 40 levels; exhaustive BFS proof per level (`validation_report.txt`) |
| 6 | Validator: counts, impossible states, capacity, reachability, duplicates, diagnostics | ✅ | `level_validator.gd`, `validate_levels.gd`, `test_campaign` (incl. negative cases) |
| 7 | Coins, hints cost, no negative balance, rewards exactly once | ✅ | `test_progress`, `test_ui_flow` (double win callback pays once) |
| 8 | Hint = legal next move, no charge when none, explanation, deterministic fallback | ✅ | `HintService`; hint-following wins all 40 levels (≈80 ms worst, desktop) |
| 9 | Premium original UI; all 10 required screens | ✅ | Splash, menu, level select, tutorial (coach + intro cards), gameplay, pause/settings, complete, failed, hint/recovery dialog, privacy+credits — screenshots inspected |
| 9 | HUD: level, moves/remaining, coins, undo, hint, restart, pause; menu progress indicator | ✅ | `GameScreen`, `MenuScreen` |
| 9 | Responsive portrait, ≥48 dp targets, readable text, non-colour cues, reduce-motion | 🟡 | Rendered at 720×1280 and 720×1600; touch size fixed to 48 dp this session; **safe-area/cutout logic untested on a device**; no TalkBack |
| 10 | Feedback: select, move, invalid, tray clear, win, fail, coin, button; sound+music toggles; works without audio | 🟡 | All present & toggleable; coin reward has a sound and text but **no animated coin counter**; **audio never listened to**; haptics none |
| 11 | Save: unlocks, completed, current level, coins, settings, tutorial, active session; validated; corrupt-safe; save at transitions | ✅ | `test_progress` (round trip, corruption, backup, sanitising, suspend flush, session restore) |
| 12 | Ad architecture, no ads shipped, no double rewards, no fake rewards | ✅ | `test_services` |
| 13 | Modular architecture, single state model, signals, no duplicated rules | ✅ | `ARCHITECTURE.md` |
| 14 | Unit/logic/level tests listed in brief | ✅ | 67 tests incl. suspend/resume, repeated taps during animation |
| 14 | Tutorial text accurately describes actual rules | 🟡 | Texts reviewed by hand against `RULES.md`; only existence is automated |
| 14 | **Android: run on device/emulator, test touch/audio/persistence/navigation, inspect logs** | ❌ | Impossible in this environment; manual plan in `TESTING.md` |
| 15 | Lightweight, no needless permissions, no input duplication | 🟡 | Manifest: 0 permissions; duplicate input guarded & tested; **no on-device perf measurement** |
| 16 | Documentation set | ✅ | §10 |
| 17 | Phases 1–5 | ✅ | §7 |
| 17 | Phase 6: app id, version, icon, orientation, export; debug APK; AAB only if possible | 🟡 | Debug APK ✅; AAB ❌ (no SDK/keystore); app id placeholder |
| 17 | Phase 7: honest handover | ✅ | This document + README + `KNOWN_ISSUES.md` |
| 18 | Working rules (no placeholder buttons, no hidden failures, progress log) | ✅ | `PROGRESS.md`; no stubbed UI |
| 19 | Definition of done items 1–10 | 🟡 | Items 1–8 ✅; **9 (debug build *generated and tested*) — generated yes, tested no**; 10 ✅ (blockers documented) |

## 7. Phase status

| Phase | Status | Notes |
|------:|:------:|-------|
| 1 Playable prototype | ✅ | Level 1 with final rules. A critical re-review (Phase-1 review) later found and fixed 6 UI defects (§9) |
| 2 Foundation | ✅ | Engine, level format, save, hints, solver, tests |
| 3 Campaign | ✅ | 40 verified levels; generator is a dev tool, results frozen as data |
| 4 Visual polish | ✅ (desktop) | All screens, animations, synthesised audio, settings |
| 5 Full QA | ✅ (desktop) | Everything runnable here has been run; device QA impossible here |
| 6 Android prep | 🟡 | Debug APK only |
| 7 Handover | 🟡 | Written; cannot claim device testing |

## 8. Release blockers and open items (authoritative list)

1. **Run on real hardware** (≥2 devices incl. a cutout device and a low-end one) using the plan in `TESTING.md`; fix what it finds.
2. **Build a release AAB**: gradle build template + full Android SDK + *your own* release keystore (never committed).
3. **Replace the placeholder application id**; bump version fields in both presets and `project.godot` together.
4. **Re-check Google Play's target-API floor** on the submission date (APK targets 35 today).
5. **Human checks:** listen to audio levels; playtest levels 1–10 with new players; confirm move-limit slack (45 %) feels fair.
6. **Store paperwork:** privacy policy URL, Data Safety form (collects nothing), screenshots, rating questionnaire.
7. Minor/accepted gaps: no animated coin counter, no haptics, no TalkBack support, dead-end positions are only
   reported via Hint (free), tablets/landscape untested.
8. Before any ad SDK: verify current SDK compatibility, consent (UMP), test-ad rules, disclosures, Play policy.

## 9. Verification history (evidence)

| Date | Event | Result |
|------|-------|--------|
| 2026-10-14 | Campaign generated; validator | 40 levels, 0 errors; shortest-solution proof for all |
| 2026-10-14 | Debug APK on Godot 4.3 / later 4.6 | Signed; 0 permissions; target 34 → **35** |
| 2026-10-15 | Core-gameplay review: random-action fuzz + UI fuzz + visual walk-through | 31 200 rules actions clean; **6 UI defects fixed** (tween drift off-slot, dialog double-fire, restored FAILED session without dialog, stale highlights, stale layout after resize, fixed-pixel toasts) |
| 2026-10-16 | Full re-run; touch targets raised 88→96 px | 67/67 tests; 40/40 levels; APK target 35, no permissions |

Known historical bug to keep in mind: packed arrays stored inside an `Array` alias on assignment in Godot —
`BoardState.clone()` copies explicitly (`test_clone_is_independent`).

## 10. Document index — which file owns which truth

| Topic | Owner |
|-------|-------|
| Overall status, requirement traceability, blockers | **this file** |
| Rules / movement / economy details | [`RULES.md`](RULES.md) |
| Module design and decisions | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Level format, authoring, validator | [`LEVELS.md`](LEVELS.md) · data: `levels/campaign.json` · proof: [`validation_report.txt`](validation_report.txt) |
| Save schema, versioning, recovery | [`SAVE_FORMAT.md`](SAVE_FORMAT.md) |
| Tests, results, manual device plan | [`TESTING.md`](TESTING.md) |
| Export / toolchain | [`ANDROID.md`](ANDROID.md) |
| Licences / dependencies | [`ASSETS_AND_LICENSES.md`](ASSETS_AND_LICENSES.md) |
| Limitations | [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) |
| Pre-publication steps | [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) |
| Chronological log | [`../PROGRESS.md`](../PROGRESS.md) |

## 11. Maintenance rules for this document

* Change §1, §6–§9 in the **same commit** as any change that alters them (tests count, level count, constants,
  blockers, versions). Numbers here must be reproducible with §4.
* Never mark an item ✅ unless a test, validator run, or inspected artifact proves it; use 🟡/❌ and say why.
* Constants in §5 must match the code; when they diverge, fix this file (or the code) immediately.
