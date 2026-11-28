#!/usr/bin/env bash
# Verifies an APK against the project's release invariants. Usage: ci/check_apk.sh path.apk [aapt path]
set -euo pipefail
APK="${1:?apk}"
AAPT="${2:-aapt}"
B="$("$AAPT" dump badging "$APK")"
echo "$B" | grep -E "^package:|targetSdkVersion|sdkVersion|native-code"
echo "$B" | grep -q "targetSdkVersion:'36'" || { echo "FAIL: target SDK is not 36"; exit 1; }
if echo "$B" | grep -q "^uses-permission"; then echo "FAIL: unexpected permissions:"; echo "$B" | grep "^uses-permission"; exit 1; fi
grep -q "name='com.sidcool.unjam'" <<<"$B" || echo "FAIL-SOFT NOTE: package id is not com.sidcool.unjam (the id the owner chose)"
echo "APK checks passed (target SDK 36, zero permissions)"
