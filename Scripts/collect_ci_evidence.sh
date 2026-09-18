#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-Audit/CI-Evidence}"
mkdir -p "$OUT"
./Scripts/capture_toolchain_provenance.sh "$OUT/toolchain.txt"
printf 'git_commit=%s\n' "$(git rev-parse HEAD 2>/dev/null || echo unavailable)" > "$OUT/execution.txt"
printf 'workflow=%s\n' "${CI_WORKFLOW:-local}" >> "$OUT/execution.txt"
printf 'build_id=%s\n' "${CI_BUILD_ID:-local}" >> "$OUT/execution.txt"
printf 'build_number=%s\n' "${CI_BUILD_NUMBER:-local}" >> "$OUT/execution.txt"
printf 'action=%s\n' "${CI_XCODEBUILD_ACTION:-local}" >> "$OUT/execution.txt"
printf 'exit_code=%s\n' "${CI_XCODEBUILD_EXIT_CODE:-unknown}" >> "$OUT/execution.txt"
if command -v xcrun >/dev/null 2>&1; then
  xcrun simctl list devices available > "$OUT/available-simulators.txt" 2>/dev/null || true
fi
for r in /tmp/PredatorLab-*.xcresult; do
  [[ -d "$r" ]] || continue
  base="$(basename "$r" .xcresult)"
  printf '%s  %s\n' "$(find "$r" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')" "$r" >> "$OUT/xcresult-tree-hashes.txt"
  if command -v xcrun >/dev/null 2>&1; then
    xcrun xcresulttool get test-results summary --path "$r" --format json > "$OUT/${base}-summary.json" 2>/dev/null || true
  fi
done
find "$OUT" -type f ! -name SHA256SUMS.txt -maxdepth 1 -print0 | sort -z | xargs -0 shasum -a 256 > "$OUT/SHA256SUMS.txt" || true
echo "CI evidence packet: $OUT"
