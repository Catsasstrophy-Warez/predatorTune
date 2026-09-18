// Rev39 decomposed technical seed category. Evidence status preserved from authored source.
import Foundation

extension TechnicalLibrarySeedData {
    // MARK: - Circuits

    static func seedCircuits() -> [CircuitRecord] {
        [fuelPumpPowerCircuit(), tcmCANBusCircuit(), bypassValveActuatorCircuit(), knockSensorCircuit(), widebandO2Circuit()]
    }

    static func fuelPumpPowerCircuit() -> CircuitRecord {
        let source = TechnicalSource(
            title: "2020-2022 Mustang Wiring Diagrams",
            sourceType: "Ford WSM",
            reference: "Section 310-01, Fuel Pump Control",
            grade: .a_factory,
            confidence: .c4
        )
        return CircuitRecord(
            id: UUID(),
            name: "Fuel Pump Power Supply Circuit",
            subsystem: "Fuel Delivery",
            function: "Delivers switched, PCM-modulated battery power to the in-tank fuel pump module via the Fuel Pump Driver Module (FPDM)",
            path: [
                CircuitNode(sequence: 1, type: "Power source", designation: "Battery positive (B+)", details: "Direct battery feed via 40A mini fuse", voltage: "12-14.4V", expectedReading: "12.6V key-off, 13.5-14.5V running"),
                CircuitNode(sequence: 2, type: "Fuse", designation: "BCM Fuse Box, Fuse 27", details: "40A mini fuse, fuel pump relay feed", voltage: "12V", expectedReading: "12V with key on"),
                CircuitNode(sequence: 3, type: "Relay", designation: "Fuel Pump Relay (K-FP)", details: "Normally-open, PCM-controlled ground on coil side", voltage: "12V switched", expectedReading: "Continuity across contacts with relay energized"),
                CircuitNode(sequence: 4, type: "Module pin", designation: "FPDM Connector C1, Pin 1 (Battery In)", details: "Fuel Pump Driver Module, mounted near fuel tank", voltage: "12V", expectedReading: "12V KOEO with relay energized"),
                CircuitNode(sequence: 5, type: "Module pin", designation: "FPDM Connector C1, Pin 3 (Pump Drive Out)", details: "PWM-modulated output to pump motor", voltage: "0-12V PWM", expectedReading: "Duty cycle varies 30-100% with demand"),
                CircuitNode(sequence: 6, type: "Connector", designation: "Fuel-tank harness connector (designation unverified)", details: "Legacy seed location/terminal detail is not admitted as production GT500 truth", voltage: "PWM"),
                CircuitNode(sequence: 7, type: "Actuator", designation: "In-tank fuel pump motor", details: "Brushless DC pump, module-driven", voltage: "PWM", expectedReading: "Audible whine, pressure rise within 2s of key-on"),
                CircuitNode(sequence: 8, type: "Ground", designation: "G206 (fuel tank area chassis ground)", details: "Pump and FPDM ground return", voltage: "0V", expectedReading: "<0.1V drop to battery negative")
            ],
            connectors: [
                ConnectorDetail(
                    name: "Fuel-tank harness connector (designation unverified)",
                    location: "Top of fuel tank, accessed via rear seat/trunk service panel",
                    pinCount: 3,
                    type: "Weather-pack, black",
                    pins: [
                        ConnectorPin(number: 1, color: "Pink/Black", function: "Pump drive (PWM)", expectedVoltage: "0-12V PWM", currentDraw: "up to 10A"),
                        ConnectorPin(number: 2, color: "Black", function: "Ground", expectedVoltage: "0V", currentDraw: nil),
                        ConnectorPin(number: 3, color: "Gray/Orange", function: "Pump feedback/speed signal", expectedVoltage: "0-5V", currentDraw: nil)
                    ],
                    knownIssues: ["Legacy anecdotal issue removed from authoritative use pending exact production source"],
                    testPoints: ["Backprobe pin 1 for PWM duty during a KOER fuel demand test"]
                )
            ],
            wireColor: "Pink/Black (drive), Black (ground)",
            wireGauge: "16 AWG (drive), 14 AWG (ground)",
            circuitId: "FP-1 (Ford circuit numbering, fuel pump primary)",
            nominalVoltage: "12V system, PWM-modulated drive",
            expectedCurrent: "Max ~10A at full pump duty",
            groundPath: "G206 chassis ground, fuel tank area",
            canNetwork: nil,
            canId: nil,
            koeoExpected: "12V at FPDM pin 1 within 2 seconds of key-on prime",
            koerExpected: "PWM duty 30-45% at idle, rising to 90-100% at WOT/high boost",
            loadedExpected: "Duty approaches 100% during sustained high-RPM WOT; Fuel Pressure Actual should track Command within ~3 psi",
            relatedDTCs: ["P0087", "P0088", "P0230", "P0231", "P0232"],
            commonIssues: [
                CircuitIssue(
                    problem: "Pump duty maxed with pressure droop under sustained high demand",
                    symptoms: ["Fuel Pressure Actual departs from Command during long WOT pulls", "Insufficient Fuel Flow protection event"],
                    diagnosis: "Log Fuel Pump Duty Cycle alongside Fuel Pressure Actual/Command; duty pinned near 100% with pressure still falling indicates flow limit, not electrical fault",
                    remedy: "Inspect in-tank filter sock for restriction; verify battery voltage doesn't sag under load; consider higher-output pump for sustained high-boost use",
                    source: source
                )
            ],
            testPoints: [
                TestPoint(
                    name: "FPDM battery input voltage",
                    location: "FPDM connector C1, pin 1",
                    tools: ["DVOM", "backprobe pins"],
                    expectedResult: "12V+ with key on, fuel pump relay energized",
                    failureInterpretation: "No voltage: check Fuse 27 and relay; voltage present but pump silent: check drive circuit continuity to the verified fuel-pump connector once its production designation is sourced",
                    relatedDTC: "P0230"
                )
            ],
            sources: [source],
            wiring: WiringDiagramReference(manual: "2020 Mustang Wiring Diagrams", section: "310-01", diagram: "Fuel Pump Control Circuit", publisher: "Ford Motor Company", partNumber: nil)
        )
    }

