# Rev156 Full Project Review & Tidying Audit

## Scope

Rev156 is a non-destructive convergence/tidying pass over the Rev155 synchronized-forensic-cockpit tree. It does not claim a new Apple runtime result. The audit inspected repository topology, project generation inputs, CI gates, source/test inventory, large-file concentration, revision-tagged production naming, forensic-cockpit integration, resource integrity, signing portability, and current execution gaps.

## Measured repository inventory

- 363 Swift files total.
- 338 production Swift files outside the test roots.
- 25 Swift files in the configured unit/UI test roots.
- 92 statically discovered `func test…` XCTest/XCUI functions.
- 28,092 Swift source lines by `wc -l` across the tree at audit time.
- 121 production Swift filenames still contain a revision number.
- 53 Button declarations, 12 NavigationLink declarations, and 20 `.sheet` presentations were statically observed in `PredatorLab/Views`.
- 22 pre-Rev156 audit files existed under `Audit/`.

These are source-shape measurements, not runtime-discovered Xcode test counts.

## Validation actually executed in this environment

PASS:
- `Scripts/verify_fresh_clone.sh`
- Golden Corpus SHA-256 verification
- imported HPL artifact SHA-256 verification
- private-identifier scan
- generated/cache artifact scan
- dependency-lock policy
- test topology
- resource topology
- signing portability
- CI execution contract
- individual `swiftc -parse` over all 363 Swift files

NOT EXECUTED HERE:
- XcodeGen generation under the target macOS/Xcode toolchain
- Swift 6 whole-project type checking/linking in Xcode
- XCTest/XCUI runtime execution
- iPhone/iPad simulator launch and visual validation
- Release archive/signing
- physical iPhone installation/launch
- physical MPVI4/vehicle acquisition

## Strongest parts

1. The evidence firewall remains the project's strongest architectural feature. The synchronized cockpit composes context without turning relevance, temporal overlap, derived A/B deltas, or calibration relationships into causal claims.
2. `project.yml` is a compact canonical Apple-project definition with iPhone/iPad support, Swift 6, automatic signing, explicit Golden Corpus/HPL resources, and configured unit/UI test targets.
3. Fresh-clone integrity is unusually strong: fixture hashes, resource topology, test topology, cache rejection, signing portability, and CI contract checks are already automated.
4. The GT500 Digital Twin has evolved from a diagram into a bidirectional forensic navigation surface. This is the right product direction.
5. The Golden Corpus provides a deterministic real-session anchor for regression and UI journeys while retaining explicit noncausal semantics.

## Highest-risk findings

### P0 — Apple runtime proof is still the release blocker
Static parse and repository gates are healthy, but this exact tree has not been proven by the real Xcode build/test/sign/install chain. No additional feature breadth should outrank obtaining that evidence.

### P0 — Test-count lineage is inconsistent
Historical project notes cite much larger test counts, while this inspected tree contains 25 configured test Swift files and 92 statically named XCTest/XCUI functions. That does not prove tests were lost, because historical counts came from different merged lineages and static discovery methods, but it is a source-completeness warning. Reconcile against the last known Mac/Xcode-green trunk before declaring Rev155/156 authoritative.

### P1 — Revision-number production debt remains large
121 production Swift filenames contain revision tags. This makes ownership and canonicality harder to see and increases the chance of parallel implementations surviving indefinitely. Do not mass-rename. Establish canonical domain facades first, migrate call sites, then retire superseded revisions with tests.

### P1 — DataRepository remains an 801-line cross-domain object
It still owns persistence across vehicles, sessions, investigations, service records, annotations, evidence, imported logs, preferences, migrations, archives, and cache coordination. Split behind stable protocols/adapters only after a fresh Xcode-green checkpoint.

### P1 — Oversized domain/UI files concentrate change risk
Largest files include `MaintenanceAndLearning.swift` (884), `TechnicalLibraryModels.swift` (833), `DataRepository.swift` (801), `AnalysisModeView.swift` (680), `TechnicalQueryEngine.swift` (619), `CSVLogParser.swift` (614), `ComponentLibrarySeedData.swift` (610), and `ReferenceLibraryView.swift` (600). These should be decomposed by stable responsibility after runtime acceptance.

### P1 — Cockpit inspector duplication is becoming visible architecture debt
Evidence/Why, Twin Relevance, Synchronized Context, and Forensic Cockpit status are currently separate inspector concepts. Their models are useful, but the UI should converge into one inspector shell with sections rather than a vertical stack of semi-overlapping cards.

### P1 — UI automation needs to follow the product's real investigation lifecycle
The flagship journey should assert one shared cursor across timeline, event band, Twin highlight, Evidence/Why, hypothesis state, A/B context, calibration relationship, and Best Next Measurement. It should also test reverse navigation from Twin node → relevant telemetry/evidence.

### P2 — Root documentation had become revision archaeology
Historical revision README files were moved into `Docs/History/`. The repository root now gains a canonical `README.md` and `ARCHITECTURE.md` so a fresh clone explains the current product instead of forcing a developer to infer it from old revisions.

## Recommended execution order

1. Obtain one clean Xcode/Xcode Cloud build and capture exact compiler/linker/test failures.
2. Reconcile the configured test corpus against the last known Mac/Xcode-green source lineage.
3. Make the synchronized forensic cockpit the canonical Analyze route and remove parallel user-facing paths only after route/XCUI proof.
4. Replace the four overlapping inspector cards with one evidence-aware inspector container.
5. Draw admitted event bands and baseline/A/B overlays directly on the production timeline and bind them to the shared cursor.
6. Add reverse Twin navigation: component → relevant channels → evidence → hypotheses → missing measurements.
7. Add a machine-readable feature/coverage registry: feature ID, source owner, tests, platforms, evidence authority, last validated commit/build, known gaps.
8. Split DataRepository behind Vehicle, Session/Telemetry, Evidence, Investigation, Attachment, Preferences/Migration interfaces without changing persisted schemas.
9. Decompose the largest models/views/query/parser files and add focused regression tests around each extraction.
10. Run Release archive, signing, physical iPhone/iPad smoke tests, then start real MPVI4/vehicle validation as a separate evidence ladder.

## Product direction

PredatorLab should become deeper, not wider. The differentiator is not the number of labs. It is the ability to move one cursor through a real acquisition and have every layer of the car's evidence model answer the same question without pretending to know more than the data supports.
