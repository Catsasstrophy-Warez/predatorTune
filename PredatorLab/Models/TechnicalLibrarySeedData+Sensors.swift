// Rev39 decomposed technical seed category. Evidence status preserved from authored source.
import Foundation

extension TechnicalLibrarySeedData {
    // MARK: - Sensors

    static func seedSensors() -> [SensorRecord] {
        [fuelRailPressureSensor(), mapBoostSensor(), iat2Sensor(), knockSensorPID(), widebandO2SensorPID()]
    }

    static func fuelRailPressureSensor() -> SensorRecord {
        let source = TechnicalSource(
            title: "GT500 Fuel Rail Pressure Sensor Spec",
            sourceType: "Ford WSM",
            reference: "310-01, Fuel Charging and Controls",
            grade: .a_factory,
            confidence: .c4
        )
        return SensorRecord(
            id: UUID(),
            name: "Fuel Rail Pressure Sensor (FRP)",
            pidName: "FRP_ACTUAL",
            pidId: "0x23",
            units: "psi",
            minValue: 0,
            maxValue: 150,
            resolution: 0.5,
            dataType: "Analog",
            typicalValues: [
                SensorTypicalValue(condition: "KOEO (key-on, engine off)", expectedValue: 0, tolerance: ValueRange(min: 0, max: 5), notes: "Pump not yet primed until key-on prime pulse"),
                SensorTypicalValue(condition: "Idle, 600 rpm, warm", expectedValue: 95, tolerance: ValueRange(min: 90, max: 100), notes: "Return-less system, base pressure held by PCM command"),
                SensorTypicalValue(condition: "WOT, 6500 rpm, full boost", expectedValue: 98, tolerance: ValueRange(min: 92, max: 100), notes: "Should track Command closely; growing gap indicates flow limitation")
            ],
            physicalComponent: nil,
            physicalLocation: "Fuel rail, driver-side cylinder head, sensor threaded into rail",
            connectorRef: "2-pin weather-pack at rail sensor",
            relatedCircuit: nil,
            voltage: "5V signal, 0.5-4.5V output",
            impedance: nil,
            scannerChannels: ["FRP_ACTUAL", "Fuel Rail Pressure (Actual)", "FRPFB"],
            updateFrequency: "Continuous, ~10 Hz",
            responseLag: "Minimal",
            diagnosticPurpose: "Confirms actual fuel rail pressure matches PCM commanded pressure for closed-loop fuel delivery; critical for diagnosing pump/injector duty-cycle limits at high demand",
            relatedDTCs: ["P0087", "P0088", "P0089", "P228E", "P228F"],
            relatedProcedures: [],
            relatedCalibration: [],
            upstreamInputs: ["Fuel pump duty cycle", "In-tank filter condition", "Battery voltage under load"],
            downstreamOutputs: ["Injector pulse width calculation", "Insufficient Fuel Flow protection trigger"],
            sources: [source]
        )
    }

    static func mapBoostSensor() -> SensorRecord {
        let source = TechnicalSource(
            title: "GT500 MAP/Boost Sensor Specification",
            sourceType: "Ford WSM",
            reference: "303-14D, Manifold Absolute Pressure Sensor",
            grade: .a_factory,
            confidence: .c4
        )
        return SensorRecord(
            id: UUID(),
            name: "Manifold Absolute Pressure / Boost Sensor (MAP)",
            pidName: "MAP_ACTUAL",
            pidId: "0x0B",
            units: "psi",
            minValue: -14.7,
            maxValue: 30,
            resolution: 0.1,
            dataType: "Analog",
            typicalValues: [
                SensorTypicalValue(condition: "KOEO, sea level", expectedValue: -14.7, tolerance: ValueRange(min: -15.2, max: -14.2), notes: "Reads barometric pressure with engine off"),
                SensorTypicalValue(condition: "Idle, 600 rpm", expectedValue: -12.5, tolerance: ValueRange(min: -14, max: -10), notes: "Engine vacuum at idle"),
                SensorTypicalValue(condition: "WOT, peak boost, TVS R2650 stock pulley", expectedValue: 12, tolerance: ValueRange(min: 11, max: 15), notes: "Stock boost target ~12 psi gauge; datasheet range reflects R2650 stock configuration")
            ],
            physicalComponent: nil,
            physicalLocation: "Intake manifold, post-supercharger discharge, downstream of charge air cooler",
            connectorRef: "3-pin sensor connector on intake manifold",
            relatedCircuit: nil,
            voltage: "5V signal, 0.2-4.8V output",
            impedance: nil,
            scannerChannels: ["MAP_ACTUAL", "Manifold Absolute Pressure", "Boost (calculated gauge)"],
            updateFrequency: "Continuous, ~10-20 Hz",
            responseLag: "Minimal",
            diagnosticPurpose: "Primary load input for fueling, timing, and boost-control strategy; used to confirm actual boost against commanded target for underboost/overboost diagnosis",
            relatedDTCs: ["P0106", "P0107", "P0108", "P0299", "P0234"],
            relatedProcedures: [],
            relatedCalibration: [],
            upstreamInputs: ["Supercharger drive belt condition", "Bypass valve position", "Throttle angle", "Ambient/barometric pressure"],
            downstreamOutputs: ["Boost control strategy (bypass valve duty)", "Spark timing table lookup", "Fuel injector pulse width"],
            sources: [source]
        )
    }

