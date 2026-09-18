# PredatorLab Rev138 — Racetrack UI Overhaul

## Product direction
PredatorLab now opens into a task-first race-track cockpit instead of dropping directly into a dense technical workspace. The redesign is deliberately visual without weakening the evidence doctrine.

Primary navigation is now: Home / Garage / Analyze / Tune / More. Deep tools live in the Paddock-style More hub so Reference, Research, acquisition labs, diagnostics, track/telemetry tools, app review, and Settings remain easy to find without overcrowding the bottom bar.

## New production surfaces
- `RaceTrackHomeView.swift`: visual hero, vehicle/session/phase status, Garage/Diagnose/Analyze/Tune route cards, Pit Lane quick actions, subsystem explorer, evidence boundary.
- `MoreHubView.swift`: grouped Diagnose & Test, Research & Reference, Track & Data, and App navigation.
- Global screen background now uses a restrained circuit/grid treatment with boost-blue + ignition accents.
- Main TabView now has five task-oriented destinations and maps legacy Reference/Settings selections into More.
- New installations default to Home; existing persisted navigation values remain understood.

## UX doctrine
- Five primary destinations only.
- Task language before internal revision language.
- Deep research remains reachable but no longer competes with everyday workflows.
- Visual race-track language is decorative only. Technical state colors retain semantic meaning.
- No generated mockup telemetry, connection state, DTC state, weather, fuel, tire pressure, track records, or controller identity was copied into production as if measured.
- No Ford/Shelby branding or trademark artwork was added to production assets.

## Regression work
The two major XCUI journeys were updated for the Home + More information architecture. Existing Garage, Analyze, Tune, Forensic Workstation, Reference and Settings flows remain in the journey, but Reference/Settings are entered through More.

## Validation in this environment
- Changed production Swift files: `swiftc -parse` PASS.
- Updated XCUI sources: `swiftc -parse` PASS.
- Rev85 local static CI: PASS.
- Xcode/Simulator/XCUITest execution remains a Mac/Xcode gate and is not claimed here.

## Next runtime pass
1. Generate/open Xcode project.
2. Build with Swift 6.
3. Run unit tests.
4. Run updated primary XCUI journey on compact iPhone.
5. Run Golden Corpus journey.
6. Review Home and More screenshots at standard + large Dynamic Type.
7. Run iPad and tune the regular-width layout into a persistent sidebar/dashboard where useful.
8. Audit every legacy deep screen for the new visual hierarchy and remove revision-number labels from user-facing names where provenance does not require them.
