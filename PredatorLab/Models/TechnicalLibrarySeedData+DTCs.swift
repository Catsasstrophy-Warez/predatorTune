// Rev39 decomposed technical seed category. Evidence status preserved from authored source.
import Foundation

extension TechnicalLibrarySeedData {
    // MARK: - DTCs

    static func seedDTCs() -> [DTCRecord] {
        [p0089(), p0299(), p0171(), p0335()]
    }

    static func p0089() -> DTCRecord {
        let source = TechnicalSource(
            title: "P0089 Fuel Pressure Regulator Performance",
            sourceType: "Ford WSM",
            reference: "DTC Index, Fuel Delivery",
            grade: .a_factory,
            confidence: .c3
        )
        return DTCRecord(
            id: UUID(),
            code: "P0089",
            title: "Fuel Pressure Regulator 1 Performance",
            description: "PCM has detected that actual fuel rail pressure does not match commanded pressure within the expected tolerance for a sustained period, indicating the closed-loop fuel pressure control (pump duty via FPDM) cannot achieve or hold target",
            severity: "Warning",
            relatedComponent: nil,
            relatedCircuits: [],
            relatedSensors: [],
            monitorLogic: MonitorLogic(
                name: "Fuel Pressure Regulator Performance Monitor",
                enableConditions: ["Engine running", "Fuel demand above idle threshold", "No active FPDM circuit DTCs"],
                testMethod: "Continuous comparison of Fuel Rail Pressure Actual vs Commanded over a rolling window",
                failureCondition: "Deviation exceeds calibrated threshold (approx. ±10 psi) for longer than the debounce time, typically across multiple drive cycles",
                rationality: "Cross-checked against Fuel Pump Duty Cycle — high duty with persistent low pressure confirms a flow/regulation fault rather than a sensor fault",
                enableMask: nil
            ),
            failureThreshold: "Approx. ±10 psi sustained deviation between actual and commanded rail pressure",
            rationalityTests: ["Fuel Pump Duty Cycle near 100% with pressure still below target", "Battery voltage in normal range (rules out pump underperformance from low voltage)"],
            knownIssues: [
                KnownIssue(
                    issue: "In-tank fuel filter restriction limiting pump flow at high demand",
                    symptoms: ["Pressure droop only under sustained WOT, not at idle/cruise", "Duty cycle pinned high during the droop"],
                    commonCauses: ["Debris/contamination in fuel filter sock", "Aging in-tank pump losing output capacity"],
                    diagnosis: "Log FRP Actual vs Command and Pump Duty during a repeatable WOT pull; compare against a known-good baseline",
                    remedy: "Replace in-tank fuel filter/pump module; verify with a repeat log",
                    relevance: "All years, more common after 20k+ miles of track use",
                    source: source
                )
            ],
            pinpointTest: PinpointProcedure(
                title: "P0089 Fuel Pressure Regulator Performance Pinpoint Test",
                overview: "Isolates whether the fault is electrical (FPDM/wiring), mechanical (pump/filter), or a false positive from a PID/sensor scaling issue",
                steps: [
                    PinpointStep(order: 1, instruction: "Verify no active FPDM circuit DTCs (P0230-P0233) are also present", expectedResult: "No FPDM circuit codes present", ifPass: "Continue to step 2", ifFail: "Diagnose FPDM circuit fault first; P0089 may be a consequence", tools: ["Scan tool"], warnings: nil),
                    PinpointStep(order: 2, instruction: "Key on, engine off: verify Fuel Rail Pressure Actual rises to ~95 psi within 2-3 seconds of key-on prime", expectedResult: "FRP Actual reaches 90-100 psi", ifPass: "Continue to step 3", ifFail: "Suspect pump or FPDM fault; test pump directly with a mechanical gauge", tools: ["Scan tool"], warnings: nil),
                    PinpointStep(order: 3, instruction: "Perform a data-logged WOT pull in 3rd or 4th gear; record Fuel Rail Pressure Actual, Command, and Pump Duty Cycle", expectedResult: "Actual tracks Command within ±5 psi throughout the pull", ifPass: "Intermittent fault — inspect connectors for corrosion/looseness", ifFail: "Continue to step 4", tools: ["Scan tool with logging", "safe stretch of road or dyno"], warnings: ["Perform only in a safe, legal environment"]),
                    PinpointStep(order: 4, instruction: "Check Pump Duty Cycle during the pressure droop", expectedResult: "Duty cycle below 100%", ifPass: "Regulation/PCM commanding issue — check FPDM programming/health", ifFail: "Duty pinned at or near 100% with pressure still low: flow-limited — inspect in-tank filter and pump condition", tools: ["Scan tool"], warnings: nil)
                ],
                testEquipment: [
                    TestEquipment(name: "Bidirectional scan tool with data logging", purpose: "Read live FRP Actual/Command and Pump Duty; command FPDM tests", critical: true),
                    TestEquipment(name: "Mechanical fuel pressure gauge", purpose: "Cross-check PCM-reported pressure against a physical gauge", critical: false)
                ],
                safetyWarnings: ["Relieve fuel system pressure before disconnecting any fuel line", "No open flame/sparks near fuel system work"],
                expectedResults: ["FRP Actual tracks Command within tolerance across the full RPM/load range"],
                failureInterpretation: "Persistent droop under load with maxed duty points to a flow restriction or weak pump; droop with duty still headroom points to FPDM/PCM control fault",
                nextSteps: "If flow-limited: replace fuel filter/pump module. If control fault confirmed and wiring/FPDM check out: consider PCM/FPDM programming issue."
            ),
            sources: [source],
            relatedTSBs: nil,
            relatedSSMs: nil
        )
    }

