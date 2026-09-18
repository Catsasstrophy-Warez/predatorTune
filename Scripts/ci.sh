#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./Scripts/verify_fresh_clone.sh
command -v xcodegen >/dev/null || { echo 'ERROR: xcodegen is required' >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo 'ERROR: Xcode/xcodebuild is required' >&2; exit 1; }
command -v xcrun >/dev/null || { echo 'ERROR: xcrun is required' >&2; exit 1; }
./Scripts/verify_tool_versions.sh
./Scripts/capture_toolchain_provenance.sh Audit/TOOLCHAIN-PROVENANCE-local.txt

echo '==> Generate and verify project'
xcodegen generate --spec project.yml
./Scripts/verify_generated_project.sh
xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -list

echo '==> Analyze generic simulator product'
xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO analyze

echo '==> Build-for-testing once per device family, then test without rebuilding'
for FAMILY in iphone ipad; do
  SIM_ID="$(./Scripts/select_ci_simulator.py --family "$FAMILY")"
  echo "==> $FAMILY simulator: $SIM_ID"
  xcrun simctl boot "$SIM_ID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$SIM_ID" -b
  DD="/tmp/PredatorLab-DD-${FAMILY}"; rm -rf "$DD"
  BUILD_RESULT="/tmp/PredatorLab-${FAMILY}-build.xcresult"; rm -rf "$BUILD_RESULT"
  TEST_RESULT="/tmp/PredatorLab-${FAMILY}-test.xcresult"; rm -rf "$TEST_RESULT"
  xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -configuration Debug -destination "id=$SIM_ID" -derivedDataPath "$DD" -resultBundlePath "$BUILD_RESULT" CODE_SIGNING_ALLOWED=NO build-for-testing
  xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -configuration Debug -destination "id=$SIM_ID" -derivedDataPath "$DD" -resultBundlePath "$TEST_RESULT" test-without-building
  [[ -d "$TEST_RESULT" ]] || { echo "ERROR: missing $FAMILY test xcresult" >&2; exit 1; }
done
./Scripts/collect_ci_evidence.sh Audit/CI-Evidence
echo '==> Local Apple-toolchain gate passed'
