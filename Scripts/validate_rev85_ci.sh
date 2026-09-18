#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/Scripts/validate_project_hygiene_rev85.sh"
"$ROOT/Scripts/validate_ios16_surface_rev85.sh"
"$ROOT/Scripts/validate_rev85_feature_routes.sh"
# Evidence fixture manifests are intentionally scoped separately from source-control history.
if [[ -f "$ROOT/PredatorLab/Resources/EvidenceFixtures/manifest.json" ]]; then
python3 - <<'PY' "$ROOT/PredatorLab/Resources/EvidenceFixtures/manifest.json"
import json,sys
with open(sys.argv[1]) as f: d=json.load(f)
assert isinstance(d,dict), 'fixture manifest must be an object'
print('Rev85 fixture manifest JSON: PASS')
PY
else
  echo "Rev85 fixture manifest: SKIP (not present in this integration tree)"
fi
echo "Rev85 local CI integrity: PASS"
