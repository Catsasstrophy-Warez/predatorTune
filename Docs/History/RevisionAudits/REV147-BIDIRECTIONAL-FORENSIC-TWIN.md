# Rev147 — Bidirectional Forensic Twin

Rev147 closes the first real two-way navigation loop between the GT500 Living Engineering Twin and the Forensic Command Center.

## Twin → forensic
- Every component node can launch the workstation with a structured `twin:<nodeID>` selection.
- Real-session evidence links can additionally seed timestamp, channel, and supported hypothesis context.
- The synchronized launch does not promote relevance to causation or component health.

## Forensic → Twin
- `GT500TwinBidirectionalResolver` conservatively maps admitted channel/hypothesis/topology context back to relevant Twin investigation nodes.
- Evidence workspace shows these nodes with the explicit boundary `Relevant ≠ causal • selected ≠ failed`.
- Explicit Twin selection survives as structured topology context.

## Truth boundaries
- Fuel Pressure (SAE) is not relabeled as transmission pressure.
- Torque/Spark source timing does not prove DCT causation.
- H4 does not prove clutch slip or a failed clutch.
- Engine RPM/IAT context does not diagnose the supercharger or charge-cooling system.

## Validation
Changed sources and new tests are syntax-parse checked in this packaging environment. Xcode/Swift 6 type checking and XCTest/XCUI execution remain Mac gates.
