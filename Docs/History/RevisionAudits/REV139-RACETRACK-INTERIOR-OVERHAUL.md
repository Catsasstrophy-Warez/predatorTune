# Rev139 Racetrack Interior Overhaul

Rev139 extends the Rev138 navigation redesign into the primary working surfaces.

## Production UI changes
- Garage now opens with a visual Garage Bay track header before vehicle/session controls.
- Analyze now opens as a Data Pit Wall while preserving Sessions/Logs, import, events, forensic log and diagnostics behavior.
- Tune was rebuilt from a long List into a visual Calibration Pit Wall with Tune Readiness, Race Engineer Workflow, Test Bench, Research Command and Evidence Boundary.
- Research Command was rebuilt from a dense List into a visual research dashboard with Evidence Ladder, highest-leverage target cards, Coverage Map, Ford Workshop lane and HP Tuners/Data lane.
- Added reusable PLTrackHeader and PLPitRoute components so the racetrack hierarchy can propagate consistently instead of being hard-coded screen by screen.
- Removed the user-facing “Forensic Workstation (Rev85)” label from the Tune route. Revision identifiers remain implementation/provenance details.

## Truth boundaries
The redesign does not manufacture connected-device status, DTC state, weather, boost, tire pressure, lap times, vehicle validation, controller definitions or research completion. Existing evidence/readiness engines remain authoritative.

## Validation performed here
Changed Swift sources pass `swiftc -parse`. The project local static CI script was executed after the changes. Full Swift type checking, Xcode build, XCTest, XCUITest, simulator screenshots and physical-device validation remain Mac/Xcode gates.
