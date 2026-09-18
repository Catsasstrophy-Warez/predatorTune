# Locked Build Config Reference

This folder protects PredatorLab's live bundle identifier from being
silently overwritten when a new Xcode Machine Handoff zip is merged in.

## Locked value
- Bundle Identifier: `com.daytradescanner.app`
- Set via `bundleIdPrefix` and `PRODUCT_BUNDLE_IDENTIFIER` in the
  top-level `project.yml`

## Why this exists
The upstream "PredatorLab-RevXXX-Xcode-Machine-Handoff.zip" packages ship
with a DIFFERENT default bundle ID (`com.predatorlab.PredatorLab`) in
their own project.yml. Extracting a new handoff zip directly over this
PREDATORMVP folder will overwrite project.yml and silently revert the
bundle identifier.

## Rule
NEVER extract a new handoff zip directly into this folder.

Instead:
1. Extract the new handoff zip to a SEPARATE folder.
2. Diff its project.yml against `_LOCKED-BuildConfig/project.yml.reference`.
3. Copy over only source/code changes (Views, Models, Services, etc.).
4. Keep this folder's project.yml (or re-apply the locked bundle ID
   settings) before running prepare_xcode.sh / regenerating the project.

## Quick check
Run this after any merge, before opening Xcode:

    diff _LOCKED-BuildConfig/project.yml.reference project.yml

If it shows a diff on bundleIdPrefix or PRODUCT_BUNDLE_IDENTIFIER,
the merge reverted the bundle ID — fix it before building.
