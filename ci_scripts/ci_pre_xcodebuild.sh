#!/bin/sh
set -eu
ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
echo "==> PredatorLab pre-xcodebuild validation (${CI_XCODEBUILD_ACTION:-local})"
./Scripts/verify_fresh_clone.sh
./Scripts/verify_tool_versions.sh
./Scripts/verify_ci_contract.sh
./Scripts/validate_rev85_ci.sh
./Scripts/verify_resource_topology.py
./Scripts/capture_toolchain_provenance.sh Audit/TOOLCHAIN-PROVENANCE-pre-xcodebuild.txt
# Fail early if the Cloud action cannot see the generated project/scheme.
if command -v xcodebuild >/dev/null 2>&1 && [ -d PredatorLab.xcodeproj ]; then
  xcodebuild -project PredatorLab.xcodeproj -list >/tmp/predatorlab-xcode-list.txt
  grep -q 'PredatorLab' /tmp/predatorlab-xcode-list.txt || { echo 'ERROR: PredatorLab scheme/target not discoverable' >&2; exit 1; }
fi
