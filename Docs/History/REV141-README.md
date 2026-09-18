# PredatorLab Rev141 — UX Convergence + Paddock Navigation

Rev141 continues the racetrack redesign by converging navigation rather than adding another isolated visual layer.

## Changes
- Promoted Systems Paddock into Home and More so users can enter the app by physical vehicle subsystem.
- Rebuilt More as the Paddock with clearer job-oriented names: Diagnostic Pit Board, Acquisition Bench, Forensic Command Center, Workshop Manual, Evidence Authority Review.
- Added reusable `PLTrackSection` for consistent pit-wall hierarchy across deep technical screens.
- Added `PLEvidenceLaneLegend` to keep Measured / Derived / Candidate / Unknown visually distinct wherever the racing UI could otherwise imply certainty.
- Added stable accessibility identifiers to primary Paddock routes for the next XCUI pass.
- Kept all technical/evidence boundaries intact; this revision does not promote missing research or invent live vehicle status.

## Validation in this environment
Changed Swift files were syntax parsed. Full Xcode/Swift 6 type checking, simulator rendering and XCUI remain Mac-side gates.
