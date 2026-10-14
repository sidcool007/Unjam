# Android export

## Requirements
* Godot **4.6-stable** editor + matching **export templates** (`4.6.stable`).
* JDK 17+ (21 used here), Android SDK with `platform-tools`, `build-tools` (apksigner, zipalign)
  and `cmdline-tools`; set paths in *Editor Settings → Export → Android*.
* A debug keystore (`keytool -genkeypair -keystore debug.keystore -alias androiddebugkey
  -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android`).
  **Never commit keystores** (`.gitignore` excludes `*.keystore`/`*.jks`).

## Debug APK (what this repo builds today)
```bash
godot --headless --path . --import
godot --headless --path . --export-debug "Android Debug" build/unjam-debug.apk
```
Preset "Android Debug" (`export_presets.cfg`): application id `com.unjam.thelastslot`
(**placeholder – change to an id you own before publishing**), version 0.1.0 / code 1,
portrait, ABIs arm64-v8a + x86_64, no gradle, **all permissions off** (verified with
`aapt dump badging`: no `uses-permission` entries), backup disabled.
Icons: `assets/icon*.svg` → PNGs via `tools/make_icons.gd`.

### Result in this environment
`build/unjam-debug.apk` (~55 MB: two native ABIs + debug template) was exported,
zip-aligned and signed with a *debug* key. It is not committed (`*.apk` is ignored).
Install: `adb install -r build/unjam-debug.apk`.

How the toolchain was assembled here (Google's `dl.google.com` was blocked): Godot,
templates from GitHub releases; `apksigner`, `zipalign`, `adb`, `aapt` from Ubuntu
packages; a minimal SDK folder (`/opt/android-sdk/{platform-tools,build-tools/34.0.0,
cmdline-tools/latest/bin}`) of symlinks plus a stub `sdkmanager`. This is enough for
the non-gradle export only.

## Release AAB (NOT produced)
Needs: the gradle build template installed from the editor (*Project → Install Android
Build Template*), a full Android SDK (platform + build tools; not downloadable here), and
your own **release keystore**. Then use preset "Android Release (AAB)" (gradle,
AAB format, arm64 + armv7), set `keystore/release*` via environment variables
(`GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`) — never in the repo.
No signing key was created and nothing was published.

## Play Store target API
Godot 4.6 templates target Android API 35 (verified with `aapt dump badging`; min SDK 24).
Google Play raises its target-API floor every year: **check the current requirement on the
day you submit** and move to a newer Godot if it is above 35.