    static func tcmCANBusCircuit() -> CircuitRecord {
        let source = TechnicalSource(
            title: "2020-2022 Mustang Network Communications",
            sourceType: "Ford WSM",
            reference: "Section 418-00, Module Communications Network",
            grade: .a_factory,
            confidence: .c4
        )
        return CircuitRecord(
            id: UUID(),
            name: "TCM High-Speed CAN Bus (Powertrain)",
            subsystem: "Electrical & CAN",
            function: "Carries real-time gear, clutch, and shift-strategy data between the TR-9070 DCT's TCM and the PCM over the HS-CAN (powertrain) network",
            path: [
                CircuitNode(sequence: 1, type: "Module pin", designation: "PCM Connector C1, Pin 41 (CAN High)", details: "PCM node on HS-CAN", voltage: "2.5-3.5V (dominant/recessive)", expectedReading: "~2.75V idle bias"),
                CircuitNode(sequence: 2, type: "Module pin", designation: "PCM Connector C1, Pin 42 (CAN Low)", details: "PCM node on HS-CAN", voltage: "1.5-2.5V", expectedReading: "~2.25V idle bias"),
                CircuitNode(sequence: 3, type: "Splice", designation: "S powertrain CAN splice pack", details: "Twisted-pair CAN H/L trunk, spliced to each node", voltage: "CAN differential"),
                CircuitNode(sequence: 4, type: "Module pin", designation: "TCM Connector C2, Pin 12/13 (CAN H/L)", details: "TR-9070 TCM node", voltage: "CAN differential", expectedReading: "Active traffic, ~500 kbps"),
                CircuitNode(sequence: 5, type: "Module pin", designation: "ABS/BCM/Cluster nodes", details: "Additional HS-CAN nodes sharing the same trunk", voltage: "CAN differential")
            ],
            connectors: [
                ConnectorDetail(
                    name: "TCM Connector C2",
                    location: "Rear transaxle-mounted TCM, integrated with TR-9070",
                    pinCount: 2,
                    type: "Sealed CAN pair",
                    pins: [
                        ConnectorPin(number: 12, color: "White/Orange", function: "CAN High", expectedVoltage: "2.5-3.5V", currentDraw: nil),
                        ConnectorPin(number: 13, color: "Yellow/Brown", function: "CAN Low", expectedVoltage: "1.5-2.5V", currentDraw: nil)
                    ],
                    knownIssues: nil,
                    testPoints: ["Terminating resistor check across CAN H/L, expect ~60Ω with key off (two 120Ω terminators in parallel)"]
                )
            ],
            wireColor: "White/Orange (CAN H), Yellow/Brown (CAN L)",
            wireGauge: "20 AWG twisted pair",
            circuitId: "HS-CAN1 (Powertrain)",
            nominalVoltage: "2.5V ±2.5V differential",
            expectedCurrent: nil,
            groundPath: "Shared module chassis grounds, not signal-carrying",
            canNetwork: "HS-CAN (Powertrain)",
            canId: "0x217 (TCM status, approximate/representative — exact frame IDs are Ford-proprietary)",
            koeoExpected: "Bus active within 1s of key-on; ~60Ω resistance across CAN H/L with key off and battery connected",
            koerExpected: "Continuous bidirectional traffic between PCM and TCM for gear/clutch/torque-reduction coordination",
            loadedExpected: "Elevated message rate during shift events; no dropped frames expected under normal operation",
            relatedDTCs: ["U0101", "U0100", "P0613"],
            commonIssues: [
                CircuitIssue(
                    problem: "U0101 Lost Communication with TCM",
                    symptoms: ["Transmission defaults to failsafe gear", "Instrument cluster shows transmission fault"],
                    diagnosis: "Check CAN H/L resistance (~60Ω) and continuity to TCM connector; look for chafed harness near transaxle mount points",
                    remedy: "Repair chafed/open CAN wiring or reseat TCM connector; replace TCM only after wiring is confirmed good",
                    source: source
                )
            ],
            testPoints: [
                TestPoint(
                    name: "CAN bus termination resistance",
                    location: "OBD-II pins 6 (CAN H) and 14 (CAN L), key off",
                    tools: ["DVOM"],
                    expectedResult: "~60Ω across pins 6 and 14",
                    failureInterpretation: "Open (infinite Ω) suggests a break in the bus or a missing terminator; near 120Ω suggests one terminator failed open",
                    relatedDTC: "U0101"
                )
            ],
            sources: [source],
            wiring: WiringDiagramReference(manual: "2020 Mustang Wiring Diagrams", section: "418-00", diagram: "HS-CAN Powertrain Network", publisher: "Ford Motor Company", partNumber: nil)
        )
    }

