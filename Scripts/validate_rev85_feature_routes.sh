#!/usr/bin/env bash
set -euo pipefail
root="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root"
fail=0
for token in 'case .pullLab' 'case .evidence' 'case .calibration' 'case .topology' 'case .execution' 'case .replay'; do
  if ! grep -q "$token" PredatorLab/Views/PredatorLabWorkstationRev85.swift; then echo "ERROR: missing workstation route: $token"; fail=1; fi
done
for token in 'Forensic Workstation' 'PredatorLabWorkstationRev85'; do
  if ! grep -R -q "$token" PredatorLab/Views PredatorLab/PredatorLabApp.swift; then echo "ERROR: workstation not reachable: $token"; fail=1; fi
done
if grep -R -E -n '192\.168\.4\.1|port[^0-9]*2390|0xAA55|0xAA 0x55' PredatorLab/Services PredatorLab/Models PredatorLab/Views --include='*.swift'; then
  echo 'ERROR: unverified MPVI4 framing/endpoint assumption entered production Swift'; fail=1
fi
if grep -R -E -n '1800.*PSI|2100.*PSI|225.*F|145.*F|88%|85.*RPM' PredatorLab/Services/HypothesisSignatureEngineRev85.swift PredatorLab/Services/TelemetryTransportRev85.swift 2>/dev/null; then
  echo 'ERROR: proposed diagnostic threshold entered Rev85 detector/transport code'; fail=1
fi
exit "$fail"
