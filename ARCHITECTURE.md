# PredatorLab architecture map

## Product surfaces

Home / Garage → Systems Paddock / GT500 Digital Twin → Analyze / Forensic Cockpit → Evidence / Hypotheses → Calibration Research → Research Command / Reference.

## Canonical forensic chain

1. **Acquisition**: imported CSV and explicitly experimental HPL research artifacts.
2. **Verification**: source identity, hashes, units/semantics, timing authority, provenance.
3. **Telemetry**: parsed channels, timeline, cursor, event segmentation, baseline/Golden Corpus context.
4. **Topology**: GT500 Digital Twin nodes and evidence attachments.
5. **Diagnostics**: hypotheses, support/contradiction/missing evidence, Best Next Measurement.
6. **Calibration**: read-only research relationships and experiment context until stronger authority exists.
7. **Forensics**: annotations, replay, A/B comparison, provenance, durable investigation state.
8. **Research**: factory/public-source applicability and explicit unresolved gaps.

## Authority firewall

- SHA-256 establishes byte identity, not semantic truth.
- Signatures establish authenticated signing-key possession over exact payload, not engineering truth.
- HPL decoding remains artifact-specific unless independently established otherwise.
- Configured scanner intervals are not measured per-channel acquisition rates.
- Temporal overlap is not causation.
- Digital Twin relevance is not component health/failure proof.
- Calibration-family relevance is not proof that a table caused an event.
- Simulator/XCUI success is not physical-vehicle validation.

## Architectural debt to retire

The repository still carries substantial revision-number naming in production Swift and several oversized files. Migration should be incremental and test-backed, not a mass rename. Stable destination domains are Acquisition, Evidence, Telemetry, Diagnostics, Calibration, Topology, Forensics, Research, Persistence, and UI.