    static func iat2Sensor() -> SensorRecord {
        let source = TechnicalSource(
            title: "GT500 Charge Air Temperature Sensor",
            sourceType: "Ford WSM",
            reference: "303-14D, Intake Air Temperature Sensor 2 (post-intercooler)",
            grade: .a_factory,
            confidence: .c3
        )
        return SensorRecord(
            id: UUID(),
            name: "Intake Air Temperature Sensor 2 (IAT2, post-intercooler)",
            pidName: "IAT2_ACTUAL",
            pidId: "0x1F",
            units: "°C",
            minValue: -40,
            maxValue: 150,
            resolution: 0.5,
            dataType: "Analog",
            typicalValues: [
                SensorTypicalValue(condition: "Cold start, ambient 20°C", expectedValue: 22, tolerance: ValueRange(min: 18, max: 28), notes: "Should closely track ambient before boost is applied"),
                SensorTypicalValue(condition: "Sustained WOT pull, single pass", expectedValue: 45, tolerance: ValueRange(min: 35, max: 55), notes: "Rise from compression heat, partially offset by charge air cooler"),
                SensorTypicalValue(condition: "Repeated WOT pulls, track day, heat-soaked", expectedValue: 70, tolerance: ValueRange(min: 60, max: 85), notes: "CAC coolant loop heat-soak; power may be pulled back via thermal protection above this range")
            ],
            physicalComponent: nil,
            physicalLocation: "Intake manifold, downstream of charge air cooler core, upstream of intake valves",
            connectorRef: "2-pin sensor connector on intake manifold runner",
            relatedCircuit: nil,
            voltage: "5V signal, thermistor-based, inverse voltage/temp curve",
            impedance: "NTC thermistor, ~2.5kΩ at 25°C",
            scannerChannels: ["IAT2_ACTUAL", "Intake Air Temp 2", "Charge Air Temp"],
            updateFrequency: "Continuous, ~5-10 Hz",
            responseLag: "~1-2s thermal response lag",
            diagnosticPurpose: "Detects charge air cooler heat soak during sustained high-load use; PCM uses IAT2 to trigger timing/boost pullback protection strategies",
            relatedDTCs: ["P0111", "P0112", "P0113"],
            relatedProcedures: [],
            relatedCalibration: [],
            upstreamInputs: ["Charge air cooler coolant loop temperature", "Ambient temperature", "Boost level/compression heating"],
            downstreamOutputs: ["Spark timing correction table", "Thermal-protection power pullback strategy"],
            sources: [source]
        )
    }

