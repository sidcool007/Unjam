# UNJAM: THE LAST SLOT — Single Source of Truth (SSOT)

> **Purpose.** One place that states what the game *is*, what is *verified*, what is *not*, and
> where each fact lives. If another document disagrees with this one, **the code and tests win
> over this file, and this file wins over every other document** — then fix the other document.
>
> **Last verified:** 2026-10-16 · branch `claude/compassionate-goldberg-7e0tm0` · Godot **4.7.1.stable** ·
> version 0.1.0 (code 1) · APK **target SDK 36**. Re-verify with the commands in §4 and update §1/§9 whenever they change.

---

## 1. Current state at a glance

| Item | State |
|------|-------|
| Overall | **Release candidate, desktop-verified, API-36 build. Not device-verified. Not release-signed.** |
| Gameplay | Complete: 40 levels, 7 mechanic stages, tutorial, undo/restart/hints/coins/save |
| Automated tests | **80 / 80 pass** (exit 0): rules, 31 200-action fuzz, UI fuzz, save/economy, hints, campaign, layout/safe-area maths, release-config guard, ad gate |
| Level validator | **40 levels, 0 errors, 0 warnings** (exit 0); every recorded solution proven shortest by exhaustive search |
| Debug APK | `build/unjam-debug.apk` (57 133 192 B, git-ignored): **targetSdkVersion 36**, compileSdk 36, min SDK 24, arm64-v8a + x86_64, portrait, **0 permissions**, v2+v3 signature OK (debug key). |
| Google Play target-API rule | Official page (read 2026-10-16): new apps/updates from 31 Aug 2026 must target **API 36**. **Met by the APK** (was *not* met at target 35 — fixed by Godot 4.6 → 4.7.1). |
| Real device / emulator run | **Never done** — none available (`adb devices` empty, no KVM) → `docs/DEVICE_TEST_PLAN.md`, all NOT RUN |
| Release AAB | **BLOCKED**: (1) no release/upload keystore (owner), (2) `dl.google.com` denied by egress policy → Android Gradle Plugin / SDK platform 36 unobtainable here |
| Play listing assets | Icon 512, feature graphic, 6 screenshots in `store/` (rendered by the game on desktop GL, not device captures) |
| Compliance drafts | Privacy policy + Play Console prep drafted (`store/`), **nothing submitted**, owner fields/decisions open |
| Store readiness | **Not ready** — see §8 |

## 2. Identity and constraints (from the brief — fixed)

* Name: *Unjam: The Last Slot* · Engine **Godot 4.x, GDScript** · Android, **portrait**, 2D (GL Compatibility).
* Touch-first, mouse works on desktop. Local storage only. **No** paid engine/plugins/assets, accounts,
  backend, remote API, AI calls, or network dependency; plays in airplane mode. No live ads / IAP.
* Original identity, levels and art: all shapes/icons are drawn in code, all audio is synthesised in code.
* Application id: `com.unjam.thelastslot` (**placeholder** — owner must approve a final id before first upload; proposals in `store/PLAY_CONSOLE_PREP.md`).

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
| `src/ui/*` | Screens (built in code) and components (incl. `column_margin.gd`: responsive column + safe area); `scenes/main.tscn` is the only scene |
| `levels/campaign.json` | **The level data** (40 levels) |
| `tools/` | `generate_levels.gd`, `level_specs.gd`, `validate_levels.gd`, `make_icons.gd`, `make_store_assets.gd` (dev only) |
| `store/` | Play listing assets + `PRIVACY_POLICY.md` (draft) + `PLAY_CONSOLE_PREP.md`; `.gdignore`d, never shipped in the APK |
| `tests/` | Headless test runner + `test_*.gd` |
| `export_presets.cfg` | "Android Debug" and "Android Release (AAB)" presets |
| `SSOT.md` (this file) | Single source of truth |
| `docs/` | Detail docs (index in §10) |

## 4. How to verify (reproducible commands)

