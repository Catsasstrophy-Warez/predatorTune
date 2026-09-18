#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./Scripts/verify_fresh_clone.sh
./Scripts/validate_rev85_ci.sh
printf '\nRepository metrics\n'
printf 'Swift sources: '; find PredatorLab PredatorLabTests PredatorLabUITests -name '*.swift' -type f | wc -l | tr -d ' '
printf 'Test Swift files: '; find PredatorLab/PredatorLabTests PredatorLabTests PredatorLabUITests -name '*.swift' -type f | wc -l | tr -d ' '
printf 'Fixture bytes: '; find PredatorLab/Resources/Fixtures PredatorLab/Resources/ImportedHPL -type f -not -name '*.sha256' -exec stat -f '%z' {} + 2>/dev/null | awk '{s+=$1} END{print s+0}' || true
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate --spec project.yml
  echo 'XcodeGen generation: PASS'
else
  echo 'XcodeGen generation: NOT RUN (xcodegen unavailable on this host)'
fi
if command -v xcodebuild >/dev/null 2>&1; then
  echo 'xcodebuild available: YES'
else
  echo 'xcodebuild available: NO (requires macOS/Xcode or Xcode Cloud)'
fi
