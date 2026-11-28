#!/usr/bin/env bash
# Runs on a booted Android emulator: installs the debug APK, launches it, runs the in-app autotest
# (plays level 1 with real taps, checks reward + save), restarts the app and checks persistence,
# and fails on crashes/ANRs. Evidence (screenshots, logcat, device info) goes to $2.
#   ci/emulator_smoke.sh build/unjam-debug.apk ci-out
set -uo pipefail
APK="${1:?apk}"; OUT="${2:-ci-out}"; PKG="com.unjam.thelastslot"; ACT="$PKG/com.godot.game.GodotAppLauncher"  # exported launcher alias (GodotApp itself is not exported)
mkdir -p "$OUT"
fail() {
  echo "SMOKE FAIL: $*"; adb logcat -d > "$OUT/logcat.txt" 2>&1 || true
  # Put the evidence in the job log itself so it can be read without downloading the artifact.
  echo "---- logcat: crashes, Godot and app lines (last 120) ----"
  grep -E "FATAL EXCEPTION|AndroidRuntime|Fatal signal|ANR in|DEBUG +:|libc +:|godot|Godot|GodotApp|unjam|am_crash|am_proc_died|Process .* has died|ActivityManager.*(unjam|Start proc|Displayed|Killing)" "$OUT/logcat.txt" | tail -120
  echo "---- running processes ----"; adb shell ps -A 2>/dev/null | grep -i unjam || echo "(unjam is not running)"
  exit 1
}
shot() { adb exec-out screencap -p > "$OUT/$1.png" 2>/dev/null || true; }
wait_for() { # pattern seconds
  local n=0; while [ $n -lt "$2" ]; do
    if adb logcat -d -s godot:I | grep -q "AUTOTEST FAIL"; then adb logcat -d -s godot:I | grep "AUTOTEST"; fail "in-app autotest reported a failure"; fi
    adb logcat -d -s godot:I | grep -q "$1" && return 0; sleep 2; n=$((n+2)); done; return 1; }

adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
{ echo "== device"; adb shell getprop ro.product.model; adb shell getprop ro.build.version.sdk; adb shell wm size; adb shell wm density
  adb shell dumpsys display | grep -iE "cutout|DisplayInfo" | head -5; } > "$OUT/device.txt" 2>&1
adb install -r "$APK" || fail "install failed"
sleep "${SETTLE_AFTER_INSTALL:-20}"  # let package verification / dexopt / Play Protect finish (a launch right after install died once on API 34)
[ -n "${CUTOUT:-}" ] && { adb shell cmd overlay enable "$CUTOUT" >> "$OUT/device.txt" 2>&1 || echo "cutout overlay not available" >> "$OUT/device.txt"; }
adb logcat -c

# 1) plain cold launch must stay alive and render
adb shell am start -n "$ACT" >/dev/null; sleep 14
if [ -z "$(adb shell pidof "$PKG" | tr -d '\r')" ]; then
  # Observed on the API 34 emulator: the first launch right after install can die within ~0.1 s.
  # Do not hide it: dump the unfiltered log around the launch, warn loudly, retry once like a user would.
  echo "::warning::first launch after install did not survive (see 'first-launch diagnostics' above); retrying once"
  echo "---- first-launch diagnostics: the app's own log lines + activity lifecycle events ----"
  adb logcat -d -b all -v threadtime > "$OUT/first_launch_all_buffers.txt" 2>&1 || true
  APP_PID=$(grep -m1 "am_proc_start.*$PKG" "$OUT/first_launch_all_buffers.txt" | sed -E 's/.*am_proc_start: \[[0-9]+,([0-9]+),.*/\1/')
  echo "app pid at first launch: ${APP_PID:-unknown}"
  { grep -E "wm_(create|destroy|finish|pause|stop|resume|restart|relaunch|set_resumed|on_)[a-z_]*:.*(unjam|godot)|am_(proc_start|proc_died|kill|crash|anr|finish_activity|destroy_activity)[a-z_]*:.*(unjam|$APP_PID)|Fatal signal|FATAL EXCEPTION|ANR in" "$OUT/first_launch_all_buffers.txt"
    [ -n "${APP_PID:-}" ] && awk -v p="$APP_PID" '$3==p' "$OUT/first_launch_all_buffers.txt"; } | sort -u | head -250
  echo "---- activity state ----"; adb shell dumpsys activity activities 2>/dev/null | grep -iE "unjam|mResumed|ResumedActivity|topResumed" | head -10
  adb logcat -c
  adb shell am start -n "$ACT" >/dev/null; sleep 14
  [ -n "$(adb shell pidof "$PKG" | tr -d '\r')" ] || fail "app is not running after launch (also after one retry)"
  FIRST_LAUNCH_DIED=1
fi
shot "01_launch_menu"

# 2) in-app autotest, phase 1 (real taps through the real UI)
adb shell am force-stop "$PKG"; sleep 1
adb shell "run-as $PKG sh -c 'mkdir -p files && touch files/autotest'" || fail "cannot create the autotest trigger (debuggable build expected)"
adb logcat -c
adb shell am start -n "$ACT" >/dev/null
sleep 8; shot "02_autotest_playing"
wait_for "AUTOTEST phase1 PASS" 120 || fail "autotest phase 1 did not finish in time"
sleep 3

# 3) restart the process and verify persistence (phase 2)
adb shell am start -n "$ACT" >/dev/null
wait_for "AUTOTEST phase2 PASS" 90 || fail "autotest phase 2 (persistence after restart) did not pass"

# 4) normal launch again, then background/foreground cycle
adb shell am start -n "$ACT" >/dev/null; sleep 10; shot "03_menu_after_autotest"
adb shell input keyevent KEYCODE_HOME; sleep 3
adb shell am start -n "$ACT" >/dev/null; sleep 4
[ -n "$(adb shell pidof "$PKG" | tr -d '\r')" ] || fail "app died across background/foreground"
shot "04_after_resume"
adb shell dumpsys meminfo "$PKG" | grep -E "TOTAL|Graphics" | head -3 >> "$OUT/device.txt" 2>&1

adb logcat -d > "$OUT/logcat.txt" 2>&1
if grep -E "FATAL EXCEPTION|ANR in $PKG|Fatal signal" "$OUT/logcat.txt" | grep -v "^--" | head -5 | grep -q .; then
  grep -E "FATAL EXCEPTION|ANR in|Fatal signal" "$OUT/logcat.txt" | head; fail "crash/ANR found in logcat"; fi
grep -E "AUTOTEST" "$OUT/logcat.txt" | head
[ "${FIRST_LAUNCH_DIED:-0}" = "1" ] && echo "SMOKE PASS WITH WARNING: the first launch after install died once (retry worked); see diagnostics" || echo "SMOKE PASS"
