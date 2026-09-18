#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null || { echo 'ERROR: Xcode required' >&2; exit 1; }
[[ -d PredatorLab.xcodeproj ]] || { echo 'ERROR: generate PredatorLab.xcodeproj first' >&2; exit 1; }
OUT="${1:-/tmp/PredatorLab-RC.xcarchive}"
rm -rf "$OUT"
echo '==> Archive Release Candidate for generic iOS device'
xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -configuration Release -destination 'generic/platform=iOS' -archivePath "$OUT" archive
[[ -d "$OUT" ]] || { echo 'ERROR: archive missing' >&2; exit 1; }
/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleIdentifier' "$OUT/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "$OUT/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$OUT/Info.plist" 2>/dev/null || true
echo "Archive: $OUT"
