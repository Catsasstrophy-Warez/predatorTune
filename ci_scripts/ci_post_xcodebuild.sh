#!/bin/sh
set -eu
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
echo "==> PredatorLab Xcode action complete"
echo "Build: ${CI_BUILD_NUMBER:-local}"
echo "Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "Exit: ${CI_XCODEBUILD_EXIT_CODE:-unknown}"
./Scripts/collect_ci_evidence.sh Audit/CI-Evidence || true
if [ "${CI_XCODEBUILD_EXIT_CODE:-0}" != "0" ]; then
  echo "ERROR: xcodebuild action failed" >&2
  exit "${CI_XCODEBUILD_EXIT_CODE}"
fi