    static func bypassValveActuatorCircuit() -> CircuitRecord {
        let source = TechnicalSource(
            title: "GT500 Supercharger Bypass Valve Control",
            sourceType: "HP Tuners Doc",
            reference: "Supercharger bypass/recirculation actuator strategy notes",
            grade: .b_professional,
            confidence: .c3
        )
        return CircuitRecord(
            id: UUID(),
            name: "Supercharger Bypass Valve Actuator Circuit",
            subsystem: "Supercharger",
            function: "PCM-driven vacuum/electric actuator that opens the bypass valve at low load to recirculate charge air internally and reduce parasitic drag and off-boost heat",
            path: [
                CircuitNode(sequence: 1, type: "Power source", designation: "Battery positive via ignition relay", details: "Switched 12V, ignition-on only", voltage: "12V"),
                CircuitNode(sequence: 2, type: "Fuse", designation: "Powertrain fuse box, actuator feed fuse", details: "10A mini fuse", voltage: "12V"),
                CircuitNode(sequence: 3, type: "Module pin", designation: "PCM Driver Output (low-side)", details: "PCM switches ground to energize actuator solenoid", voltage: "0V when commanded on"),
                CircuitNode(sequence: 4, type: "Actuator", designation: "Bypass valve solenoid/actuator", details: "Electrically-actuated butterfly valve in the bypass passage between supercharger discharge and inlet", voltage: "12V when energized", expectedReading: "Valve closes (boost mode) when energized, opens (bypass) when de-energized"),
                CircuitNode(sequence: 5, type: "Ground", designation: "PCM internal low-side driver ground", details: "Returns through PCM case ground", voltage: "0V")
            ],
            connectors: [
                ConnectorDetail(
                    name: "Bypass Valve Connector",
                    location: "Top of supercharger housing, driver side",
                    pinCount: 2,
                    type: "2-pin metripack",
                    pins: [
                        ConnectorPin(number: 1, color: "Orange", function: "Switched 12V feed", expectedVoltage: "12V", currentDraw: "~1A"),
                        ConnectorPin(number: 2, color: "Black/White", function: "PCM low-side driver return", expectedVoltage: "0V when commanded", currentDraw: nil)
                    ],
                    knownIssues: nil,
                    testPoints: nil
                )
            ],
            wireColor: "Orange (feed), Black/White (driver return)",
            wireGauge: "18 AWG",
            circuitId: "SC-BPV-1 (representative designation)",
            nominalVoltage: "12V",
            expectedCurrent: "~1A holding current",
            groundPath: "PCM internal low-side driver",
            canNetwork: nil,
            canId: nil,
            koeoExpected: "12V at pin 1 with key on; 12V at pin 2 (valve open/de-energized, default state)",
            koerExpected: "Pin 2 pulled to near 0V under PCM command to close the bypass valve as boost demand rises",
            loadedExpected: "Valve fully closed (energized) throughout sustained boost; should track Throttle Angle/Load, not oscillate erratically",
            relatedDTCs: ["P0299", "P228A", "P228B"],
            commonIssues: [
                CircuitIssue(
                    problem: "Valve stuck open causing underboost",
                    symptoms: ["P0299 underboost code", "Sluggish acceleration despite normal throttle input"],
                    diagnosis: "Command the actuator via scan tool bidirectional control and listen/feel for valve movement; check for 12V and driver ground continuity at the connector",
                    remedy: "Clean or replace stuck actuator; repair open/shorted driver circuit if no PCM control detected",
                    source: source
                )
            ],
            testPoints: [
                TestPoint(
                    name: "Actuator driver ground activation",
                    location: "Bypass valve connector, pin 2",
                    tools: ["DVOM", "scan tool bidirectional control"],
                    expectedResult: "Voltage drops from 12V to near 0V when actuator commanded closed",
                    failureInterpretation: "No voltage change: PCM driver circuit open or PCM fault; voltage changes but valve doesn't move: mechanical/actuator fault",
                    relatedDTC: "P0299"
                )
            ],
            sources: [source],
            wiring: nil
        )
    }

