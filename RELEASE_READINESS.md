# PredatorLab Release Readiness

> **Status as of Rev162.** This file previously recorded a stale "532 tests" /
> `com.predatorlab.PredatorLab` checkpoint that predated a bundle-id and test-suite
> change; `Docs/History/RevisionAudits/REV136-RECONCILIATION.md` flagged that drift.
> The numbers below are the current, correct values — update them together
> whenever the test suite or bundle identifier changes again, rather than letting
> this file drift out of sync a second time.

## Verified in the current workspace

- Debug simulator build succeeds with XcodeGen-generated project.
- Unsigned Release archive succeeds for `generic/platform=iOS`.
- Current unit/UI test corpus: 98 `func test...` cases across `PredatorLabTests/`,
  `PredatorLabUITests/`, and `PredatorLab/PredatorLabTests/` (per `project.yml`'s
  `sources:` wiring). Pass/fail status has **not** been verified in this
  environment — there is no Xcode, xcodebuild, XcodeGen output, or iOS Simulator
  available here, so this only confirms the tests exist and reference real
  symbols, not that they currently pass. Confirm with `xcodebuild test` on macOS
  before treating this as release-ready.
- Overhaul regression coverage includes technical seed domains, topology identity, calibration records, RFC-4180 multiline CSV, empty fields, and a 5,000-row performance fixture.
- iPhone 17 Pro Max compact UI flow passes through onboarding, primary tabs, Maintenance, R04, Tune, Forensic Workstation, Calibration, and Topology.
- iPad simulator launch contract passes.
- iPhone and iPad orientation declarations are present.
- App version is `1.0.0` / build `1`.

## Required before physical installation

1. Add the Apple Developer account in Xcode Settings → Accounts.
2. Select the PredatorLab development team for bundle identifier `com.daytradescanner.app`
   (this is a carried-over identifier from an earlier, unrelated project — consider
   renaming it to something under a `com.predatorlab.*`-style prefix before shipping).
3. Enable automatic signing or provide a matching development provisioning profile.
4. Build to the connected iPhone 17 Pro Max.
5. Verify onboarding, CSV import, file access, persistence, export, Dynamic Type, VoiceOver order, and Garage hit targets on-device.

## Explicit product boundaries

PredatorLab remains an evidence and workflow tool. It does not claim direct MPVI4 communication, calibration flashing, universal OEM strategy semantics, or vehicle-safety certification without separately verified authority and hardware evidence.
