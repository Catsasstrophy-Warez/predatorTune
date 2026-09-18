#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fail(){ echo "ERROR: $*" >&2; exit 1; }
[[ -s Tooling/XCODEGEN_VERSION ]] || fail 'missing pinned XcodeGen version'
grep -q 'build-for-testing' Scripts/ci.sh || fail 'CI does not separate build-for-testing'
grep -q 'test-without-building' Scripts/ci.sh || fail 'CI does not use test-without-building'
[[ -x Scripts/collect_ci_evidence.sh ]] || fail 'CI evidence collector missing'
[[ -x Scripts/archive_release_candidate.sh ]] || fail 'release archive gate missing'
for f in ci_scripts/ci_post_clone.sh ci_scripts/ci_pre_xcodebuild.sh ci_scripts/ci_post_xcodebuild.sh; do [[ -x "$f" ]] || fail "$f not executable"; done
echo 'CI execution contract: PASS'
