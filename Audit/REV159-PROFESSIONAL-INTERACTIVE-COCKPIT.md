# Rev159 Professional Interactive Cockpit

## Goal
Turn the Rev158 visual chassis into a more professional and intuitive forensic instrument without changing evidence authority.

## Implemented
- Rebuilt the core forensic timeline into a high-contrast recorder surface with instantaneous cursor value, observed-authority badge, grid, optional evidence bands, cursor marker and drag-to-scrub affordance.
- Added a persistent forensic context bar so timestamp/workspace survive navigation.
- Numbered the Investigation Inspector as an explicit reasoning sequence: Evidence/Event → Physical Context → Hypothesis → Calibration → Best Next Measurement → Authority Boundary.
- Added reusable context and inspector primitives to the visual design system.
- Preserved semantic-neutral telemetry and all existing causality/vehicle-validation firewalls.

## Professional UX doctrine
1. One timestamp everywhere.
2. One primary action per surface.
3. Current value before decoration.
4. Evidence authority stays visible.
5. Missing evidence becomes an actionable measurement.
6. Twin relevance is navigation, never a health verdict.
7. A/B differences remain derived and noncausal unless separately validated.

## Remaining runtime gate
This revision requires a real Xcode iPhone/iPad render pass for Dynamic Type, VoiceOver order, hit targets, clipping, chart performance and pixel-level spacing. Source parse is not runtime proof.
