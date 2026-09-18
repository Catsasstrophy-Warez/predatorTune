# Rev148 Cursor-Driven Forensic Twin

Rev148 adds cursor-scoped Twin relevance to the Forensic Command Center.

## Added
- `GT500TwinCursorIntelligence`: conservative mapping of synchronized cursor/channel/hypothesis/topology context into relevant Twin nodes.
- `GT500TwinCursorInspector`: persistent iPhone/iPad inspector showing relevant physical nodes at the current forensic cursor.
- Component-specific preferred channel groups for DCT/controller, production fuel, engine/charge-cooling, and scanner/sensor investigations.
- Regression tests for H4 DCT relevance, fuel-pressure semantic separation, and the clutch-slip evidence firewall.

## Truth boundaries
- Highlighted = relevant, not failed or healthy.
- Fuel Pressure (SAE) is never relabeled transmission pressure.
- Torque/Spark Source timing is context, not DCT causation.
- RPM difference is never promoted to clutch slip without verified shaft/gear relationships.
- Candidate hypotheses remain unresolved until discriminator evidence is acquired.

## Remaining runtime gates
Xcode/Swift 6 type checking, XCTest/XCUI execution, iPhone/iPad rendering, performance profiling, and physical GT500 validation must be performed on the Mac/Xcode machine.
