#!/usr/bin/env bash
set -euo pipefail
root="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root"
fail=0
# APIs intentionally forbidden while deployment target remains iOS 16.
patterns=('ContentUnavailableView' 'symbolEffect(' 'sensoryFeedback(' 'containerRelativeFrame(' 'scrollPosition(')
for p in "${patterns[@]}"; do
  hits=$(grep -RInF --include='*.swift' "$p" PredatorLab/PredatorLabApp.swift PredatorLab/Views PredatorLab/Services PredatorLab/State PredatorLab/Models 2>/dev/null || true)
  # Allow our compatibility comment to name ContentUnavailableView.
  if [[ "$p" == 'ContentUnavailableView' ]]; then hits=$(printf '%s\n' "$hits" | grep -v 'PlatformUnavailableView.swift' || true); fi
  if [[ -n "$hits" ]]; then echo "ERROR: iOS 16 surface audit found '$p':"; echo "$hits"; fail=1; fi
done
exit "$fail"
