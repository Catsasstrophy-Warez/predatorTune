// PredatorLab/Services/R04InvestigationEngine.swift
// Insufficient Fuel Flow hypothesis investigation and evidence synthesis

import Foundation
import Combine

class R04InvestigationEngine: ObservableObject {

    /// Seed all eight R04 hypotheses with evidence framework
    static func seedAllHypotheses() -> [DiagnosticHypothesis] {
        return [
            h1aPhysicalInjectorCapacity(),
            h1bInjectionWindowLimit(),
            h2PumpPressureLimit(),
            h3ModeledFuelFlowLimit(),
            h4DCTShiftTransient(),
            h5PIDIdentityError(),
            h6SecondaryProtection(),
            h7PressureStrategy()
        ]
    }

    // MARK: - H1A: Physical Injector-Flow Capacity

    static func h1aPhysicalInjectorCapacity() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h1aInjectorCapacity,
            title: "Physical Injector-Flow Capacity Limit",
            description: """
            The stock EV14 injectors (Ford Performance 55 lb/hr @ 40 psi) are physically exhausted at peak demand.
            Total mass-flow cannot be delivered even with full pressure and pulse width.
            """,
            supportingEvidence: [
                "Injector demand approaches or equals injector rated flow at event",
                "Fuel pressure remains healthy (>90 psi) despite protection",
                "Event occurs consistently at similar torque/RPM (repeatable saturation point)",
                "Lambda begins to lag command as injector demand peaks",
                "No system intervention appears before protection triggers"
            ],
            contradictingEvidence: [
                "Injector demand remains significantly below rated capacity",
                "Event occurs without elevated injector demand",
                "Pressure collapse occurs before injector demand peaks"
            ],
            requiredEvidence: [
                "Stock injector specification: 55 lb/hr @ 40 psi",
                "Calculated injector demand (fuel mass per cycle)",
                "Injector pulse width at event",
                "Fuel pressure at event",
                "Repeated event confirmation at different conditions"
            ],
            confidence: .c1,
            isPlausible: true,
            nextMeasurements: [
                "Calculate mass-flow demand: (scheduled torque * BSFC @ condition) ÷ lambda",
                "Compare against injector spec at operating pressure",
                "Verify injector flow rate with new injector characterization",
                "Test with ID1050-XDS or similar higher-flow injector (hypothesis disprove/support)"
            ]
        )
    }

    // MARK: - H1B: Injection-Window Limit (PRIORITY #1)

    static func h1bInjectionWindowLimit() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h1bInjectionWindow,
            title: "Usable Injector Window / Maximum PW Limit",
            description: """
            The PCM's available injection time (window) per cylinder event shrinks with RPM.
            At high RPM, the time between cylinder firings becomes so short that the requested
            pulse width cannot be delivered within the available window, even with adequate pressure.
            """,
            supportingEvidence: [
                "Actual injector PW climbs toward maximum available PW before flag",
                "Lines converge (PW margin shrinks) as event timestamp approaches",
                "Flag appears exactly when PW reaches/exceeds maximum",
                "Event is RPM-dependent (occurs at higher RPM where window shrinks)",
                "Fuel pressure remains controlled throughout",
                "Lambda response remains reasonable despite flag"
            ],
            contradictingEvidence: [
                "Actual PW remains well below maximum (>20% margin) when flag appears",
                "Flag appears without PW saturation tendency",
                "Event has no RPM/load dependency"
            ],
            requiredEvidence: [
                "Injector Actual Pulse Width (critical)",
                "Maximum Available Injector Pulse Width OR Injection Window Duration (CRITICAL discriminator)",
                "Fuel Pressure Command and Actual",
                "Pump Duty Actual",
                "Commanded and Measured Lambda",
                "RPM and Load at event",
                "Torque Source enum at event onset",
                "Multiple Insufficient Fuel Flow events with timestamps"
            ],
            confidence: .c2,
            isPlausible: true,
            nextMeasurements: [
                "Generate 'Killer Comparison Chart': Actual PW (blue), Maximum Available PW (red), IFF flag (orange overlay)",
                "If lines converge at flag onset → H1B signature confirmed",
                "Plot injection window vs RPM curve from PCM data",
                "Document exact RPM/load convergence point for each event"
            ]
        )
    }

    // MARK: - H2: Pump / Pressure Limitation

    static func h2PumpPressureLimit() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h2PumpPressure,
            title: "Fuel Pump / Pressure Command Limitation",
            description: """
            The fuel pump cannot sustain the commanded pressure at high fuel demand.
            Actual pressure falls away from desired, pump duty maxes out, lambda trends lean.
            """,
            supportingEvidence: [
                "Desired fuel pressure remains high (90+ psi command)",
                "Actual pressure departs materially from command (gap >3-5 psi)",
                "Pump duty rises toward or reaches 100%",
                "Lambda trends lean relative to commanded value",
                "Event occurs at high-load conditions when pump is stressed"
            ],
            contradictingEvidence: [
                "Actual pressure tracks desired throughout event (within ±2 psi)",
                "Pump duty remains below 90%",
                "Lambda remains on-target despite flag"
            ],
            requiredEvidence: [
                "Fuel Pressure Command",
                "Fuel Pressure Actual (direct sensor measurement)",
                "Pump Duty Actual",
                "Pump Duty Command (if available)",
                "Commanded Lambda",
                "Measured Lambda",
                "Load and RPM at event"
            ],
            confidence: .c1,
            isPlausible: true,
            nextMeasurements: [
                "Plot Pressure Command vs Actual on same timeline",
                "Calculate RMS(Actual - Command) at event window",
                "Verify pump voltage/current (oscilloscope if available)",
                "Check fuel filter restriction",
                "Test with aftermarket pump if pressure loss confirmed"
            ]
        )
    }

    // MARK: - H3: Modeled Fuel-Flow / Calculated Capacity Limit

    static func h3ModeledFuelFlowLimit() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h3ModeledFlowLimit,
            title: "Modeled / Calculated Fuel-Flow Limit",
            description: """
            The PCM calculates a maximum available fuel flow based on a threshold (load, RPM, pressure).
            Physical fuel delivery remains healthy, but the modeled limit triggers protection.
            The threshold may be too conservative.
            """,
            supportingEvidence: [
                "Pressure tracks command throughout event",
                "Lambda tracks command throughout event",
                "Injector demand remains credible",
                "Protection appears at repeatable modeled threshold (same load/RPM/temp)",
                "No actual fuel-system constraint evident"
            ],
            contradictingEvidence: [
                "Threshold changes unpredictably",
                "Physical constraint becomes evident (pressure collapse, lean condition)"
            ],
            requiredEvidence: [
                "Fuel Pressure Command and Actual (no deviation)",
                "Commanded and Measured Lambda (agreement)",
                "Scheduled Load",
                "Calculated Fuel Flow Demand (if available)",
                "Multiple events at identical conditions (repeatable boundary)"
            ],
            confidence: .c1,
            isPlausible: true,
            nextMeasurements: [
                "Log multiple events at same load/RPM; verify threshold reproducibility",
                "Check for fuel-flow calculation table in TC-298B calibration",
                "Compare threshold against known GT500 fuel-system capacity",
                "If threshold is artificially low: consider relaxing in calibration (R05 decision)"
            ]
        )
    }

    // MARK: - H4: DCT Shift-Transient Interaction

    static func h4DCTShiftTransient() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h4DCTTransient,
            title: "DCT Shift-Transient Interaction",
            description: """
            Dual-clutch transmission shift choreography creates a transient fuel demand surge
            that exceeds capacity for brief moment. Flag appears only during shift, not steady WOT.
            """,
            supportingEvidence: [
                "Event timestamp coincides with gear change (±100ms)",
                "Torque Source enum changes simultaneously (Trans Shift Mod or similar)",
                "Spark Source enum changes simultaneously",
                "Input/Output speed relationship shows shift event",
                "Fuel pressure and lambda remain controlled despite brief surge",
                "Events cluster around gear changes, not sustained WOT"
            ],
            contradictingEvidence: [
                "Event occurs steady-state WOT without gear change",
                "No source-enum change at event",
                "Shift timestamp does not align with protection flag"
            ],
            requiredEvidence: [
                "Gear Selection (current gear)",
                "Torque Source and Spark Source enums (at event and before/after)",
                "Input/Output speed from TCM",
                "Torque Max Protection Source",
                "Shift-phase identification (pre-shift, crossover, post-shift)"
            ],
            confidence: .c1,
            isPlausible: true,
            nextMeasurements: [
                "Capture multiple shifts across different gear pairs (1→2, 2→3, etc.)",
                "Timestamp shift event vs protection event (ms-level precision)",
                "Analyze shift torque reduction strategy: is it sufficient?",
                "May require gear-specific torque reduction calibration (R09)"
            ]
        )
    }

    // MARK: - H5: PID Identity / Scaling Issue

    static func h5PIDIdentityError() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h5PIDIdentity,
            title: "PID Identity / Scaling / Instrumentation Error",
            description: """
            One or more scanner PIDs are incorrectly identified, scaled, or assigned.
            Duplicate channels disagree. Values are physically implausible.
            Instrumentation error, not actual fuel-system problem.
            """,
            supportingEvidence: [
                "Duplicate/related PIDs disagree significantly (e.g., two pressure readings >5 psi apart)",
                "Impossible physical values logged (negative pressure, >110% throttle, etc.)",
                "Odd scaling behavior (channel jumps, saturation at round numbers like 100.0 or 99.9)",
                "WB sensors B1 and B2 diverge >0.05 lambda in steady state",
                "Channel updates erratic or misaligned with expected response times"
            ],
            contradictingEvidence: [
                "All duplicate channels agree closely",
                "All values physically plausible",
                "Consistent scaling and update behavior"
            ],
            requiredEvidence: [
                "Complete PID definition from HP Tuners (name, scaling, min/max, units)",
                "Duplicate/related PID comparison",
                "Cross-vendor validation (external gauge vs logged pressure, etc.)",
                "WB sensor dual-channel agreement test (cruise at stable lambda)"
            ],
            confidence: .c0,
            isPlausible: true,
            nextMeasurements: [
                "Compare logged pressure against OBD live scanner readout",
                "Compare logged pressure against analog fuel-pressure gauge (if available)",
                "Compare WB B1/B2 against known-good external wideband",
                "Re-check HP Tuners PID definition (exact scaling factors, offsets)",
                "Re-build Config B with verified PIDs"
            ]
        )
    }

    // MARK: - H6: Secondary Protection / Hidden Dependency

    static func h6SecondaryProtection() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h6SecondaryProtection,
            title: "Secondary Protection / Hidden Dependency",
            description: """
            A protection source other than the directly-logged one is driving the response.
            Cylinder pressure limit, thermal protection, traction control, or another hidden mechanism.
            """,
            supportingEvidence: [
                "H1–H5 mechanisms do not explain the event pattern",
                "Another source/limit PID changes first (before Insufficient Fuel Flow appears)",
                "Spark Source changes suggest pressure-limit intervention",
                "Event depends on thermal state (only in heat-soak)",
                "Event depends on traction-control state",
                "Event depends on transmission temperature"
            ],
            contradictingEvidence: [
                "One of H1–H5 fully explains the event"
            ],
            requiredEvidence: [
                "Full protection-source timeline (all Torque Max, Spark, Throttle sources)",
                "Cylinder pressure limit channel (if available)",
                "Thermal state (ECT, IAT2, transmission temperature)",
                "Traction control state",
                "Any additional protection not yet logged"
            ],
            confidence: .c0,
            isPlausible: false,
            nextMeasurements: [
                "Build comprehensive Config with ALL protection sources",
                "Correlate all source changes with Insufficient Fuel Flow appearance",
                "Log thermal and traction state alongside fuel/injector data"
            ]
        )
    }

    // MARK: - H7: Pressure-Strategy / Differential-Pressure Interaction

    static func h7PressureStrategy() -> DiagnosticHypothesis {
        DiagnosticHypothesis(
            id: .h7PressureStrategy,
            title: "Pressure-Strategy / Differential-Pressure Interaction",
            description: """
            Fuel pressure deliberately rises (or falls) with load as part of an active pressure strategy.
            The PCM adjusts injector effective flow rate via pressure.
            Allowable injection window or injection-pressure differential creates the constraint.
            """,
            supportingEvidence: [
                "Actual pressure rises intentionally with load",
                "Desired pressure rises with it (not pressure-pump failure)",
                "Pump command changes appropriately",
                "Injector effective-flow calculation depends on differential (rail - return pressure)",
                "Protection may trigger based on differential pressure or resulting allowable PW"
            ],
            contradictingEvidence: [
                "Pressure remains constant across load range",
                "Pressure and strategy are decoupled"
            ],
            requiredEvidence: [
                "Fuel Pressure Command behavior across load (table characterization)",
                "Return pressure (if available)",
                "Pressure differential (rail - return, if available)",
                "Injector flow-rate dependency on pressure",
                "Allowable pulse-width recalculation based on pressure strategy"
            ],
            confidence: .c0,
            isPlausible: false,
            nextMeasurements: [
                "Build table: Pressure Command vs Load from multiple runs",
                "Search TC-298B for differential-pressure or return-pressure PIDs",
                "Correlate allowable injection window against pressure differential"
            ]
        )
    }

    // MARK: - Investigation Scoring

    /// Score all hypotheses based on provided evidence
    func scoreHypotheses(
        actualPW: Double?,
        maximumPW: Double?,
        pressureCommand: Double?,
        pressureActual: Double?,
        pumpDuty: Double?,
        commandedLambda: Double?,
        measuredLambda: Double?,
        torqueSource: String?,
        sparkSource: String?,
        rpm: Double?,
        load: Double?,
        gearAtEvent: Int?,
        shiftTimestamp: TimeInterval?,
        eventTimestamp: TimeInterval?
    ) -> [R04HypothesisID: Int] {

        var scores: [R04HypothesisID: Int] = [:]

        // H1B: Injection Window - strongest discriminator
        if let actualPW = actualPW, let maximumPW = maximumPW {
            let margin = (maximumPW - actualPW) / maximumPW
            if margin < 0.2 {
                scores[.h1bInjectionWindow] = 75 // Strong signature
            } else if margin < 0.35 {
                scores[.h1bInjectionWindow] = 50 // Moderate
            } else {
                scores[.h1bInjectionWindow] = 15 // Weak
            }
        }

        // H2: Pump Pressure
        if let pressureCommand = pressureCommand, let pressureActual = pressureActual {
            let gap = pressureCommand - pressureActual
            if gap > 5 {
                scores[.h2PumpPressure] = 70 // Strong
            } else if gap > 2 {
                scores[.h2PumpPressure] = 40
            } else {
                scores[.h2PumpPressure] = 10
            }
        }

        // H4: DCT Shift
        if let shiftTimestamp = shiftTimestamp, let eventTimestamp = eventTimestamp {
            let timeDelta = abs(eventTimestamp - shiftTimestamp)
            if timeDelta < 0.1 {
                scores[.h4DCTTransient] = 80 // Very strong
            } else if timeDelta < 0.3 {
                scores[.h4DCTTransient] = 60
            } else {
                scores[.h4DCTTransient] = 20
            }
        }

        // H5: PID/channel identity conflict. A low prior is retained until the
        // resolver or an external channel map demonstrates an actual conflict;
        // this is deliberately not presented as a measured probability.
        scores[.h5PIDIdentity] = 10 // Baseline low unless evidence shows conflict

        return scores
    }
}