    static func p0299() -> DTCRecord {
        let source = TechnicalSource(
            title: "P0299 Turbo/Supercharger Underboost Condition",
            sourceType: "Ford WSM",
            reference: "DTC Index, Boost Control",
            grade: .a_factory,
            confidence: .c3
        )
        return DTCRecord(
            id: UUID(),
            code: "P0299",
            title: "Turbo/Supercharger 'A' Underboost Condition",
            description: "PCM detects that actual manifold pressure (boost) fails to reach the commanded target within a calibrated tolerance and time window under boost-demand conditions",
            severity: "Warning",
            relatedComponent: nil,
            relatedCircuits: [],
            relatedSensors: [],
            monitorLogic: MonitorLogic(
                name: "Boost Underboost Monitor",
                enableConditions: ["Throttle above threshold indicating boost demand", "Engine at operating temperature", "No active MAP sensor circuit codes"],
                testMethod: "Compares MAP Actual against Boost Target table lookup (RPM vs throttle/load) over a debounce window",
                failureCondition: "MAP Actual remains below target by a calibrated margin (commonly several psi) for longer than the debounce time across multiple attempts",
                rationality: "Cross-checked with bypass valve command state and throttle angle to rule out a simple low-throttle scenario",
                enableMask: nil
            ),
            failureThreshold: "Boost deficit of several psi below target sustained beyond the debounce window",
            rationalityTests: ["Throttle angle confirms driver is requesting boost", "Bypass valve commanded closed but MAP still low"],
            knownIssues: [
                KnownIssue(
                    issue: "Accessory drive belt slip under high boost torque load",
                    symptoms: ["Boost falls progressively short at higher RPM", "Audible chirp/squeal under hard acceleration"],
                    commonCauses: ["Glazed or worn serpentine belt", "Weak/worn tensioner losing clamp force"],
                    diagnosis: "Log Boost Actual vs Target across the RPM range; visually inspect belt and tensioner travel",
                    remedy: "Replace belt and/or tensioner",
                    relevance: "All years",
                    source: source
                ),
                KnownIssue(
                    issue: "Bypass valve stuck partially open",
                    symptoms: ["Underboost even with a known-good belt", "Boost target reached briefly then falls off"],
                    commonCauses: ["Actuator mechanical binding", "Vacuum/electrical actuator fault"],
                    diagnosis: "Command the bypass actuator with a bidirectional scan tool and confirm full travel",
                    remedy: "Clean, repair, or replace the bypass valve actuator",
                    relevance: "All years",
                    source: source
                )
            ],
            pinpointTest: PinpointProcedure(
                title: "P0299 Underboost Pinpoint Test",
                overview: "Distinguishes mechanical drive-system faults (belt/pulley) from bypass valve control faults and MAP sensor faults",
                steps: [
                    PinpointStep(order: 1, instruction: "Verify no MAP sensor circuit DTCs (P0106-P0108) are present", expectedResult: "No MAP circuit codes", ifPass: "Continue to step 2", ifFail: "Resolve MAP sensor circuit fault first", tools: ["Scan tool"], warnings: nil),
                    PinpointStep(order: 2, instruction: "Visually inspect supercharger drive belt for glazing, cracking, or slip marks; check tensioner arm travel", expectedResult: "Belt in good condition, tensioner within normal travel range", ifPass: "Continue to step 3", ifFail: "Replace belt/tensioner and re-test", tools: ["Flashlight", "belt tension gauge"], warnings: ["Engine off and cool before inspection"]),
                    PinpointStep(order: 3, instruction: "Using bidirectional scan tool, command the bypass valve actuator through full travel and confirm movement", expectedResult: "Valve moves fully open to fully closed on command", ifPass: "Continue to step 4", ifFail: "Repair/replace actuator or its wiring circuit", tools: ["Bidirectional scan tool"], warnings: nil),
                    PinpointStep(order: 4, instruction: "Data-log Boost Actual vs Target through a full-throttle pull in 3rd gear", expectedResult: "Boost Actual reaches within ~1 psi of target by mid-RPM range", ifPass: "Intermittent — recheck connectors and belt tension periodically", ifFail: "Deficit scales with RPM: suspect belt slip under load; deficit is flat/early: suspect bypass valve leak-by", tools: ["Scan tool with logging"], warnings: ["Perform only in a safe, legal environment"])
                ],
                testEquipment: [
                    TestEquipment(name: "Bidirectional scan tool with logging", purpose: "Command bypass valve, log Boost Actual/Target", critical: true),
                    TestEquipment(name: "Belt tension gauge", purpose: "Verify tensioner is within spec range", critical: false)
                ],
                safetyWarnings: ["Allow engine to cool before belt inspection", "Perform WOT logging only in a safe, legal environment"],
                expectedResults: ["Boost Actual reaches within ~1 psi of Target across the RPM range"],
                failureInterpretation: "RPM-scaling deficit indicates belt slip; flat early deficit indicates bypass valve leak-by; no deficit on retest indicates an intermittent connector/wiring issue",
                nextSteps: "Replace confirmed faulty component (belt, tensioner, or bypass actuator) and clear codes for a verification drive cycle"
            ),
            sources: [source],
            relatedTSBs: nil,
            relatedSSMs: nil
        )
    }