    static func knockSensorCircuit() -> CircuitRecord {
        let source = TechnicalSource(
            title: "5.2L Predator Knock Sensor Circuit",
            sourceType: "Ford WSM",
            reference: "Section 303-14D, Knock Sensor System",
            grade: .a_factory,
            confidence: .c4
        )
        return CircuitRecord(
            id: UUID(),
            name: "Knock Sensor Circuit (Bank 1 / Bank 2)",
            subsystem: "Spark & Ignition",
            function: "Piezoelectric knock sensors detect combustion-induced block vibration; PCM uses the signal to retard timing and protect against detonation under boost",
            path: [
                CircuitNode(sequence: 1, type: "Sensor", designation: "Knock Sensor 1 (Bank 1, driver side block)", details: "Piezoelectric, non-powered (self-generating)", voltage: "AC signal, mV range", expectedReading: "Amplitude rises sharply with detonation-frequency vibration"),
                CircuitNode(sequence: 2, type: "Sensor", designation: "Knock Sensor 2 (Bank 2, passenger side block)", details: "Piezoelectric, non-powered", voltage: "AC signal, mV range"),
                CircuitNode(sequence: 3, type: "Connector", designation: "Knock sensor pigtail connectors", details: "Shielded 2-pin connectors at each sensor", voltage: "AC signal"),
                CircuitNode(sequence: 4, type: "Module pin", designation: "PCM Connector C3, Pins for KS1/KS2 signal", details: "Shielded twisted-pair input to PCM knock ASIC", voltage: "AC signal", expectedReading: "PCM samples in a frequency window matched to bore resonance")
            ],
            connectors: [
                ConnectorDetail(
                    name: "Knock Sensor Pigtail (KS1/KS2)",
                    location: "Lower engine block, between cylinder banks under intake manifold",
                    pinCount: 2,
                    type: "Shielded 2-pin",
                    pins: [
                        ConnectorPin(number: 1, color: "Gray (shielded signal)", function: "Knock signal to PCM", expectedVoltage: "AC mV signal", currentDraw: nil),
                        ConnectorPin(number: 2, color: "Black (shield ground)", function: "Shield drain ground", expectedVoltage: "0V", currentDraw: nil)
                    ],
                    knownIssues: ["Sensor torque is critical — over/under-torque changes sensitivity and can cause false or missed knock detection"],
                    testPoints: nil
                )
            ],
            wireColor: "Gray shielded",
            wireGauge: "20 AWG shielded twisted pair",
            circuitId: "KS-1/KS-2",
            nominalVoltage: "Self-generating AC signal, no supply voltage",
            expectedCurrent: nil,
            groundPath: "Shield drain to PCM case ground only; sensor body ground is through mounting torque to block",
            canNetwork: nil,
            canId: nil,
            koeoExpected: "No signal (sensor requires vibration to generate output)",
            koerExpected: "Low-amplitude broadband signal at idle; PCM should show zero or minimal knock retard at steady idle",
            loadedExpected: "Under WOT boost, PCM knock retard should stay near 0° on 93 octane at stock tune; sustained retard indicates marginal fuel quality, heat soak, or a mechanical knock source",
            relatedDTCs: ["P0325", "P0326", "P0330", "P0331"],
            commonIssues: [
                CircuitIssue(
                    problem: "Sensor loose or incorrectly torqued causing erratic knock retard",
                    symptoms: ["Inconsistent timing retard unrelated to fuel quality", "Power loss under boost with no audible knock"],
                    diagnosis: "Verify sensor torque per WSM spec; check shielded wiring for chafing near the intake manifold gasket area",
                    remedy: "Re-torque or replace sensor to spec; repair shield/ground path",
                    source: source
                )
            ],
            testPoints: [
                TestPoint(
                    name: "Knock sensor resistance/signal check",
                    location: "PCM connector C3, KS1/KS2 pins, sensor disconnected",
                    tools: ["DVOM (AC mV scale)", "scan tool knock retard PID"],
                    expectedResult: "Small AC voltage spike when block is tapped near the sensor with engine off",
                    failureInterpretation: "No signal: open circuit or dead sensor; signal present but PCM shows no knock PID activity: PCM input fault",
                    relatedDTC: "P0325"
                )
            ],
            sources: [source],
            wiring: WiringDiagramReference(manual: "2020 Mustang Wiring Diagrams", section: "303-14D", diagram: "Knock Sensor Circuit", publisher: "Ford Motor Company", partNumber: nil)
        )
    }

