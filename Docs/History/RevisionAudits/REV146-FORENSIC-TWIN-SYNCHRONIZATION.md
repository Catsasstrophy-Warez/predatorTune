# Rev146 — Forensic Twin Synchronization

Rev146 connects the Living Engineering Twin to the existing real sep2/Golden Corpus forensic evidence without changing evidence authority.

## Added
- `GT500TwinForensicBridge`: node-specific links into observed sep2 samples and unresolved hypotheses.
- `GT500TwinForensicLinksView`: component-level real-session evidence cards and direct route to the Golden Corpus A/B case.
- DCT/fuel/PCM/sensor nodes now expose relevant observed samples and missing discriminators in context.
- Regression tests protect observed/candidate authority and the no-RPM-difference-equals-clutch-slip boundary.

## Truth correction
An inherited HPL source comment previously described the opaque six-byte counter as consistent with a one-microsecond timestamp. Rev146 removes that semantic implication. The counter is monotonic with a repeatable delta in the inspected artifacts, but its unit/meaning remains unverified.

## Boundaries
- sep2 controller/source labels are observations, not proof of physical faults.
- A/B windows are analysis navigation windows, not Ford-defined WOT or health limits.
- A/B statistics are derived and noncausal.
- H4 remains a hypothesis despite temporal overlap.
- DCT slip remains blocked without verified gear/shaft/clutch relationships.
- HPL structure remains artifact-specific; no universal HPL format or timestamp unit is claimed.
