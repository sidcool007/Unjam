#!/usr/bin/env bash
# Installs the pinned Godot editor (+ optionally the Android export templates) for CI or a fresh machine.
#   GODOT_VERSION=4.7.1-stable WITH_TEMPLATES=1 ./ci/install_godot.sh
set -euo pipefail
VER="${GODOT_VERSION:-4.7.1-stable}"
DIR="${GODOT_DIR:-$HOME/godot-ci}"
BASE="https://github.com/godotengine/godot/releases/download/${VER}"
mkdir -p "$DIR"
if [ ! -x "$DIR/godot" ]; then
  curl -sSL --fail -o "$DIR/godot.zip" "$BASE/Godot_v${VER}_linux.x86_64.zip"
  unzip -oq "$DIR/godot.zip" -d "$DIR"
  ln -sf "$DIR/Godot_v${VER}_linux.x86_64" "$DIR/godot"
  rm -f "$DIR/godot.zip"
fi
if [ "${WITH_TEMPLATES:-0}" = "1" ]; then
  TPL="$HOME/.local/share/godot/export_templates/${VER/-/.}"
  if [ ! -f "$TPL/android_release.apk" ]; then
    mkdir -p "$TPL" "$DIR/tpl"
    curl -sSL --fail -o "$DIR/tpl.tpz" "$BASE/Godot_v${VER}_export_templates.tpz"
    unzip -oq "$DIR/tpl.tpz" -d "$DIR/tpl"
    cp -r "$DIR/tpl/templates/"* "$TPL/"
    rm -rf "$DIR/tpl" "$DIR/tpl.tpz"
  fi
fi
echo "$DIR" >> "${GITHUB_PATH:-/dev/null}"
"$DIR/godot" --headless --version
