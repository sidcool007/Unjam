# Android build and export

## Verified toolchain (2026-10-16)
| Component | Version | Notes |
|-----------|---------|-------|
| Godot editor | **4.7.1.stable** (`a13da4feb`) | `/opt/godot471`, symlinked as `godot` |
| Export templates | **4.7.1.stable** | prebuilt APK templates are compiled with **compileSdk 36 / targetSdk 36** (checked with `aapt dump badging` on `android_release.apk`) |
| JDK | OpenJDK 21.0.12 | Godot's gradle template needs ≥17 |
| Gradle | 8.14.3 installed; project wrapper downloads 8.11.1 | |
| `adb` / `aapt` / `aapt2` / `apksigner` / `zipalign` | Ubuntu packages (platform-tools 34.0.4 / apksigner 31.0.2 / zipalign 10.0.0) | in a minimal SDK folder of symlinks, `/opt/android-sdk` (see below) |
| Android SDK platforms | **only `android-34` stub folder** | **no real platform-36 / build-tools-36.1.0** (see blockers) |
| Emulator / device | **none** (`adb devices` empty, no `/dev/kvm`) | |
| Older templates kept | 4.3.stable, 4.6.stable | 4.6 templates target API 35 — do not use for release |

## Play target-API requirement
Official page <https://developer.android.com/google/play/requirements/target-sdk> (read 2026-10-16): from **31 Aug 2026**
new apps and app updates must target **Android 16 (API 36)** or higher. The earlier API-35 APK therefore did **not** meet it.
Fix applied: toolchain moved from Godot 4.6 (template target 35) to **4.7.1** (template target 36), no other upgrade.
**Evidence:** `aapt dump badging build/unjam-debug.apk` → `targetSdkVersion:'36'`, `compileSdkVersion='36'`, `sdkVersion:'24'`,
`uses-permission` count 0, native-code `arm64-v8a x86_64`, APK Signature Scheme v2 and v3 verify.
API-36 behaviour to remember: on screens ≥600 dp (tablets/foldables) Android ignores the portrait lock, so the UI uses a
centred, resize-aware column (`src/ui/column_margin.gd`) — covered by `tests/test_layout.gd`, **not yet seen on a real tablet**.

## Debug APK (what exists today)
```bash
godot --headless --path . --import
godot --headless --path . --export-debug "Android Debug" build/unjam-debug.apk
aapt dump badging build/unjam-debug.apk | grep -E "package:|targetSdk|uses-permission"
apksigner verify --verbose build/unjam-debug.apk
```
Preset "Android Debug": no gradle, ABIs arm64-v8a + x86_64, all permissions off, backup off, version `0.1.0` / code `1`,
application id `com.unjam.thelastslot` (**placeholder**, see `store/PLAY_CONSOLE_PREP.md`). Signed with the standard
**Android debug key** (a throw-away key outside the repo, `CN=Android Debug`) — for testing only, never for release.
Latest artifact: `build/unjam-debug.apk`, 57 133 192 bytes (git-ignored; regenerate with the command above).
`docs/`, `tests/`, `tools/`, `store/`, `*.md` are excluded from the export.

## Release AAB — status: BLOCKED (not built)
Attempted in a scratch copy with the real gradle export preset ("Android Release (AAB)", `android/build` template from
`android_source.zip`, `android/.build_version` = `4.7.1.stable`). Observed, in order:
1. Without a keystore: `ERROR: Code Signing: Could not find release keystore, unable to export.` → **owner must create the upload key** (`docs/SIGNING.md`).
2. With a clearly-labelled throw-away test keystore (deleted afterwards, never a release key): Gradle 8.11.1 downloaded fine, then
   `Plugin [id: 'com.android.application', version: '8.6.1'] was not found` — Google's Maven (`dl.google.com`) answers
   **403 (egress policy denial)**. The same host serves the Android SDK platforms/build-tools, so **no gradle/AAB build can
   succeed in this environment**.
Remedy (owner): in the Claude Code environment settings add `dl.google.com` to *Allowed domains* (keep "Allow package managers"
ticked), or build the AAB on a normal workstation / CI with Android Studio's SDK. Then install `platforms;android-36`,
`build-tools;36.1.0`, NDK not needed for non-custom builds, accept licences, run the command in `docs/SIGNING.md`, and verify with
`bundletool`/`jarsigner`. Do **not** call any unsigned bundle or the debug APK a production release.

## How the minimal SDK folder was built (debug export only)
`/opt/android-sdk/{platform-tools/adb → /usr/bin/adb, build-tools/34.0.0/{apksigner,zipalign} → /usr/bin, cmdline-tools/latest/bin/sdkmanager (stub), platforms/android-34/ (empty)}`
and `~/.config/godot/editor_settings-4.7.tres` (`export/android/android_sdk_path`, `java_sdk_path`, `debug_keystore*`).
Godot prints "Could not find version of build tools that matches Target SDK, using 34.0.0" — harmless for the non-gradle export.
