#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f REPOSITORY-SHA256SUMS.txt ]] || { echo 'ERROR: repository manifest missing' >&2; exit 1; }
# Manifest deliberately excludes itself so verification is stable.
shasum -a 256 -c REPOSITORY-SHA256SUMS.txt
echo 'Repository manifest: PASS'
