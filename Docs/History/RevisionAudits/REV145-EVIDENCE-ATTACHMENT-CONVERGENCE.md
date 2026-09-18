# Rev145 — Evidence Attachment Convergence

Rev145 changes the Living Engineering Twin from descriptive component navigation into an evidence-attached model.

## Added
- `GT500TwinEvidenceGraph`: typed evidence objects attached to individual Twin nodes.
- Evidence kinds for factory source, topology, telemetry, DTC/service, measurement, hypothesis, calibration, and research gaps.
- Authority labels that keep source-verified, observed, derived, candidate, and unknown information distinct.
- `GT500TwinEvidenceInspector`: node-local evidence/limitations display inside the component browser.
- Regression tests protecting C105, TR-9070 pressure, production PCM/control-pack, and Scanner cadence truth boundaries.

## Important correction
Legacy technical seed data incorrectly reused `C105` as an in-tank fuel-pump connector with unsupported terminal/detail claims. Ford SSM 49581 verifies C105 as an inline connector next to the right-side valve cover in its specified 2020–2021 GT500 transmission diagnostic context. Rev145 removes the conflicting C105 designation and quarantines the remaining legacy fuel-connector detail until exact production wiring evidence is acquired.

## Evidence discipline
- A selected/glowing Twin node is navigation, not vehicle health.
- Source verified is not vehicle validated.
- The 3.0 bar value in TSB 21-2059 remains a procedure-specific decision point, not a universal TR-9070 pressure specification.
- VCM Scanner configured polling interval remains distinct from observed per-channel cadence.
- TC-298B control-pack evidence cannot fill the production GT500 PCM definition gap.