```bash
godot --headless --path . --import                                   # once / after file changes
godot --headless --path . --script res://tests/test_runner.gd        # expect: 80 tests, 80 passed; exit 0
godot --headless --path . --script res://tools/validate_levels.gd    # expect: 40 levels, 0 errors, 0 warnings; exit 0
godot --headless --path . --export-debug "Android Debug" build/unjam-debug.apk
aapt dump badging build/unjam-debug.apk | grep -E "targetSdk|uses-permission"   # expect target 36, no permissions
apksigner verify --verbose build/unjam-debug.apk
```
Toolchain: Godot **4.7.1-stable** + 4.7.1 export templates; JDK 21; `apksigner`/`zipalign`/`adb`/`aapt` from Ubuntu packages in a
minimal SDK folder (`docs/ANDROID.md`). Also green on Godot 4.6 and 4.3 (but their templates target API 35/34 — don't release with them).

## 5. Canonical game facts (constants — must equal the code)

Rules are specified in full in [`docs/RULES.md`](docs/RULES.md). Key facts duplicated here for lookup only:

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
* **Save:** `user://unjam_save.json` (+ `.bak`), `version: 1` — [`SAVE_FORMAT.md`](docs/SAVE_FORMAT.md).
* **UI:** logical viewport 720×1280, stretch `canvas_items`, aspect `expand`; minimum touch target 96 logical px
  (= 48 dp on a 360 dp phone); Android back button handled (dialog → pause → previous screen → exit). Content lives in a centred column
  (≤ 780 logical px; ≤ 900 on level select) that re-flows on resize/rotation and clears safe-area insets (Android 16 ignores the portrait lock on ≥600 dp screens).

## 6. Requirement traceability (brief sections 1–19)

Legend: ✅ done & verified on desktop · 🟡 done, verification limited · ❌ not done.

| § | Requirement | Status | Evidence / note |
|---|-------------|:--:|----------------|
| 2 | Inspect environment first; preserve existing work | ✅ | Repo was empty; toolchain verified and documented (`docs/ANDROID.md`) |
| 3 | Godot 4 / GDScript / Android portrait / local save / JSON levels / no paid or network deps | ✅ | `project.godot`; manifest has 0 permissions |
| 3 | Monetisation modular, no live ads/IAP | ✅ | `RewardedAdProvider` interface only; `test_services` |
| 4–5.1 | Board of trays/objects, distinct shapes+colours, blocked objects not movable | ✅ | `BoardState`, `Shapes`; fuzz proves blocked objects never pickable |
| 5.2 | One canonical move rule, documented before content | ✅ | `docs/RULES.md`; single implementation; legal-move enumeration = `check_move` (fuzz) |
| 5.3 | Move limits, failure state, restart (+confirm), exact undo, victory, input lock during animation | ✅ | `test_board_rules`, `test_fuzz`, `test_ui_flow`, `test_ui_fuzz` |
| 5.4 | Mechanics introduced gradually, each in a safe level first | ✅ | `test_campaign` (debut order + intro card on each debut level) |
| 6 | Data-driven levels, persistent progress, replayable, locked levels distinct, level select, number/moves shown | ✅ | `campaign.json`, `LevelSelectScreen`, HUD |
| 6 | **30–50 levels, every one with a verified solution** | ✅ | 40 levels; exhaustive BFS proof per level (`docs/validation_report.txt`) |
| 6 | Validator: counts, impossible states, capacity, reachability, duplicates, diagnostics | ✅ | `level_validator.gd`, `validate_levels.gd`, `test_campaign` (incl. negative cases) |
| 7 | Coins, hints cost, no negative balance, rewards exactly once | ✅ | `test_progress`, `test_ui_flow` (double win callback pays once) |
| 8 | Hint = legal next move, no charge when none, explanation, deterministic fallback | ✅ | `HintService`; hint-following wins all 40 levels (≈80 ms worst, desktop) |
| 9 | Premium original UI; all 10 required screens | ✅ | Splash, menu, level select, tutorial (coach + intro cards), gameplay, pause/settings, complete, failed, hint/recovery dialog, privacy+credits — screenshots inspected |
| 9 | HUD: level, moves/remaining, coins, undo, hint, restart, pause; menu progress indicator | ✅ | `GameScreen`, `MenuScreen` |
| 9 | Responsive portrait, ≥48 dp targets, readable text, non-colour cues, reduce-motion | 🟡 | Rendered at 720×1280, 720×1560, 540×960 and landscape/tablet 1280×720, 1200×1920 (centred column); safe-area maths unit-tested (`test_layout`); **real cutout/OS values untested**; **TalkBack impossible on Godot 4.7.1 (no Android accessibility server)** |
| 10 | Feedback: select, move, invalid, tray clear, win, fail, coin, button; sound+music toggles; works without audio | 🟡 | All present & toggleable; coin reward has a sound and text but **no animated coin counter**; **audio never listened to**; haptics none |
| 11 | Save: unlocks, completed, current level, coins, settings, tutorial, active session; validated; corrupt-safe; save at transitions | ✅ | `test_progress` (round trip, corruption, backup, sanitising, suspend flush, session restore) |
| 12 | Ad architecture, no ads shipped, no double rewards, no fake rewards | ✅ | `test_services` |
| 13 | Modular architecture, single state model, signals, no duplicated rules | ✅ | `docs/ARCHITECTURE.md` |
| 14 | Unit/logic/level tests listed in brief | ✅ | 80 tests incl. suspend/resume, repeated taps during animation, 31 200-action fuzz |
| 14 | Tutorial text accurately describes actual rules | 🟡 | Automated: each intro's promised mechanic exists on its level; every refusal reason has text; rules text covers every mechanic. Wording clarity needs a human playtest (`docs/PLAYTEST_PLAN.md`, not run) |
| 14 | **Android: run on device/emulator, test touch/audio/persistence/navigation, inspect logs** | ❌ | Impossible in this environment; full procedure + empty results table in `docs/DEVICE_TEST_PLAN.md` |
| 15 | Lightweight, no needless permissions, no input duplication | 🟡 | Manifest: 0 permissions; duplicate input guarded & tested; **no on-device perf measurement** |
| 16 | Documentation set | ✅ | §10 |
| 17 | Phases 1–5 | ✅ | §7 |
| 17 | Phase 6: app id, version, icon, orientation, export; debug APK; AAB only if possible | 🟡 | Debug APK ✅ (API 36); icon ✅ (safe zone verified); orientation ✅; AAB ❌ blocked (§8); app id placeholder |
| 17 | Phase 7: honest handover | ✅ | This document + README + `docs/KNOWN_ISSUES.md` |
| 18 | Working rules (no placeholder buttons, no hidden failures, progress log) | ✅ | `PROGRESS.md`; no stubbed UI |
| 19 | Definition of done items 1–10 | 🟡 | Items 1–8 ✅; **9 (debug build generated *and tested on a device*) — generated yes (API 36), device-tested no**; 10 ✅ (blockers documented) |

## 7. Phase status

| Phase | Status | Notes |
|------:|:------:|-------|
| 1 Playable prototype | ✅ | Level 1 with final rules. A critical re-review (Phase-1 review) later found and fixed 6 UI defects (§9) |
| 2 Foundation | ✅ | Engine, level format, save, hints, solver, tests |
| 3 Campaign | ✅ | 40 verified levels; generator is a dev tool, results frozen as data |
| 4 Visual polish | ✅ (desktop) | All screens, animations, synthesised audio, settings |
| 5 Full QA | ✅ (desktop) | Everything runnable here has been run; device QA impossible here |
| 6 Android prep | 🟡 | Debug APK (API 36) ✅, icons ✅, store assets ✅; release AAB ❌ blocked (§8) |
| 7 Handover | 🟡 | Written; cannot claim device testing |

## 8. Release blockers and open items (authoritative list)

**Blocked by environment (needs an owner action on the environment):**
1. `dl.google.com` is denied by the egress policy (403 on CONNECT, observed 2026-10-16) → Android Gradle Plugin 8.6.1, SDK platform 36 and
   build-tools 36.1.0 cannot be fetched → **no AAB build and no emulator images** here. Fix: add `dl.google.com` to the environment's *Allowed
   domains* (keep "Allow package managers"), or build on a workstation/CI with Android Studio.
2. `support.google.com` / `play.google.com` are also denied → Play help pages (closed-testing rules, console state) could not be read.

**Owner decisions / actions:**
3. Create the **upload keystore** (`docs/SIGNING.md`), never in git; use Play App Signing.
4. Approve the **final application id** (check it is unused in Play Console), developer name, support email, target age group (`store/PLAY_CONSOLE_PREP.md`).
5. Host the privacy policy at a stable public URL (e.g. GitHub Pages) and fill the placeholders (`store/PRIVACY_POLICY.md`).
6. Create the Play Console app / accept terms / publish — **only with the owner's explicit authorisation**.
7. Recruit testers: human playtest (`docs/PLAYTEST_PLAN.md`) and, if the account requires it, a closed test (confirm in Console; the brief says 12 testers × 14 days for new personal accounts — unverified here).

**Verification still owed (needs a device):**
8. Complete `docs/DEVICE_TEST_PLAN.md` on ≥2 devices (one with cutout, one low-end; ideally a tablet/foldable); fix defects found.
9. Listen to audio; confirm move-limit fairness with real players.

**Accepted/known gaps:** TalkBack unsupported by the engine version; no animated coin counter; no haptics; dead ends reported only via Hint.
**Before any ad SDK:** verify SDK compatibility, consent (UMP), test-ad rules, disclosures, Play policy.

### 8b. Remaining blockers by milestone
* **Before closed testing:** 1 (or a workstation build), 3, 4, 6, a signed AAB, a device smoke test (at least D6/I1–I5/P2), privacy URL (5) for the console form.
* **Before production:** all of the above + closed-test requirement if it applies + 7/9 + re-verify every declaration against the released AAB.

## 9. Verification history (evidence)

| Date | Event | Result |
|------|-------|--------|
| 2026-10-14 | Campaign generated; validator | 40 levels, 0 errors; shortest-solution proof for all |
| 2026-10-14 | Debug APK on Godot 4.3 / later 4.6 | Signed; 0 permissions; target 34 → **35** |
| 2026-10-15 | Core-gameplay review: random-action fuzz + UI fuzz + visual walk-through | 31 200 rules actions clean; **6 UI defects fixed** (tween drift off-slot, dialog double-fire, restored FAILED session without dialog, stale highlights, stale layout after resize, fixed-pixel toasts) |
| 2026-10-16 | Full re-run; touch targets raised 88→96 px | 67/67 tests; 40/40 levels; APK target 35, no permissions |
| 2026-10-16 | **Release-hardening audit.** Baseline reproduced (67/67, 40/40, APK 35). Official Play page: target **API 36** required since 31 Aug 2026 → APK at 35 was non-compliant | Finding |
| 2026-10-16 | Godot 4.6→**4.7.1** (templates target 36); tests/validator/export re-run | 67/67, 40/40, APK `targetSdkVersion:'36'`, 0 permissions, v2+v3 OK |
| 2026-10-16 | Landscape/tablet stretching found by rendering 1280×720 → responsive column + `insets_from_rects` | `test_layout` (5); renders re-inspected |
| 2026-10-16 | Adaptive icon: 685 px outside safe zone → 0 after scaling; store icon/feature graphic/6 screenshots generated; `store/` excluded from APK | measured + inspected |
| 2026-10-16 | AAB attempt in scratch copy: stops at missing keystore; with throw-away key (deleted) stops at AGP resolution (`dl.google.com` 403) | blockers recorded in `docs/ANDROID.md` |
| 2026-10-16 | New tests: tutorial-claims (+2), release-config guard (4), layout (5); APK dependency scan: no ad/analytics/network libs | **78/78**, validator 0 errors |
| 2026-10-16 | Rendering all 29 screens for the UI spec exposed 2 defects: splash logo mis-positioned, Settings dialog taller than the screen → fixed (`test_layout` +2) | **80/80**; spec written (`docs/UI_UX_DESIGN_SPEC.md`) incl. measured WCAG contrast gaps for review |

Known historical bug to keep in mind: packed arrays stored inside an `Array` alias on assignment in Godot —
`BoardState.clone()` copies explicitly (`test_clone_is_independent`).

## 10. Document index — which file owns which truth

| Topic | Owner |
|-------|-------|
| Overall status, requirement traceability, blockers | **this file** |
| Rules / movement / economy details | [`docs/RULES.md`](docs/RULES.md) |
| Module design and decisions | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Level format, authoring, validator | [`LEVELS.md`](docs/LEVELS.md) · data: `levels/campaign.json` · proof: [`docs/validation_report.txt`](docs/validation_report.txt) |
| Save schema, versioning, recovery | [`SAVE_FORMAT.md`](docs/SAVE_FORMAT.md) |
| Tests and results | [`docs/TESTING.md`](docs/TESTING.md) |
| Device test matrix + results log (NOT RUN) | [`docs/DEVICE_TEST_PLAN.md`](docs/DEVICE_TEST_PLAN.md) |
| Human playtest protocol (NOT RUN) | [`docs/PLAYTEST_PLAN.md`](docs/PLAYTEST_PLAN.md) |
| Export / toolchain / blockers evidence | [`docs/ANDROID.md`](docs/ANDROID.md) |
| UI / UX / design specification (+ 29 current screens) | [`docs/UI_UX_DESIGN_SPEC.md`](docs/UI_UX_DESIGN_SPEC.md) · images in `docs/design/` |
| Release signing procedure | [`docs/SIGNING.md`](docs/SIGNING.md) |
| Play listing assets, privacy policy draft, console prep | [`store/`](store/) |
| Licences / dependencies | [`ASSETS_AND_LICENSES.md`](docs/ASSETS_AND_LICENSES.md) |
| Limitations | [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) |
| Pre-publication steps | [`RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) |
| Chronological log | [`../PROGRESS.md`](PROGRESS.md) |

## 11. Maintenance rules for this document

* Change §1, §6–§9 in the **same commit** as any change that alters them (tests count, level count, constants,
  blockers, versions). Numbers here must be reproducible with §4.
* Never mark an item ✅ unless a test, validator run, or inspected artifact proves it; use 🟡/❌ and say why.
* Constants in §5 must match the code; when they diverge, fix this file (or the code) immediately.
