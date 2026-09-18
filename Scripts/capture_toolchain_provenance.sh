#!/usr/bin/env bash
set -euo pipefail
ROOT="${SRCROOT:-${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}}"
cd "$ROOT"
OUT="${1:-Audit/TOOLCHAIN-PROVENANCE.txt}"
mkdir -p "$(dirname "$OUT")"
{
 echo "PredatorLab toolchain provenance"
 echo "generated_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
 echo "git_commit=$(git rev-parse HEAD 2>/dev/null || echo unavailable)"
 echo "ci_build_id=${CI_BUILD_ID:-unavailable}"
 echo "ci_build_number=${CI_BUILD_NUMBER:-unavailable}"
 echo "ci_workflow=${CI_WORKFLOW:-unavailable}"
 echo "ci_action=${CI_XCODEBUILD_ACTION:-unavailable}"
 echo "xcode_path=${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || echo unavailable)}"
 xcodebuild -version 2>/dev/null || true
 swift --version 2>/dev/null || true
 xcodegen --version 2>/dev/null || true
 uname -a
} > "$OUT"
echo "Toolchain provenance: $OUT"
