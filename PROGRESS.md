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

2026-10-16: added docs/SSOT.md; raised minimum touch target 88→96 logical px (48 dp on a 360 dp phone).
