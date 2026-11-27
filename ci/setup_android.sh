#!/usr/bin/env bash
# Prepares the Android SDK pieces and Godot editor settings for exporting. Needs network access to Google's SDK host.
# Env: ANDROID_HOME (preinstalled on GitHub runners), JAVA_HOME (JDK 17+), GODOT_VERSION.
set -euo pipefail
VER="${GODOT_VERSION:-4.7.1-stable}"
MM="$(echo "$VER" | cut -d. -f1-2)"      # 4.7
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
SM="$SDK/cmdline-tools/latest/bin/sdkmanager"
[ -x "$SM" ] || SM="$(ls "$SDK"/cmdline-tools/*/bin/sdkmanager | head -1)"
yes | "$SM" --licenses >/dev/null || true
"$SM" "platform-tools" "platforms;android-36" "build-tools;36.1.0" ${INSTALL_NDK:+"ndk;29.0.14206865"} >/dev/null
KS="${DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
if [ ! -f "$KS" ]; then
  mkdir -p "$(dirname "$KS")"
  keytool -genkeypair -keystore "$KS" -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi
mkdir -p "$HOME/.config/godot"
cat > "$HOME/.config/godot/editor_settings-${MM}.tres" <<EOT
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$SDK"
export/android/java_sdk_path = "${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export/android/debug_keystore = "$KS"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOT
echo "Android SDK ready at $SDK; build-tools: $(ls "$SDK/build-tools" | tr '\n' ' ')"
