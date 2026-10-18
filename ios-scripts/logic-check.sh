#!/bin/bash
#
# BakeCheck — iOS business-rule check.
#
# Compiles the app's real Core/Data/State sources together with a small
# assertion harness and runs it on macOS. No Xcode UI, no simulator, no
# duplicate implementation of the rules.
#
#   ./ios-scripts/logic-check.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/bakery-unforgotten/BakeCheck"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "BakeCheck · กำลังคอมไพล์ชุดตรวจสอบกฎทางธุรกิจ…"

swiftc \
  -swift-version 5 \
  -parse-as-library \
  -default-isolation MainActor \
  -o "$WORK/bakecheck-logic-check" \
  "$APP/Core/Models.swift" \
  "$APP/Core/Verification.swift" \
  "$APP/Core/Formatters.swift" \
  "$APP/Core/Scanner.swift" \
  "$APP/Core/Notifications.swift" \
  "$APP/Data/SeedData.swift" \
  "$APP/State/AppStore.swift" \
  "$ROOT/ios-scripts/logic-check/LogicCheck.swift"

"$WORK/bakecheck-logic-check"