    static func knockSensorPID() -> SensorRecord {
        let source = TechnicalSource(
            title: "5.2L Predator Knock Retard Strategy",
            sourceType: "HP Tuners Doc",
            reference: "TC-298B knock control PIDs",
            grade: .b_professional,
            confidence: .c3
        )
        return SensorRecord(
            id: UUID(),
            name: "Knock Retard (Bank 1 / Bank 2)",
            pidName: "KNOCK_RETARD_B1",
            pidId: "0x33 (derived, not raw sensor)",
            units: "° (degrees timing retard)",
            minValue: 0,
            maxValue: 20,
            resolution: 0.1875,
            dataType: "Analog",
            typicalValues: [
                SensorTypicalValue(condition: "Idle/cruise, 93 octane", expectedValue: 0, tolerance: ValueRange(min: 0, max: 1), notes: "No retard expected under light load on spec fuel"),
                SensorTypicalValue(condition: "WOT pull, 93 octane, healthy engine", expectedValue: 0.5, tolerance: ValueRange(min: 0, max: 2), notes: "Brief adaptive retard is normal; should not persist"),
                SensorTypicalValue(condition: "WOT pull, marginal fuel or heat soak", expectedValue: 4, tolerance: ValueRange(min: 2, max: 8), notes: "Sustained retard above ~2-3° on multiple cylinders across repeated pulls warrants investigation")
            ],
            physicalComponent: nil,
            physicalLocation: "Derived PCM value from Knock Sensor 1/2 circuit signal processing",
            connectorRef: nil,
            relatedCircuit: nil,
            voltage: nil,
            impedance: nil,
            scannerChannels: ["Knock Retard Bank 1", "Knock Retard Bank 2", "KR_B1", "KR_B2"],
            updateFrequency: "Per cylinder event",
            responseLag: "Near-immediate, within one combustion cycle",
            diagnosticPurpose: "Direct indicator of detonation/pre-ignition protection activity; used to validate fuel octane adequacy and tune safety margin",
            relatedDTCs: ["P0325", "P0326", "P0330", "P0331"],
            relatedProcedures: [],
            relatedCalibration: [],
            upstreamInputs: ["Knock sensor signal quality", "Fuel octane rating", "IAT2/charge temperature", "Spark timing table commanded value"],
            downstreamOutputs: ["Actual spark timing applied", "Long-term knock learn/adaptive table"],
            sources: [source]
        )
    }

    static func widebandO2SensorPID() -> SensorRecord {
        let source = TechnicalSource(
            title: "GT500 Wideband Lambda PID Reference",
            sourceType: "HP Tuners Doc",
            reference: "WRAF lambda/equivalence ratio channels",
            grade: .b_professional,
            confidence: .c4
        )
        return SensorRecord(
            id: UUID(),
            name: "Wideband O2 Lambda, Bank 1 Sensor 1",
            pidName: "LAMBDA_B1S1",
            pidId: "0x24",
            units: "lambda",
            minValue: 0.5,
            maxValue: 1.5,
            resolution: 0.001,
            dataType: "Analog",
            typicalValues: [
                SensorTypicalValue(condition: "Closed loop idle, warm", expectedValue: 1.0, tolerance: ValueRange(min: 0.97, max: 1.03), notes: "14.64:1 stoichiometric AFR for pump gasoline"),
                SensorTypicalValue(condition: "Cruise, light load", expectedValue: 1.0, tolerance: ValueRange(min: 0.95, max: 1.05), notes: "Closed-loop trim active"),
                SensorTypicalValue(condition: "WOT, full boost, 93 octane calibration", expectedValue: 0.82, tolerance: ValueRange(min: 0.78, max: 0.86), notes: "Commanded rich for detonation margin and EGT control under boost")
            ],
            physicalComponent: nil,
            physicalLocation: "Pre-catalyst, exhaust manifold collector",
            connectorRef: "5-pin WRAF sensor connector",
            relatedCircuit: nil,
            voltage: "Pump cell current signal, μA range",
            impedance: nil,
            scannerChannels: ["Lambda B1S1", "EQ_RATIO_B1", "AFR (calculated)"],
            updateFrequency: "Continuous, ~10 Hz",
            responseLag: "~50-100 ms sensor response",
            diagnosticPurpose: "Confirms actual air/fuel ratio tracks commanded target, particularly the WOT enrichment table; primary tool for diagnosing lean/rich conditions and fuel trim faults",
            relatedDTCs: ["P0171", "P0174", "P0131", "P0132"],
            relatedProcedures: [],
            relatedCalibration: [],
            upstreamInputs: ["Fuel rail pressure", "Injector pulse width", "MAF/MAP-derived airflow estimate"],
            downstreamOutputs: ["Short-term and long-term fuel trims", "Rich/lean protection strategy"],
            sources: [source]
        )
    }

}
