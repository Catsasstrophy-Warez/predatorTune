# PredatorLab Xcode Cloud execution contract

## Workflow A — PR Gate
Run the reproducibility gate, XcodeGen topology verification, Build, Analyze, and unit tests. Treat any missing fixture, orphaned XCTest, generated/cache residue, hard-coded signing team, or resource-topology drift as a merge blocker.

## Workflow B — Main / Golden Corpus
Run Build + unit tests + XCUI on a currently available iPhone and iPad simulator. Preserve `.xcresult` artifacts and Golden Corpus screenshots. The deterministic corpus must remain byte-identical before tests begin. UI success is execution evidence only; it does not promote Candidate/Derived engineering claims.

## Workflow C — Release Candidate
Manual/tag trigger. Run a clean Build, Test, Analyze and Archive using the configured Apple team. Preserve archive metadata, toolchain provenance, result bundles and commit identity. TestFlight distribution remains explicit.

## Execution evidence packet
Every Apple-hosted run should be traceable to Git commit, workflow/build ID, Xcode version, Swift version, XcodeGen version, simulator/device family, result bundle and archive identity. `Scripts/capture_toolchain_provenance.sh` creates the machine-readable text nucleus for this packet.

## Simulator policy
Never pin CI correctness to a marketing device name. `Scripts/select_ci_simulator.py` discovers available runtimes and chooses a current iPhone or iPad. The exact selected UDID/runtime belongs in CI logs/result bundles.

## Resource policy
`Scripts/verify_resource_topology.py` requires the Golden Corpus and imported HPL resource roots to remain declared in `project.yml` and requires exactly one canonical sep2 fixture. `Scripts/verify_generated_project.sh` additionally verifies that XcodeGen carries the corpus into the generated project.

## Authority firewall
Cloud-green means the exact source revision built/tested under the recorded Apple toolchain. It does not make telemetry causal, make a research relationship calibration truth, validate a GT500 threshold, decode unknown HPL bytes, or constitute physical-vehicle validation.

## First Apple-hosted proof
The first workflow must prove project/scheme discovery, XcodeGen availability, Swift 6 whole-module compile, link, resource inclusion, XCTest discovery/execution, XCUI launch, Golden Corpus bundle access, iPhone/iPad rendering, archive signing and artifact retention. Historical local test counts must not be reported as Cloud results.

## Rev154 deterministic execution additions
The expected XcodeGen release is recorded in `Tooling/XCODEGEN_VERSION`; generator drift is a hard failure. The full local Apple gate uses `build-for-testing` followed by `test-without-building` with isolated DerivedData for each iPhone/iPad family. `Scripts/collect_ci_evidence.sh` creates an execution-evidence packet, while `Scripts/archive_release_candidate.sh` is the explicit signed generic-device archive gate. Archive success is not device-install success.
