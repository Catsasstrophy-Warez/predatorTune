# PredatorLab Rev136 Reconciliation Audit

## Baseline decision
`PredatorLab-Latest-AI-Handoff.zip` is the newest Mac-side source handoff and is used as the executable-source baseline for this reconciliation. The older Integration RC remains a donor/reference only.

## Verified in this reconciliation environment
- 326 Swift files were present in the incoming handoff before restoration of integration tests.
- The incoming handoff contains the Rev125–Rev134 production convergence surfaces sampled in this audit, including baseline designation, evidence authority/capability/threshold models, structured forensic evidence, Ghost Pull comparison, Best Next Measurement, calibration evidence bridge, performance/physical-validation plans, interactive timeline, Evidence/Why, Golden Corpus launch and Rev134 flagship case.
- `project.yml` currently specifies Swift 6.0, iOS 16 deployment, and live bundle identifier `com.daytradescanner.app`.
- The stale Rev85 validation scripts in the incoming handoff were repaired using the already-audited Integration RC versions. `Scripts/validate_rev85_ci.sh` now reports PASS; the optional fixture manifest is explicitly SKIP when absent.
- `build/`, `__pycache__`, and `.pyc` transfer artifacts were removed from the clean package.
- Ten Rev125–Rev134 integration unit-test source files missing from the incoming handoff were restored from the previous audited Integration RC.
- Static interaction inventory remains 186 sites from the prior full audit unless/until regenerated after a real rendered-XCUI pass.

## Critical reconciliation finding
The incoming handoff's `HANDOFF.md` reports 545 passing unit tests, but the ZIP did not contain the `PredatorLab/PredatorLabTests` source directory referenced by `project.yml`. Therefore the historical 545-test result cannot be reproduced from the incoming ZIP alone. The ten newer integration test files have been restored, but the larger Mac-side unit-test source corpus is still missing from this portable handoff.

This is a packaging/source-completeness problem, not evidence that the historical Mac Xcode run was false. The handoff also contained a previously built simulator `.app`, which has been removed from this clean source package.

## Documentation drift
`RELEASE_READINESS.md` still records an older 532-test checkpoint and the obsolete bundle identifier `com.predatorlab.PredatorLab`. Treat that document as historical until the next Mac run rewrites it from current results. `HANDOFF.md` and `project.yml` identify the live bundle as `com.daytradescanner.app`.

## Validation boundary
A parallel all-file `swiftc -parse` sweep was attempted but exceeded this environment's execution window, so no fresh full-tree parse PASS is claimed. Xcode, XCTest, XCUITest, simulator rendering, signing, MPVI4 hardware and physical GT500 execution are not available in this environment.

## Required Mac closure
1. Restore/copy the complete current Mac `PredatorLabTests` source corpus into this tree before calling it source-complete.
2. Run `xcodegen generate` from the root.
3. Build under Swift 6 with warnings treated as review items.
4. Execute the complete unit suite and record the exact executed-test count from `.xcresult`.
5. Execute all XCUI journeys, including the control-surface audit and Golden Corpus route, on fresh simulators.
6. Regenerate the interaction inventory from the final source and reconcile every interactive control with runtime coverage.
7. Run iPhone and iPad screenshot review.
8. Update `HANDOFF.md` and `RELEASE_READINESS.md` from that one run so there is one authoritative build/test count and bundle ID.
9. Resolve Xcode Accounts/signing and run the physical-device campaign.
10. Tag the resulting commit as the first Xcode-Verified Consolidated RC only after those gates pass.

## Truth label
This package is a **Consolidation Candidate**, not an Xcode-Verified RC. It is intentionally labeled this way because the portable handoff is missing most of the unit-test source corpus and this environment cannot execute Xcode.
