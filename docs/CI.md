# Continuous integration and automated Android verification

Files: `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `ci/*.sh`, `src/services/autotest.gd`.

**Status: IMPLEMENTED, NOT VERIFIED.** The workflows could not be executed from the build environment (no GitHub Actions access;
Google's SDK host is blocked there). Their *parts* were exercised locally: `ci/install_godot.sh` (editor + templates), the debug export,
`ci/check_apk.sh`, shell syntax of every script, YAML parsing, and the in-app autotest on desktop (including a real app restart).
The first run on GitHub is the real verification — see "First run" below.

## What runs on every push / PR (`ci.yml`)
| Job | Does | Proves |
|-----|------|--------|
| `test` | imports the project, runs `tests/test_runner.gd`, runs `tools/validate_levels.gd` | rules, UI, fuzz, save, layout, contrast; all levels solvable + shortest solution proven |
| `apk` | installs Godot + templates + Android SDK (platform 36, build-tools 36.1.0), exports the debug APK, runs `ci/check_apk.sh` | **target SDK 36 and zero permissions** are enforced on every build; uploads the APK artifact |
| `emulator` (matrix) | boots an Android emulator, installs the APK, runs `ci/emulator_smoke.sh` | see below |

Emulator configurations: **Android 14 / Pixel 6** and **Android 10 / Nexus 5, 1.5 GB RAM, with a display-cutout overlay** (the "lower-end" and
"cutout" device configurations asked for in the release brief). Each run uploads screenshots, `logcat.txt` and device info (`emulator-evidence-api*` artifacts).

`ci/emulator_smoke.sh`: cold launch stays alive and renders → creates the debug-only trigger file via `run-as` → the app plays **level 1 with real
tray taps**, checks the win, the single coin reward and the unlock (`Autotest` phase 1) → the process is restarted and **progress/coins are verified to have
survived** (phase 2) → home/resume cycle → fails on `FATAL EXCEPTION`, `ANR` or native crashes in logcat.

Limits (be honest in reports): emulators are not phones — no real touch hardware, thermal/memory behaviour, vendor cutouts or audio output. This closes
"has it ever run on Android at all" and "does persistence survive a process restart"; it does **not** replace the owner's manual plan in `docs/DEVICE_TEST_PLAN.md`.
The debug-only self-test (`OS.is_debug_build()` and a trigger file in app-private storage) is inert in release exports.

## Release bundle (`release.yml`, manual)
`Actions -> Release AAB (manual) -> Run workflow`. Needs three repository secrets (see the header of the file and `docs/SIGNING.md`):
`ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_UPLOAD_KEY_ALIAS`, `ANDROID_UPLOAD_KEYSTORE_PASSWORD`. Without them it stops with a clear error.
It builds a signed AAB with the gradle template, then verifies it with `bundletool validate`, checks the manifest (target SDK 36, no permissions) and
the signature, prints the SHA-256 and uploads the bundle as an artifact. **It never publishes to Google Play**; the upload is a manual Play Console step.

## First run — owner checklist
1. Push is already done; open the repository's **Actions** tab and enable workflows if GitHub asks.
2. Watch `CI`. Likely first-run fixes (not guessable from here): runner image details (SDK location/Java), emulator boot flags, a Godot flag change.
   Paste the failing step's log back and it can be fixed quickly.
3. For a release: create the upload key (`docs/SIGNING.md`), add the 3 secrets, run `Release AAB (manual)`.
