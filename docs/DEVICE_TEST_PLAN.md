# Android device test plan and results log

**Status of every row below: NOT RUN.** No Android device or emulator has been available to any
session so far (no `/dev/kvm`, no system images obtainable, `adb devices` empty). Nothing here
is a result; it is the exact procedure for the owner (or any session with a device) and the
table in which to record results. Do not mark a row Pass unless it was performed.

## Setup (per device)
```bash
adb devices                                              # device authorised?
adb install -r build/unjam-debug.apk                     # debug APK is debuggable → run-as works
adb logcat -c && adb logcat -s godot AndroidRuntime DEBUG > logcat_<device>.txt &
adb shell am start -n com.unjam.thelastslot/com.godot.game.GodotApp
adb shell dumpsys package com.unjam.thelastslot | grep -E "versionName|targetSdk|permission"   # expect no granted permissions
```
Save location on device: `/data/data/com.unjam.thelastslot/files/` (Godot `user://`), file `unjam_save.json`.
Useful: `adb shell am force-stop com.unjam.thelastslot` · `adb shell cmd connectivity airplane-mode enable`
(or toggle in the UI) · `adb shell input keyevent KEYCODE_BACK` · `adb shell wm size 1080x2400`.

Recommended devices (≥2): (A) low-end/small phone, Android 8–10, ≤2 GB RAM, 16:9–18:9;
(B) modern phone with a **display cutout** and gesture navigation, Android 14–16; optional (C) tablet/foldable
(Android 16 ignores the portrait lock at ≥600 dp, so landscape must be checked there).

## Results table
Columns: ID · Test · Expected · Device · Actual · Pass/Fail · Defect ref.

| ID | Test | Expected | Device | Actual | Result | Defect |
|----|------|----------|--------|--------|--------|--------|
| I1 | Fresh install, first launch | Splash → menu, no crash, no permission prompt | – | – | NOT RUN | – |
| I2 | Tutorial on level 1 | Coach text guides lift+drop; level 1 completes; +30 coins once | – | – | NOT RUN | – |
| I3 | Level select & unlocks | Only level 2 unlocks after level 1; locked tiles show padlock + toast | – | – | NOT RUN | – |
| I4 | System back button | Closes dialogs → game opens pause → select → menu → exits from menu; non-dismissible result dialogs ignore back | – | – | NOT RUN | – |
| I5 | Pause/resume, Home and return | Same board, move count, undo history; no duplicate dialog | – | – | NOT RUN | – |
| G1 | Valid/invalid moves | Valid animates; invalid shakes + toast with reason; state unchanged | – | – | NOT RUN | – |
| G2 | Capacity, blocked objects | Full tray rejects; only top object lifts | – | – | NOT RUN | – |
| G3 | Level 15 padlock, 27 ice, 21 reserved, 24 one-way | Each behaves per intro card; toasts explain refusals | – | – | NOT RUN | – |
| G4 | Win / fail (level 11 move limit) | Win dialog with stars; fail dialog offers Undo/Restart; single reward | – | – | NOT RUN | – |
| G5 | Undo / restart | Exact previous state; restart asks confirmation after ≥1 move | – | – | NOT RUN | – |
| G6 | Hint & coins | Hint highlights legal move, −15 coins; refused with <15; dead-end hint free | – | – | NOT RUN | – |
| G7 | Rapid repeated touches during animation | Exactly one move; no stuck state | – | – | NOT RUN | – |
| G8 | Complete levels 1–4 | Each reward paid once; replay pays 0 | – | – | NOT RUN | – |
| P1 | Save/load | Progress, coins, settings survive relaunch | – | – | NOT RUN | – |
| P2 | Background → resume (≥10 min, memory pressure) | Session restored; no lost/duplicated reward | – | – | NOT RUN | – |
| P3 | Force-stop mid-level → relaunch | *Continue* resumes board + undo history | – | – | NOT RUN | – |
| P4 | Corrupt save: `adb shell run-as com.unjam.thelastslot sh -c 'echo garbage > files/unjam_save.json'` | Menu shows "save could not be read"; backup or fresh start; no crash | – | – | NOT RUN | – |
| P5 | Truncated/odd JSON (`{"version":1,"coins":-5}`) | Sanitised to defaults for bad fields | – | – | NOT RUN | – |
| D1 | Portrait layout, system bars | Nothing under status/nav bar; board fully visible | – | – | NOT RUN | – |
| D2 | Display cutout / rounded corners (device B) | HUD buttons not clipped | – | – | NOT RUN | – |
| D3 | Touch target size & readability | All controls comfortably tappable with a thumb; text legible outdoors | – | – | NOT RUN | – |
| D4 | Audio: SFX/music toggles, volume | Audible, not harsh, toggles take effect immediately; silent mode respected | – | – | NOT RUN | – |
| D5 | Performance | Smooth animation, no visible stutter on hint, no ANR; note device & fps feel | – | – | NOT RUN | – |
| D6 | Logs | `logcat` free of `E godot`/crash entries during the above | – | – | NOT RUN | – |
| D7 | Airplane mode, whole session | Everything works; no network error anywhere | – | – | NOT RUN | – |
| D8 | Tablet/foldable & rotation (device C) | Landscape shows a centred phone-style column; rotating mid-level keeps the board | – | – | NOT RUN | – |

## Defect log
| Ref | Found by | Description | Fix commit | Retest |
|-----|----------|-------------|-----------|--------|
| – | – | none recorded (no device run yet) | – | – |

## What *has* been simulated (not a substitute for the table above)
Headless/desktop only: rules fuzz, UI fuzz, safe-area arithmetic (`tests/test_layout.gd`), wide-window layout,
and renders at 720×1280, 720×1560, 540×960, 1200×1920, 1280×720.