    static func p0171() -> DTCRecord {
        let source = TechnicalSource(
            title: "P0171/P0174 System Too Lean",
            sourceType: "Ford WSM",
            reference: "DTC Index, Fuel Trim",
            grade: .a_factory,
            confidence: .c3
        )
        return DTCRecord(
            id: UUID(),
            code: "P0171",
            title: "System Too Lean (Bank 1)",
            description: "PCM's long-term and/or short-term fuel trim on Bank 1 has exceeded a calibrated positive (lean-correcting) limit, indicating the closed-loop system is compensating for an actual lean condition beyond its normal adaptive range",
            severity: "Warning",
            relatedComponent: nil,
            relatedCircuits: [],
            relatedSensors: [],
            monitorLogic: MonitorLogic(
                name: "Fuel Trim Monitor",
                enableConditions: ["Closed-loop fuel control active", "Engine at operating temperature", "Steady-state cruise or idle conditions sampled"],
                testMethod: "Accumulates Long Term Fuel Trim (LTFT) and Short Term Fuel Trim (STFT) values over multiple drive cycles",
                failureCondition: "LTFT + STFT exceeds a calibrated positive threshold (commonly around +20-25%) sustained across the monitor's evaluation window",
                rationality: "Cross-checked against MAF/MAP airflow plausibility and wideband lambda actual vs commanded",
                enableMask: nil
            ),
            failureThreshold: "Combined fuel trim exceeding approx. +20-25% sustained",
            rationalityTests: ["Vacuum leak check (unmetered air entering downstream of MAF/throttle)", "Wideband lambda reading confirms genuine lean condition vs a trim calculation artifact"],
            knownIssues: [
                KnownIssue(
                    issue: "Vacuum/boost leak downstream of the throttle body or at intake manifold gaskets",
                    symptoms: ["Lean trim most pronounced at idle/light load", "Rough or unstable idle"],
                    commonCauses: ["Cracked PCV hose", "Loose or degraded intake manifold/throttle body gasket", "Aftermarket intake fitment issue"],
                    diagnosis: "Smoke test the intake tract from throttle body to intake valves",
                    remedy: "Repair or replace the leaking hose/gasket",
                    relevance: "All years",
                    source: source
                )
            ],
            pinpointTest: PinpointProcedure(
                title: "P0171/P0174 Lean Condition Pinpoint Test",
                overview: "Localizes a vacuum leak or fueling shortfall causing sustained lean fuel trim correction",
                steps: [
                    PinpointStep(order: 1, instruction: "Record LTFT/STFT at idle and at steady 2000 rpm cruise", expectedResult: "Trims within normal range (±10%) or clearly elevated for comparison baseline", ifPass: "Trims normal — condition intermittent, monitor and re-test", ifFail: "Continue to step 2", tools: ["Scan tool"], warnings: nil),
                    PinpointStep(order: 2, instruction: "Smoke test the intake tract from the throttle body through the intake manifold and PCV system", expectedResult: "No smoke escaping at gaskets, hoses, or fittings", ifPass: "Continue to step 3", ifFail: "Repair leak source found and re-test trims", tools: ["Smoke machine"], warnings: ["Engine off and cool during smoke test"]),
                    PinpointStep(order: 3, instruction: "Inspect wideband O2 sensor (B1S1) signal for correlation with the reported lean trim", expectedResult: "Wideband confirms genuine lean AFR matching trim direction", ifPass: "Genuine lean fault confirmed — check fuel delivery capacity next", ifFail: "Suspect a sensor/PID scaling issue rather than a true lean condition", tools: ["Scan tool", "wideband datalog"], warnings: nil)
                ],
                testEquipment: [
                    TestEquipment(name: "Smoke machine", purpose: "Locate vacuum/boost leaks", critical: true),
                    TestEquipment(name: "Scan tool with fuel trim and wideband PIDs", purpose: "Quantify trim and confirm against wideband", critical: true)
                ],
                safetyWarnings: ["Ventilate area when using a smoke machine", "Engine off during smoke testing"],
                expectedResults: ["Trims return to normal range after leak repair, confirmed over a follow-up drive cycle"],
                failureInterpretation: "Leak found and fixed with trims normalizing confirms the root cause; no leak found with trims still elevated should escalate to fuel delivery investigation",
                nextSteps: "If no vacuum leak found, investigate fuel pressure/pump capacity and injector condition"
            ),
            sources: [source],
            relatedTSBs: nil,
            relatedSSMs: nil
        )
    }

