# PredatorLab

PredatorLab is a Swift/SwiftUI GT500 forensic tuning and diagnostics workbench built around an evidence-first workflow:

**Acquire → Verify → Investigate → Experiment → Validate**

The product's central surface is the synchronized forensic cockpit. A shared cursor coordinates telemetry, admitted event windows, GT500 Digital Twin relevance, Evidence/Why, hypothesis context, Golden Corpus A/B context, calibration research relationships, and Best Next Measurement without promoting correlation into causation.

## Current repository truth

- Canonical project definition: `project.yml` (XcodeGen)
- Swift language mode: 6.0
- Deployment target: iOS 16.0
- Device families: iPhone + iPad
- App bundle identifier: `com.daytradescanner.app`
- Golden Corpus fixture: `PredatorLab/Resources/Fixtures/sep2_full_real_hptuners_export.csv`
- Xcode Cloud lifecycle scripts: `ci_scripts/`
- Apple execution helpers: `Scripts/`
- Current engineering audit: `Audit/REV161-FULL-READ-SIMULATION-TEST-AUDIT.md`

## Evidence boundaries

PredatorLab distinguishes measured, derived, candidate, unknown/research-required, source-verified, and vehicle-validated information. A build/test pass proves software execution for a particular source/toolchain configuration. It does not promote an automotive hypothesis, inferred HPL structure, calibration relationship, or simulator observation into vehicle-validated truth.

## Fresh-clone gate

Run:

```sh
./Scripts/verify_fresh_clone.sh
```

On macOS with Xcode/XcodeGen available, continue with the Apple execution scripts documented in `XCODE-CLOUD.md` and `XCODE-CLOUD-WORKFLOWS.md`.

## Current priority

Do not expand breadth merely to increase feature count. The next engineering objective is convergence and execution proof: make the synchronized cockpit the canonical investigation path, reduce revision-tagged production debt, split oversized persistence/query surfaces behind stable domain interfaces, expand end-to-end XCUI coverage, and obtain a fresh Xcode/Xcode Cloud + physical-device acceptance result.

## Current convergence state

Rev157–Rev161 converged the product around one synchronized investigation path: unified Investigation Inspector, cursor/event-band telemetry, bidirectional Digital Twin routing, typed acquisition plans, hypothesis evidence/falsification ledgers, explicit comparison authority, guided Golden Corpus investigation, professional cockpit UI, and a full static/simulation audit. Historical revision notes are retained under `Docs/History/RevisionAudits/`; the current audit remains in `Audit/`.
