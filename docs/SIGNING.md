# Release signing — secure procedure (no key exists yet)

**Current state: no release keystore has been created. None is stored in this repository. Credentials must never be committed.**

## Concepts (Google Play App Signing)
* **App signing key** — the key Google uses to sign the APKs delivered to users. With Play App Signing Google holds it.
* **Upload key** — the key *you* keep and use to sign the AAB you upload. If it is lost or leaked you can ask Play support
  to reset it; the app-signing key is unaffected. This is why Play App Signing is strongly preferred.
Use Play App Signing; generate an **upload key** only.

## Create the upload keystore (owner, on a trusted machine, outside the repo)
```bash
keytool -genkeypair -v -keystore ~/secure/unjam-upload.keystore -alias unjam-upload \
  -keyalg RSA -keysize 4096 -validity 9125 -storetype PKCS12
# choose a strong passphrase when prompted; note the alias and the passphrase in a password manager
keytool -list -v -keystore ~/secure/unjam-upload.keystore -alias unjam-upload | grep -E "SHA-256|Valid"
```
Back up the keystore file and passphrase in **two** separate secure places (password manager + encrypted offline copy).

## Use it for a build (never write secrets into tracked files)
```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/secure/unjam-upload.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=unjam-upload
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='…'          # typed into the shell / CI secret store, not a file in git
godot --headless --path . --export-release "Android Release (AAB)" build/unjam-release.aab
```
Pre-requisites for that command (see `docs/ANDROID.md`): Android Build Template installed (`android/build`, created by
*Project → Install Android Build Template* or by unzipping `android_source.zip`), a full Android SDK with
platform 36 and build-tools 36.1.0, and network access to Google's Maven.
`tests/test_release_config.gd` fails if any keystore/password field in `export_presets.cfg` is non-empty.

## Verify the result
```bash
bundletool validate --bundle=build/unjam-release.aab                          # structure
bundletool dump manifest --bundle=build/unjam-release.aab | grep -E "package|versionCode|targetSdk|uses-permission"
jarsigner -verify -verbose -certs build/unjam-release.aab | head              # signed by the upload key
keytool -printcert -jarfile build/unjam-release.aab                           # compare SHA-256 with the keystore listing
```
Then upload to Play Console → enrol in Play App Signing when prompted. Keep the debug APK for testing; never ship it.
