#!/bin/sh
set -eu
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
echo "==> PredatorLab Xcode Cloud post-clone bootstrap"
echo "Xcode Cloud: ${CI_XCODE_CLOUD:-FALSE} | workflow: ${CI_WORKFLOW:-local} | action: ${CI_XCODEBUILD_ACTION:-unknown}"
./Scripts/verify_fresh_clone.sh
EXPECTED_XCODEGEN="$(tr -d '[:space:]' < Tooling/XCODEGEN_VERSION)"
if ! command -v xcodegen >/dev/null 2>&1; then
  command -v brew >/dev/null 2>&1 || { echo 'ERROR: Homebrew unavailable; cannot install XcodeGen' >&2; exit 1; }
  brew install xcodegen
fi
./Scripts/verify_tool_versions.sh
xcodegen --version
xcodegen generate --spec project.yml
./Scripts/verify_generated_project.sh
./Scripts/capture_toolchain_provenance.sh Audit/TOOLCHAIN-PROVENANCE-post-clone.txt
[ -d PredatorLab.xcodeproj ] || { echo 'ERROR: XcodeGen did not create PredatorLab.xcodeproj' >&2; exit 1; }
echo "==> Generated PredatorLab.xcodeproj from project.yml"
