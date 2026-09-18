#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo 'ERROR: xcodegen unavailable' >&2; exit 1; }
rm -rf /tmp/PredatorLab-project-check.xcodeproj
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp project.yml "$TMP/project.yml"
# XcodeGen resolves source paths relative to spec, so generate in repository and inspect deterministically.
xcodegen generate --spec project.yml >/dev/null
[[ -d PredatorLab.xcodeproj ]] || { echo 'ERROR: generated project missing' >&2; exit 1; }
[[ -f PredatorLab.xcodeproj/project.pbxproj ]] || { echo 'ERROR: project.pbxproj missing' >&2; exit 1; }
grep -q 'PredatorLabUITests' PredatorLab.xcodeproj/project.pbxproj || { echo 'ERROR: UI test target absent' >&2; exit 1; }
grep -q 'PredatorLabTests' PredatorLab.xcodeproj/project.pbxproj || { echo 'ERROR: unit test target absent' >&2; exit 1; }
grep -q 'sep2_full_real_hptuners_export.csv' PredatorLab.xcodeproj/project.pbxproj || { echo 'ERROR: Golden Corpus resource absent from generated project' >&2; exit 1; }
echo 'Generated-project topology: PASS'