    static func widebandO2Circuit() -> CircuitRecord {
        let source = TechnicalSource(
            title: "GT500 Heated Oxygen Sensor Circuits",
            sourceType: "Ford WSM",
            reference: "Section 303-14A, Wide-Range Air/Fuel (WRAF) Sensors",
            grade: .a_factory,
            confidence: .c4
        )
        return CircuitRecord(
            id: UUID(),
            name: "Wideband O2 (WRAF) Sensor Circuit, Bank 1 Sensor 1",
            subsystem: "Fuel Delivery",
            function: "Wide-range air/fuel sensor provides continuous lambda feedback to the PCM for closed-loop fueling and fuel trim correction",
            path: [
                CircuitNode(sequence: 1, type: "Power source", designation: "Battery positive, heater circuit", details: "Switched 12V through heater relay", voltage: "12V"),
                CircuitNode(sequence: 2, type: "Fuse", designation: "HO2S Heater Fuse", details: "15A mini fuse", voltage: "12V"),
                CircuitNode(sequence: 3, type: "Module pin", designation: "PCM low-side heater driver", details: "PCM PWM-controls heater to maintain ~780°C sensor tip temp", voltage: "PWM"),
                CircuitNode(sequence: 4, type: "Sensor", designation: "Bank 1 Sensor 1 WRAF sensor (pre-cat)", details: "5-wire wideband sensor: heater +/-, pump cell, Nernst cell, common", voltage: "Ip current output, Vs reference ~450mV"),
                CircuitNode(sequence: 5, type: "Module pin", designation: "PCM WRAF signal processing pins", details: "PCM converts pump cell current to lambda value", voltage: "Signal current, μA range", expectedReading: "Lambda 1.00 (14.64:1 AFR for gasoline) at closed-loop idle")
            ],
            connectors: [
                ConnectorDetail(
                    name: "Bank 1 Sensor 1 Connector",
                    location: "Pre-catalyst, exhaust manifold collector, driver side",
                    pinCount: 5,
                    type: "5-pin weather-pack, high-temp",
                    pins: [
                        ConnectorPin(number: 1, color: "White", function: "Heater +", expectedVoltage: "12V PWM", currentDraw: "up to 3A"),
                        ConnectorPin(number: 2, color: "White", function: "Heater -", expectedVoltage: "0V", currentDraw: nil),
                        ConnectorPin(number: 3, color: "Black", function: "Pump cell (Ip)", expectedVoltage: "current signal", currentDraw: nil),
                        ConnectorPin(number: 4, color: "Gray", function: "Nernst cell reference (Vs)", expectedVoltage: "~450mV at lambda 1.0", currentDraw: nil),
                        ConnectorPin(number: 5, color: "Gray", function: "Common/COM", expectedVoltage: "reference", currentDraw: nil)
                    ],
                    knownIssues: nil,
                    testPoints: ["Heater PWM duty check at cold start, should be near 100% then taper as sensor reaches temp"]
                )
            ],
            wireColor: "White (heater), Black/Gray (signal)",
            wireGauge: "18 AWG heater, 20 AWG signal (high-temp insulation)",
            circuitId: "HO2S11 (B1S1 wideband)",
            nominalVoltage: "12V heater, low-voltage/current signal cells",
            expectedCurrent: "Heater up to 3A cold, signal in μA range",
            groundPath: "PCM common reference, not chassis ground",
            canNetwork: nil,
            canId: nil,
            koeoExpected: "0V at sensor, heater not yet commanded",
            koerExpected: "Heater duty near 100% for ~10-20s at cold start, then modulates to hold operating temp; lambda reads rich (~0.8-0.9) during open-loop warmup then settles to ~1.00 closed loop",
            loadedExpected: "Lambda commanded rich (0.78-0.85) under sustained WOT boost per the enrichment table; should track Commanded Equivalence Ratio closely",
            relatedDTCs: ["P0171", "P0174", "P0131", "P0132", "P0135"],
            commonIssues: [
                CircuitIssue(
                    problem: "Slow or lazy sensor response causing trim hunting",
                    symptoms: ["Fuel trims oscillating outside normal band", "Rough idle after sensor ages past ~60k miles"],
                    diagnosis: "Compare sensor switching speed / lambda response time against a known-good baseline log",
                    remedy: "Replace WRAF sensor; inspect connector for exhaust heat damage to wiring insulation",
                    source: source
                )
            ],
            testPoints: [
                TestPoint(
                    name: "Heater circuit resistance",
                    location: "Sensor connector, pins 1-2, sensor disconnected and cold",
                    tools: ["DVOM"],
                    expectedResult: "~2-4Ω across heater pins when cold",
                    failureInterpretation: "Open circuit: failed heater element, replace sensor",
                    relatedDTC: "P0135"
                )
            ],
            sources: [source],
            wiring: WiringDiagramReference(manual: "2020 Mustang Wiring Diagrams", section: "303-14A", diagram: "WRAF Sensor Circuit B1S1", publisher: "Ford Motor Company", partNumber: nil)
        )
    }

}
