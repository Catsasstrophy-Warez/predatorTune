# PredatorLab fresh-clone bootstrap

On a clean Mac with Xcode installed:

```sh
git clone <repository-url> PredatorLab
cd PredatorLab
brew install xcodegen   # only if xcodegen is not already installed
xcodegen generate --spec project.yml
./Scripts/verify_fresh_clone.sh
open PredatorLab.xcodeproj
```

Then build/test the shared `PredatorLab` scheme in Xcode. For local command-line CI, run `./Scripts/ci.sh`.

Xcode Cloud runs `ci_scripts/ci_post_clone.sh` after checkout to install XcodeGen if needed, regenerate the project, and verify the repository contract before the Xcode action begins.

The current project has no declared Swift Package Manager dependencies, so no `Package.resolved` exists in this revision. If packages are added, commit the shared workspace `Package.resolved`; do not add it to `.gitignore`.

## Deep execution gate
On macOS with Xcode installed, run `./Scripts/ci.sh`. It dynamically selects an available iPhone simulator instead of assuming a particular simulator runtime. For Cloud workflow design see `XCODE-CLOUD-WORKFLOWS.md`.
