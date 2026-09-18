#!/usr/bin/env bash
set -euo pipefail
root="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root"
fail=0
while IFS= read -r -d '' f; do echo "ERROR: forbidden temporary/scratch artifact: ${f#./}"; fail=1; done < <(find . -type f \( -name '*.tmp' -o -name '*.swp' -o -name '*~' -o -name '*.orig' \) -print0)
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  untracked=$(git ls-files --others --exclude-standard -- '*.swift' '*.py' '*.json' '*.xml' '*.hpl' '*.csv' || true)
  if [[ -n "$untracked" ]]; then echo "ERROR: untracked project/evidence files:"; echo "$untracked"; fail=1; fi
fi

# Cross-file top-level declaration collision guard. Nested declarations are intentionally ignored.
# Swift parse-only validation does not catch module-wide redeclarations.
if command -v python3 >/dev/null 2>&1; then
  if ! python3 "$root/Scripts/validate_duplicate_declarations_rev85.py"; then fail=1; fi
else
  echo "ERROR: python3 is required for duplicate-declaration validation"; fail=1
fi

exit "$fail"
