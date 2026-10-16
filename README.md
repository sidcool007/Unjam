# Unjam: The Last Slot

A casual Android sorting puzzle built with **Godot 4.6 (GDScript)**. Move objects
between limited-capacity trays; only the top object moves, and you must decide
who gets the *last free slot*. 40 original, solver-verified levels, fully offline,
no ads, no account, **no Android permissions**.

Status: release **candidate** (see `docs/KNOWN_ISSUES.md` and `docs/RELEASE_CHECKLIST.md`).
The game has **not** been run on a physical device or emulator yet.

## Quick start

```bash
# desktop run (portrait window; mouse = touch)
godot --path .

# logic + UI-flow tests (headless)
godot --headless --path . --script res://tests/test_runner.gd

# exhaustive validation of every level (proves shortest solution)
godot --headless --path . --script res://tools/validate_levels.gd

# debug APK  (see docs/ANDROID.md for toolchain setup)
godot --headless --path . --export-debug "Android Debug" build/unjam-debug.apk
```

## How to play
Tap a tray to lift its top object, tap another tray to drop it. Objects stack on
the same shape or go into an empty tray. Fill a tray with one shape to clear it;
clear everything to win. Locks, ice, reserved and one-way trays and move limits are
introduced one at a time. Full rules: [`docs/RULES.md`](docs/RULES.md).

## Documentation
| Doc | Contents |
|-----|----------|
| **[SSOT.md](docs/SSOT.md)** | **single source of truth: current state, requirement traceability, blockers** |
| [RULES.md](docs/RULES.md) | canonical movement/board/win specification |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | modules, data flow, design decisions |
| [LEVELS.md](docs/LEVELS.md) | level format, authoring, generator, validator |
| [SAVE_FORMAT.md](docs/SAVE_FORMAT.md) | save file schema, versioning, recovery |
| [TESTING.md](docs/TESTING.md) | test commands, actual results, manual device test plan |
| [ANDROID.md](docs/ANDROID.md) | export instructions, what was and wasn't built |
| [ASSETS_AND_LICENSES.md](docs/ASSETS_AND_LICENSES.md) | dependencies and licences |
| [KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) | limitations, untested items |
| [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | steps before Play Store publication |
| [validation_report.txt](docs/validation_report.txt) | output of the level validator |
| [PROGRESS.md](PROGRESS.md) | development log |
