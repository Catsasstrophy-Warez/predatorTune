# PredatorLab Xcode Cloud Contract

`project.yml` is the structural source of truth. `ci_post_clone.sh` verifies fixture identity, installs XcodeGen when needed, and generates `PredatorLab.xcodeproj` before Xcode actions.

## Required repository inputs
- `PredatorLab/` production source
- `PredatorLab/PredatorLabTests/` and `PredatorLabTests/` unit tests
- `PredatorLabUITests/` UI tests
- `PredatorLab/Resources/Fixtures/` Golden Corpus plus SHA-256 manifest
- `PredatorLab/Resources/ImportedHPL/` admitted HPL artifacts plus SHA-256 manifest
- `project.yml`
- `ci_scripts/`
- `Scripts/`

No Swift package dependencies are declared today, so no `Package.resolved` is fabricated. If packages are added, commit Xcode's shared workspace `Package.resolved` and keep it out of `.gitignore`.

## Recommended workflows
1. PR Gate: Build + Analyze + unit tests.
2. Main Validation: Build + unit tests + XCUI on representative iPhone and iPad simulators.
3. Release: clean Build + Test + Analyze + Archive, then optional TestFlight distribution.

## Signing
The repository intentionally does not contain a personal `DEVELOPMENT_TEAM`. Xcode Cloud supplies the configured team. Local physical-device builds select the developer's team in Xcode/automatic signing.

## Initial onboarding caveat
The first Xcode Cloud product/workflow is configured from Xcode. Because this repository generates its `.xcodeproj` from XcodeGen, generate it locally before the first Cloud setup. The post-clone script regenerates it in Cloud. If Xcode Cloud product discovery for the connected repository requires the project file to exist in the checkout before post-clone execution, commit the generated `.xcodeproj` as a bootstrap artifact and enforce regeneration/diff checking in CI. Verify this once on the actual Apple-hosted workflow rather than assuming either behavior.

## Evidence boundary
A passing source/static audit is not an Xcode build. The release gate becomes authoritative only after Apple-hosted or local macOS Xcode Build/Test/Analyze/Archive actions succeed.