// MARK: - Recommendation Engine

class R04RecommendationEngine {

    func recommendNextSteps(
        investigationState: Investigation,
        hypothesisScores: [R04HypothesisID: Int]
    ) -> String {

        // Find the highest-scoring hypothesis
        let topHypothesis = hypothesisScores.max { $0.value < $1.value }?.key ?? .h1bInjectionWindow

        switch topHypothesis {
        case .h1bInjectionWindow:
            return """
            H1B Injection-Window Limit appears most likely (highest confidence).

            Recommended next step:
            1. Verify Injector Maximum Pulse Width PID exists in TC-298B
            2. Generate Killer Comparison Chart (Actual vs Maximum PW)
            3. Document exact RPM/load convergence point
            4. Repeat test: confirm injection window is the limiting factor

            If confirmed: Reduce max torque demand or increase fuel pressure (R05 decision)
            """

        case .h2PumpPressure:
            return """
            H2 Pump Pressure Limitation appears plausible.

            Recommended next step:
            1. Verify fuel pressure sensor accuracy (compare vs gauge)
            2. Check fuel filter restriction
            3. Confirm pump voltage/current draw
            4. If pressure drops on pump: investigate fuel system upgrade

            If confirmed: May require fuel system maintenance or upgrade
            """

        case .h4DCTTransient:
            return """
            H4 DCT Shift Transient appears to be the cause.

            Recommended next step:
            1. Document which gear pairs trigger the event
            2. Analyze shift torque reduction strategy
            3. Consider gear-specific torque limits

            If confirmed: R09 DCT tuning will address (shift torque reduction)
            """

        case .h5PIDIdentity:
            return """
            H5 Instrumentation Error appears likely.

            Recommended next step:
            1. Verify all PID definitions in HP Tuners
            2. Cross-check duplicate channels against external instruments
            3. Rebuild Config B with validated PIDs
            4. Restart R04 investigation with corrected data

            If confirmed: Fix instrumentation, return to R01 PID validation
            """

        default:
            return """
            Multiple hypotheses remain plausible. Recommend:
            1. Collect additional logs with more detailed channel coverage
            2. Cross-check all fuel-system channels against external measurements
            3. Build comprehensive Config to capture all protection sources
            4. Rerun hypothesis scoring with complete evidence
            """
        }
    }
}
