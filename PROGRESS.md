# Progress log

| Phase | Status |
|-------|--------|
| 1 Playable prototype | done — rules engine + level 1 playable with undo/restart/win (tested headless + rendered) |
| 2 Foundation | done — BoardState, GameSession, solver, hints, validator, save system, economy, tests |
| 3 Campaign | done — 40 generated levels, each with proven-shortest recorded solution; tutorial coach + intro cards |
| 4 Visual polish | done — all 10 required screens, animations, procedural audio, settings, safe-area handling |
| 5 QA | done on desktop — 55 tests + validator green, screens inspected; device QA **not possible here** |
| 6 Android prep | debug APK built/signed (no permissions, portrait); AAB **not built** (SDK/keystore unavailable) |
| 7 Handover | see final report / README |

Notable fixes during development: `clone()` aliasing packed arrays (found by generator crash,
regression test added); control sizing (`set_anchors_and_offsets_preset`); tests starting before
autoload `_ready`; move limits widened from par+3..5 to par+45 % after judging them too harsh.

Upgrade: moved the toolchain from Godot 4.3 to 4.6 (tests/validator green on both); debug APK now targets API 35, still no permissions.

## Core-gameplay review (before any Phase 2 work)
Defects found by code review + randomised exploration, all fixed and covered by tests:
1. Objects/trays drifted off their slots after rapid taps: overlapping tweens and shakes captured stale positions.
   Now one tracked position tween per node and slot maths use canonical tray columns.
2. Dialog buttons re-ran their action on a second tap before the dialog was freed (e.g. double Undo / double Next).
3. A saved FAILED session restored into a screen with no failure dialog (stuck HUD).
4. Destination highlights stayed lit during the move animation.
5. A resize during an animation left a stale layout (now re-laid-out when the animation ends).
6. Toasts used fixed pixel positions and could overlap the board on tall phones (now bottom-anchored).
No rule-engine defects were found: 31 200 randomised actions held every invariant.

2026-10-16: added SSOT.md (repo root); raised minimum touch target 88→96 logical px (48 dp on a 360 dp phone).

## Release hardening (2026-10-16)
* Audit baseline reproduced; official Play rule read: target API 36 required since 2026-08-31 → APK was at 35.
* Toolchain Godot 4.6 → 4.7.1: APK now `targetSdkVersion 36`. Tests 78/78, validator 40/40.
* Fixed: landscape/tablet stretching (responsive column), adaptive-icon safe zone; added store assets, privacy-policy and Play Console drafts,
  device/playtest/signing procedures, release-config guard test, tutorial-claim tests.
* Blocked/owner: AAB (keystore + dl.google.com), device testing, application id, privacy URL, testers. See SSOT §8.

2026-10-16: UI/UX/design spec + 29 rendered screens (`docs/UI_UX_DESIGN_SPEC.md`, `docs/design/`); fixed splash position and oversized Settings dialog; 80/80 tests.

## UI/UX improvement pass (2026-10-16, after external review)
Baseline reproduced (80/80, 40/40, APK 36). Findings from the reviewer's brief + own audit; each fixed with a test where behaviour changed:
contrast tokens (`test_contrast`), tray rule tags, lock/ice status pills, Restart moved away from Hint, toast duration, board position, menu spacing,
reward animation, intro-once + settings-persistence + 4-aspect-ratio layout tests. 91/91, validator 40/40, APK target 36 / 0 permissions.
Not changed (and why): haptics (needs VIBRATE permission), TalkBack (engine lacks Android accessibility server), device testing (no device).

## Second review pass (2026-10-17)
Baseline 91/91, 40/40, APK 36. Amber triangle: deeper fill + thicker 50 % rim for that shape only (verified in normal/selected/locked/frozen/stacked/page-bg, before/after sheet);
tray outline token 3.59:1. Tests added for hint-state, dialog hierarchy, result-dialog dismissal, minimum slot size, amber contrast (99/99). Pause position and level-select indicators evaluated and left unchanged
(provisional, documented). Not changed: haptics (permission), TalkBack (engine), device testing (no device), AAB (SDK host denied + owner key).
