# Rev161 Full Read, Simulation & Test Audit

## Scope
A complete source-tree/static-validation pass over the Rev160 lineage, plus an independent behavioral simulation of the frozen sep2 Golden Corpus and a UI-test drift repair pass. This environment is Linux/Swift and does not contain Xcode, xcodebuild, XcodeGen, iOS Simulator, or a physical Apple device.

## Measured inventory
- 364 production Swift files before this audit's documentation/script additions.
- 373 Swift files across production + configured XCTest/XCUI roots.
- 28,163 production Swift lines.
- 94 View Swift files; 216 Service Swift files.
- 135 revision-tagged production Swift filenames remain as migration debt.
- 98 statically named XCTest/XCUI test functions after Rev160 additions.
- 57 Button declarations, 65 NavigationLink occurrences, 20 sheets, 14 toggles, 26 pickers, 4 file importers, 2 sliders (rough lexical inventory, not runtime coverage).
- 89 accessibilityIdentifier occurrences in production source.

## Executed validation
PASS: fresh-clone contract; Golden Corpus and imported-HPL hashes; private-identifier scan; generated/cache scan; dependency policy; test topology; resource topology; signing portability; CI execution contract; Rev85 duplicate-declaration/local-integrity gate; repository manifest before audit edits; feature coverage registry (9 features); full per-file Swift syntax parse 373/373; no TODO/FIXME/fatalError/preconditionFailure/try!/as!/print/debugPrint in production Swift; independent Golden Corpus behavioral simulation.

## Golden Corpus simulation
The independent Python mirror uses the exact admitted analysis parameters encoded in `GT500EpisodeThresholdSetRev131.analysisDefaults` and the segmentation structure in `ParsedLogForensicBridgeRev125`.

Observed fixture invariants:
- 26,943 data rows, 61 columns.
- Offset 2.268 to 1122.728 s, span 1120.460 s.
- median exported-row delta 0.040 s. This is not a per-channel polling-rate claim.
- marks: source activity 2,087; throttle disagreement 148; thermal context 2,805; acceleration 3; high demand 29.
- episodes after 0.30 s navigation merge: source activity 407; throttle disagreement 61; thermal context 5; acceleration 3; high demand 2.
- high-demand navigation windows reproduce exactly at 5.578–6.418 s (21 marks) and 970.854–971.134 s (8 marks).

Boundary: 60% pedal, 50% throttle, 5° disagreement, 300 rpm/exported-row delta, 0.30 s merge gap, and 115°F IAT2 are analysis/navigation parameters. They are not Ford WOT, fault, controller timing, protection, or safety definitions.

## Defects found and repaired
### UI automation drift
Several XCUI tests still targeted pre-racetrack visible labels and navigation: `More` navigation title instead of `Paddock`, `Reference Library` instead of `more.reference`/Workshop Manual route, direct Settings tab assumptions instead of More/Paddock, `Forensic Workstation (Rev85)` instead of the production-facing name, and obsolete Tune research labels. These were updated to the current Rev160 navigation/identifiers. This was a real regression risk: source parsing could be green while runtime XCUI would fail immediately on stale selectors.

### User-facing revision leakage
Two HPL research views still displayed Rev78/Rev79 implementation numbers in explanatory copy. Those were replaced with product-facing PredatorLab wording.

### Stale HPL capability statement
The MPVI4 evidence screen said HPT/HPL binary decoding was wholly unimplemented, which no longer reflected the artifact-specific experimental decoder. It now states the narrower truth: universal/proprietary HPL decoding remains unimplemented, while artifact-specific research decoding exists and remains experimental/evidence-bounded.

## Architecture findings
The evidence firewall remains coherent. Rev160's acquisition-plan state machine correctly distinguishes captured from semantically verified/satisfied evidence. The comparison contract explicitly remains derived/noncausal. The guided Golden Corpus workflow teaches investigation rather than button memorization.

The principal architecture debt is now consolidation rather than missing capability. DataRepository is still 707 lines. Other largest files: MaintenanceAndLearning 884; TechnicalLibraryModels 833; AnalysisModeView 682; ComponentLibrarySeedData 610; ReferenceLibraryView 600; CSVLogParser 506; ForensicLogView 494; R04InvestigationEngine 491; SessionModels 478; TechnicalQueryEngine 447. The 135 revision-tagged production filenames are substantial migration debt.

## Runtime gaps that remain unproven
- Swift 6 whole-module type checking/linking in Xcode.
- Runtime XCTest discovery and execution of the 98 statically named tests.
- XCUI execution on current iPhone and iPad simulators.
- Actual visual rendering, Dynamic Type, VoiceOver order, hit targets, clipping, rotation and chart performance.
- Release archive, automatic signing, physical iPhone/iPad install/launch.
- Direct MPVI4 communications and real vehicle acquisition.
- Vehicle validation of DCT/fuel/calibration hypotheses.

## Priority recommendations
1. Run this exact revision on Apple tooling before more feature expansion.
2. Execute all 98 current XCTest/XCUI functions and preserve `.xcresult` bundles/screenshots.
3. Make iPad XCUI a real journey rather than launch-only early returns.
4. Add runtime tests for Rev160 Acquisition Plan state transitions, hypothesis falsification ledger, Compare alignment modes, and Golden Corpus guided workflow navigation.
5. Expand the feature coverage registry from 9 entries to every production-facing feature.
6. Continue DataRepository domain extraction only after Xcode green.
7. Consolidate revision-tagged production types behind stable canonical names and move superseded implementations to history/quarantine.
8. Add accessibility IDs to every primary route and every state-changing control, then audit VoiceOver labels/hints/order on-device.
9. Profile the synchronized recorder at 100k/1M/5M samples and 10/30 channels on real Apple hardware.
10. Treat physical GT500/MPVI4 validation as a separate evidence campaign, never as a consequence of software test success.