    static func p0335() -> DTCRecord {
        let source = TechnicalSource(
            title: "P0335 Crankshaft Position Sensor Circuit",
            sourceType: "Ford WSM",
            reference: "DTC Index, Crankshaft Position Sensor",
            grade: .a_factory,
            confidence: .c3
        )
        return DTCRecord(
            id: UUID(),
            code: "P0335",
            title: "Crankshaft Position Sensor 'A' Circuit",
            description: "PCM has detected an implausible or missing crankshaft position sensor signal — no signal, erratic signal, or a signal that fails plausibility checks against camshaft position sensor data",
            severity: "Critical",
            relatedComponent: nil,
            relatedCircuits: [],
            relatedSensors: [],
            monitorLogic: MonitorLogic(
                name: "Crankshaft Position Sensor Circuit Monitor",
                enableConditions: ["Engine cranking or running"],
                testMethod: "Monitors CKP signal pattern continuity and compares timing/sync against camshaft position sensor signals",
                failureCondition: "Signal absent during cranking, or sync loss/implausible tooth pattern detected during running",
                rationality: "Cross-checked against CMP signals for cam/crank correlation",
                enableMask: nil
            ),
            failureThreshold: "Loss of signal or sync fault exceeding a single calibrated occurrence threshold",
            rationalityTests: ["CMP-to-CKP correlation check", "No-start condition with cranking RPM PID at zero despite starter engagement"],
            knownIssues: [
                KnownIssue(
                    issue: "CKP connector heat damage near the exhaust/headers",
                    symptoms: ["Intermittent stall or no-start, worse when hot", "Code sets sporadically, especially after extended driving"],
                    commonCauses: ["Connector or wiring insulation degraded from proximity to exhaust heat", "Sensor air gap contamination with debris"],
                    diagnosis: "Inspect connector and wiring near the exhaust for heat damage; check sensor air gap and mounting",
                    remedy: "Repair/replace damaged wiring or connector; reseat or replace sensor",
                    relevance: "All years",
                    source: source
                )
            ],
            pinpointTest: PinpointProcedure(
                title: "P0335 Crankshaft Position Sensor Pinpoint Test",
                overview: "Confirms whether the fault is sensor, wiring, or a genuine mechanical timing issue, prioritizing safety given this is a no-start-capable code",
                steps: [
                    PinpointStep(order: 1, instruction: "Attempt to crank the engine and monitor CKP RPM PID on the scan tool", expectedResult: "RPM PID shows nonzero value while cranking", ifPass: "Intermittent fault — inspect wiring/connector for marginal contact", ifFail: "Continue to step 2", tools: ["Scan tool"], warnings: ["Ensure vehicle is in Park/Neutral with parking brake set before cranking"]),
                    PinpointStep(order: 2, instruction: "Inspect CKP connector and wiring harness routing near the exhaust manifold/headers for heat damage", expectedResult: "Connector and insulation intact, no melting or chafing", ifPass: "Continue to step 3", ifFail: "Repair/replace damaged harness section and re-test", tools: ["Flashlight", "DVOM"], warnings: ["Engine off and cool before inspection"]),
                    PinpointStep(order: 3, instruction: "Check sensor signal with a DVOM/scope at the PCM connector while cranking (if a helper is available)", expectedResult: "AC signal pulses present corresponding to crank rotation", ifPass: "Signal reaches PCM but isn't recognized — suspect PCM fault (rare)", ifFail: "No signal at PCM — sensor or wiring open between sensor and PCM", tools: ["DVOM or scope", "second technician to crank"], warnings: ["Coordinate clearly before cranking with hands near the engine"])
                ],
                testEquipment: [
                    TestEquipment(name: "Scan tool with live RPM PID", purpose: "Confirm PCM is or isn't seeing a crank signal", critical: true),
                    TestEquipment(name: "Digital storage oscilloscope", purpose: "Verify signal waveform quality if DVOM is inconclusive", critical: false)
                ],
                safetyWarnings: ["Never work near a cranking/running engine's rotating components", "Coordinate with a second person before any cranking test"],
                expectedResults: ["Consistent CKP signal present during cranking and running with no dropouts"],
                failureInterpretation: "No signal at sensor and at PCM: replace sensor. Signal at sensor but not PCM: repair wiring. Signal present but code persists: rare PCM fault.",
                nextSteps: "Replace CKP sensor per WSM procedure if wiring and connector check out good; verify with a clear drive cycle"
            ),
            sources: [source],
            relatedTSBs: nil,
            relatedSSMs: nil
        )
    }

}
