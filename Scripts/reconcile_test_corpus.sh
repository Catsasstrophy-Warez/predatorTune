#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "Configured XCTest roots:"
echo "  PredatorLab/PredatorLabTests"
echo "  PredatorLabTests"
echo "  PredatorLabUITests"
for d in PredatorLab/PredatorLabTests PredatorLabTests PredatorLabUITests; do
  files=$(find "$d" -type f -name '*.swift' | wc -l | tr -d ' ')
  tests=$(grep -RhoE 'func[[:space:]]+test[A-Za-z0-9_]+' "$d" --include='*.swift' 2>/dev/null | wc -l | tr -d ' ')
  echo "$d files=$files named_xctest_functions=$tests"
done
all=$(grep -RhoE 'func[[:space:]]+test[A-Za-z0-9_]+' PredatorLab/PredatorLabTests PredatorLabTests PredatorLabUITests --include='*.swift' 2>/dev/null | wc -l | tr -d ' ')
echo "TOTAL named XCTest/XCUI functions=$all"
echo "Historical counts used different snapshots/counting methods. Treat this as reconciliation evidence, not proof of runtime discovery."
