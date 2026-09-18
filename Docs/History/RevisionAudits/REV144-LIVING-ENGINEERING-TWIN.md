# Rev144 — Living GT500 Engineering Twin

Rev144 promotes the Rev143 subsystem twin into a component-level investigation browser.

## Added
- Selectable component/logical nodes for all eight GT500 Twin systems.
- Lateral evidence questions: Where is it? What connects to it? What should I measure? What did the log measure? What DTC evidence exists? What is still missing?
- Direct Diagnose / Reference / Research routes from the selected node.
- Explicit evidence-state labels on every node.
- Production GT500 vs TC-298B control-pack quarantine retained.
- DCT truth boundaries retained: RPM difference is not automatically clutch slip; the procedure-specific 3.0 bar evidence is not a universal operating threshold.
- Sensor Workshop Matrix and Scanner Identity become explicit structured acquisition nodes.

## Validation in this environment
Changed Swift production/test sources pass `swiftc -parse`. Full Xcode/Swift 6 type checking, XCTest/XCUI and rendered simulator/device validation remain Mac gates.
