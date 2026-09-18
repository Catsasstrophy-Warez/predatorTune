# PredatorLab Rev154 — Deterministic Apple Execution Evidence

Rev154 deepens Rev153 around the remaining real execution gates.

## New execution controls
- Pins XcodeGen expectation to `Tooling/XCODEGEN_VERSION` (2.46.0) and fails on version drift.
- Separates `build-for-testing` from `test-without-building` for iPhone and iPad simulator lanes.
- Uses isolated DerivedData per device family.
- Produces separate build/test `.xcresult` bundles.
- Creates a CI evidence packet with toolchain, commit/build identity, simulator inventory, xcresult summaries where supported, and SHA-256 hashes.
- Adds a signed Release archive gate for generic iOS device builds.
- Adds a CI-contract validator so later edits cannot silently remove the execution architecture.

## Truth boundary
Static validation here does not establish Xcode compilation, XCTest/XCUI execution, signing, archive success, device installation, MPVI4 communication, or vehicle validation. Those remain Apple-toolchain/physical gates.

## XcodeGen bootstrap note
The repository remains `project.yml` authoritative. The expected generator is pinned to 2.46.0. If a future Homebrew formula moves past that version, CI deliberately fails rather than silently regenerating the Xcode project with a different generator. Update the pin only in a reviewed tooling change.
