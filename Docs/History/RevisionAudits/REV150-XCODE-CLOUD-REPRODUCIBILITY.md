# Rev150 — Xcode Cloud Reproducibility Contract

PredatorLab Rev150 is organized so a clean Git checkout contains the complete build/test inputs rather than transferred build products.

## Repository inputs
- Application source under `PredatorLab/`
- Unit tests under `PredatorLab/PredatorLabTests/` and `PredatorLabTests/`
- XCUI tests under `PredatorLabUITests/`
- `project.yml` as the XcodeGen source of project structure
- `ci_scripts/` for Xcode Cloud bootstrap and validation
- Golden Corpus fixture: `PredatorLab/Resources/Fixtures/sep2_full_real_hptuners_export.csv`
- Golden Corpus SHA-256: `8952bf30a0577d5c2ba57936cacd521efc0c13df7ef9e114aa2b9439ff70976e`
- Imported HPL research fixtures under `PredatorLab/Resources/ImportedHPL/`

## Package.resolved
The current `project.yml` declares no Swift package dependencies, so there is no applicable `Package.resolved` to commit in this revision. If a Swift package is introduced, commit Xcode's shared workspace `Package.resolved` and never ignore it.

## Clean-checkout policy
The repository excludes build products, DerivedData, Swift/Python caches, user-specific Xcode state, editor caches, temporary files, and OS metadata. `Scripts/verify_fresh_clone.sh` fails when those artifacts are present and verifies the Golden Corpus byte identity.

## Xcode Cloud bootstrap
`ci_scripts/ci_post_clone.sh` installs XcodeGen with Homebrew when necessary and regenerates `PredatorLab.xcodeproj` from `project.yml`. `ci_pre_xcodebuild.sh` executes the fresh-clone contract and the existing Rev85 static validation before Xcode builds/tests.

## Important onboarding detail
Xcode Cloud initially needs an Xcode project/workspace and shared scheme to select a product during onboarding. On the first Mac bootstrap, run XcodeGen, open the generated project, confirm the shared PredatorLab scheme, and commit the generated `PredatorLab.xcodeproj` if Xcode Cloud cannot complete initial product discovery from the repository without it. After onboarding, `project.yml` remains the structural source of truth and CI regenerates the project after clone.

## Reproducibility definition
A revision is reproducible when a fresh checkout plus the documented toolchain can regenerate the Xcode project, verify fixture hashes, compile the same source/test graph, and run the same deterministic test inputs without relying on transferred `build/`, DerivedData, caches, or files outside the repository.
