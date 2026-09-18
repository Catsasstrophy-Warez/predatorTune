#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
EXPECTED="$(tr -d '[:space:]' < Tooling/XCODEGEN_VERSION)"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "ERROR: XcodeGen $EXPECTED required but xcodegen is unavailable" >&2; exit 1
fi
ACTUAL="$(xcodegen --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
[[ "$ACTUAL" == "$EXPECTED" ]] || { echo "ERROR: XcodeGen drift: expected $EXPECTED, got ${ACTUAL:-unknown}" >&2; exit 1; }
echo "XcodeGen version: PASS ($ACTUAL)"
