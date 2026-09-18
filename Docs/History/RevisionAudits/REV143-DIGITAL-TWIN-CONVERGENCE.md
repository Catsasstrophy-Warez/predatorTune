# Rev143 Digital Twin Convergence

Rev143 makes the physical GT500 the primary technical navigation object.

## Added
- Interactive GT500 System Twin with eight primary system families.
- System-specific evidence lanes for engine, production fuel, PCM/TCM, TR-9070 DCT, MagneRide/VDM, ABS/EPAS, wiring and sensors.
- Vehicle-map selection synchronized with system detail.
- Direct routes from system context into Workshop Manual and Research Command.
- Truth firewall: navigation never represents live health, diagnosis or completeness.
- Explicit production-GT500 vs control-pack boundary in the fuel lane.
- Regression tests for system coverage and cross-domain boundaries.

## UX convergence
Garage -> Systems Paddock -> GT500 System Twin -> system evidence lanes -> Workshop Manual / Research Command.

## Validation boundary
Changed Swift files syntax-parse successfully in this environment. Full Swift 6 type checking, XCTest/XCUI, simulator rendering, Dynamic Type, iPad resizing and physical-device validation require Xcode on macOS.
