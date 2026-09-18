#!/usr/bin/env bash
set -euo pipefail
ROOT="${SRCROOT:-${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}}"
cd "$ROOT"

fail(){ echo "ERROR: $*" >&2; exit 1; }
required=(project.yml PredatorLab PredatorLab/PredatorLabTests PredatorLabTests PredatorLabUITests \
  PredatorLab/Resources/Fixtures/sep2_full_real_hptuners_export.csv \
  PredatorLab/Resources/Fixtures/FIXTURE-MANIFEST.sha256 \
  PredatorLab/Resources/ImportedHPL/ARTIFACT-MANIFEST.sha256 \
  Scripts/validate_rev85_ci.sh Tooling/XCODEGEN_VERSION Scripts/verify_tool_versions.sh Scripts/verify_ci_contract.sh Scripts/collect_ci_evidence.sh Scripts/archive_release_candidate.sh ci_scripts/ci_post_clone.sh ci_scripts/ci_pre_xcodebuild.sh ci_scripts/ci_post_xcodebuild.sh)
for p in "${required[@]}"; do [[ -e "$p" ]] || fail "required repository input missing: $p"; done

# Byte identity for all admitted binary/corpus fixtures.
(cd PredatorLab/Resources/Fixtures && shasum -a 256 -c FIXTURE-MANIFEST.sha256) || fail "Golden Corpus fixture mismatch"
(cd PredatorLab/Resources/ImportedHPL && shasum -a 256 -c ARTIFACT-MANIFEST.sha256) || fail "HPL artifact mismatch"

# No user/device identity in repository source paths or text.
private_token="1FA6P8SJX""N5501522"
if grep -RIl --exclude='*.hpl' --exclude='*.zip' --exclude='REPOSITORY-SHA256SUMS.txt' "$private_token" . >/dev/null 2>&1; then
  fail "private VIN remains in repository text"
fi
if find . -name "*$private_token*" -print -quit | grep -q .; then fail "private VIN remains in repository path"; fi

# Fresh source checkouts must not contain generated/cached state.
while IFS= read -r p; do [[ -z "$p" ]] || fail "generated/cache artifact present: $p"; done < <(
  find . \( -type d \( -name build -o -name .build -o -name DerivedData -o -name __pycache__ -o -name xcuserdata \) \
    -o -type f \( -name '*.pyc' -o -name '*.pyo' -o -name '.DS_Store' -o -name '*.xcuserstate' \) \) -print)

# Dependency lock contract. Do not fabricate Package.resolved when no package exists.
if grep -Eq '^[[:space:]]*packages:' project.yml; then
  find . -path '*/xcshareddata/swiftpm/Package.resolved' -type f -print -quit | grep -q . || fail "Swift packages declared but shared Package.resolved is missing"
fi

# project.yml must not bake a developer's Team ID into source control.
if grep -Eq '^[[:space:]]*DEVELOPMENT_TEAM:[[:space:]]*[A-Z0-9]+' project.yml; then fail "hard-coded DEVELOPMENT_TEAM found"; fi

./Scripts/verify_test_topology.py
./Scripts/verify_resource_topology.py
./Scripts/verify_ci_contract.sh

# Xcode Cloud scripts must be executable.
for s in ci_scripts/*.sh Scripts/*.sh; do [[ -x "$s" ]] || fail "script is not executable: $s"; done

echo "Fresh-clone contract: PASS"
echo "Golden Corpus: verified"
echo "Imported HPL artifacts: verified"
echo "Private VIN scan: PASS"
echo "Generated/cache artifact scan: PASS"
echo "Dependency lock contract: PASS"
echo "Test topology: PASS"
echo "Resource topology: PASS"
echo "Signing portability: PASS"
