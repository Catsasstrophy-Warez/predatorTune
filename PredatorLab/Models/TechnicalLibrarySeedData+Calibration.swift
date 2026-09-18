// Rev39 decomposed technical seed category. Evidence status preserved from authored source.
import Foundation

extension TechnicalLibrarySeedData {
    // MARK: - Calibration

    static func seedCalibration() -> [CalibrationRecord] {
        [fuelRailPressureTargetTable(), boostTargetTable(), sparkTimingTable(), injectorPulseWidthTable()]
    }

    static func fuelRailPressureTargetTable() -> CalibrationRecord {
        let source = TechnicalSource(title: "GT500 Fuel Rail Pressure Control Strategy", sourceType: "HP Tuners Doc", reference: "VCM Editor fuel pressure tables", grade: .b_professional, confidence: .c3)
        return CalibrationRecord(
            id: UUID(),
            name: "Fuel Rail Pressure Target Table",
            section: "Engine",
            tableType: "Lookup table",
            vcmPath: "Engine → Fuel → Fuel Rail Pressure → FRP Command vs RPM/Load",
            vcmDisplayName: "FRP_TARGET_TBL",
            parameterID: "FRP_TARGET",
            axes: CalibrationAxes(xAxis: "Engine RPM", xMin: 600, xMax: 7300, xStep: 500, yAxis: "Calculated Load", yMin: 0.2, yMax: 2.5, yStep: 0.2, zAxis: nil, zMin: nil, zMax: nil),
            stockValues: [
                [55, 60, 65, 70, 75, 80, 85, 90, 95, 95, 95, 95, 95, 95, 95],
                [55, 62, 68, 74, 80, 86, 90, 93, 96, 97, 97, 97, 97, 97, 97],
                [55, 63, 70, 77, 83, 88, 92, 95, 97, 98, 98, 98, 98, 98, 98]
            ],
            units: "psi",
            resolution: 0.5,
            displayFormat: "0.0",
            function: "Determines the base commanded fuel rail pressure as a function of engine RPM and calculated load, providing the fueling system a pressure target the FPDM/pump duty control tries to hold",
            role: "Input",
            controlStrategy: "PCM closed-loop fuel pressure control via FPDM pump duty modulation",
            relatedSensors: [],
            relatedDTCs: [],
            relatedComponents: [],
            upstream: [
                CalibrationLink(relatedTable: "Boost Target Table", relationship: "Feeds input to", consequence: "Higher boost/load targets increase the load axis lookup, raising the commanded rail pressure", evidence: "Load axis is derived from MAP/airflow, which is itself boost-dependent")
            ],
            downstream: [
                CalibrationLink(relatedTable: "Injector Pulse Width Table", relationship: "Validates against", consequence: "Injector pulse width calculation assumes this rail pressure target is achieved; a pressure shortfall causes actual delivered fuel mass to fall short of commanded", evidence: "Injector flow characteristics are pressure-dependent per injector flow curve")
            ],
            modificationPrerequisites: ["Upgraded fuel pump and/or filter if raising pressure targets beyond stock for higher injector flow needs"],
            modificationGuidance: "Raising FRP targets increases effective injector flow without changing injector hardware, but is bounded by pump capacity and injector duty-cycle margin at high RPM — verify with a logged WOT pull that Actual tracks Command before committing to a higher target.",
            knownCrosslinks: [
                CrosslinkWarning(
                    warning: "Increasing FRP target without verifying pump headroom risks a pressure droop under sustained WOT",
                    relatedTables: ["Injector Pulse Width Table", "Boost Target Table"],
                    consequence: "Actual pressure falls short of the raised command, causing an unintended lean condition at high load",
                    validation: "Data-log Fuel Rail Pressure Actual vs Command and Pump Duty Cycle across a full WOT pull after any FRP target change"
                )
            ],
            sources: [source],
            historicalData: nil
        )
    }

    static func boostTargetTable() -> CalibrationRecord {
        let source = TechnicalSource(title: "GT500 Boost Control Strategy", sourceType: "HP Tuners Doc", reference: "VCM Editor boost control tables", grade: .b_professional, confidence: .c3)
        return CalibrationRecord(
            id: UUID(),
            name: "Boost Target Table",
            section: "Supercharger",
            tableType: "Lookup table",
            vcmPath: "Engine → Boost Control → Boost Target vs RPM/Throttle",
            vcmDisplayName: "BOOST_TARGET_TBL",
            parameterID: "BOOST_TARGET",
            axes: CalibrationAxes(xAxis: "Engine RPM", xMin: 1500, xMax: 7300, xStep: 500, yAxis: "Throttle Angle", yMin: 10, yMax: 100, yStep: 10, zAxis: nil, zMin: nil, zMax: nil),
            stockValues: [
                [2, 4, 6, 8, 9, 10, 11, 12, 12, 12],
                [3, 5, 7, 9, 10, 11, 12, 12, 12, 12],
                [3, 6, 8, 10, 11, 12, 12, 12, 12, 12]
            ],
            units: "psi gauge",
            resolution: 0.1,
            displayFormat: "0.0",
            function: "Commands target boost pressure (via the bypass valve) as a function of RPM and throttle angle, capped near stock 12 psi for the TVS R2650",
            role: "Input",
            controlStrategy: "PCM closed-loop boost control via bypass valve duty, referenced against MAP sensor feedback",
            relatedSensors: [],
            relatedDTCs: [],
            relatedComponents: [],
            upstream: [
                CalibrationLink(relatedTable: "Throttle Angle / Driver Demand", relationship: "Feeds input to", consequence: "Higher throttle angle at a given RPM raises the boost target lookup", evidence: "Y-axis is throttle angle directly")
            ],
            downstream: [
                CalibrationLink(relatedTable: "Spark Timing Table", relationship: "Blocks this table from changing", consequence: "Raising boost target beyond the pulley/fuel system's safe margin requires a corresponding spark timing pullback to manage knock risk", evidence: "Spark table is indexed by the same RPM/load axes and must be co-tuned")
            ],
            modificationPrerequisites: ["Smaller supercharger pulley to physically exceed stock boost ceiling", "Fuel system headroom verified (pump/injector) before raising targets", "Matching spark and fuel enrichment table revisions"],
            modificationGuidance: "Boost target increases beyond stock 12 psi require a smaller pulley (mechanical boost ceiling change) plus a full recalibration of fuel and spark tables — this table alone cannot safely exceed what the supercharger can mechanically produce.",
            knownCrosslinks: [
                CrosslinkWarning(
                    warning: "Raising boost target without a pulley change has no effect since the R2650 is already near its stock mechanical boost ceiling on the stock pulley",
                    relatedTables: ["Fuel Rail Pressure Target Table", "Spark Timing Table"],
                    consequence: "Wasted tuning effort or, if a pulley is installed without table review, an uncontrolled overboost condition",
                    validation: "Confirm pulley size and log Boost Actual vs Target after any change to this table"
                )
            ],
            sources: [source],
            historicalData: nil
        )
    }

    static func sparkTimingTable() -> CalibrationRecord {
        let source = TechnicalSource(title: "5.2L Predator Spark Timing Strategy", sourceType: "HP Tuners Doc", reference: "VCM Editor spark advance tables", grade: .b_professional, confidence: .c3)
        return CalibrationRecord(
            id: UUID(),
            name: "Spark Timing Table (High Octane, 93+)",
            section: "Engine",
            tableType: "Lookup table",
            vcmPath: "Engine → Spark → Spark Advance vs RPM/Load (High Octane)",
            vcmDisplayName: "SPARK_ADV_HO_TBL",
            parameterID: "SPARK_ADV_HO",
            axes: CalibrationAxes(xAxis: "Engine RPM", xMin: 600, xMax: 7300, xStep: 500, yAxis: "Calculated Load", yMin: 0.2, yMax: 2.5, yStep: 0.2, zAxis: nil, zMin: nil, zMax: nil),
            stockValues: [
                [28, 27, 26, 24, 22, 20, 18, 17, 16, 15, 14, 13, 12, 12, 12],
                [24, 23, 22, 20, 18, 16, 15, 14, 13, 12, 11, 10, 10, 10, 10],
                [20, 19, 18, 16, 14, 12, 11, 10, 9, 8, 8, 8, 8, 8, 8]
            ],
            units: "° BTDC",
            resolution: 0.1875,
            displayFormat: "0.00",
            function: "Base spark advance commanded by RPM and calculated load on the 93-octane calibration; reduced automatically at high load/RPM to manage knock risk under boost",
            role: "Output",
            controlStrategy: "Base timing table with real-time knock-retard correction layered on top per-cylinder",
            relatedSensors: [],
            relatedDTCs: [],
            relatedComponents: [],
            upstream: [
                CalibrationLink(relatedTable: "Boost Target Table", relationship: "Blocks this table from changing", consequence: "Any boost increase requires the spark table to be pulled back further at the affected RPM/load cells to maintain knock margin", evidence: "Same RPM/load axes; higher cylinder pressure from added boost lowers the knock-limited timing ceiling")
            ],
            downstream: [
                CalibrationLink(relatedTable: "Knock Retard Adaptive Table", relationship: "Feeds input to", consequence: "Base timing sets the starting point that real-time knock retard subtracts from", evidence: "Applied Timing = Base Table − Knock Retard")
            ],
            modificationPrerequisites: ["93 octane minimum fuel confirmed", "Knock sensor circuit verified functional before adding timing"],
            modificationGuidance: "Timing should only be advanced incrementally with data-logged knock retard review after each change; never assume zero knock retard means unlimited headroom — check across the full RPM/load range including sustained track conditions where heat soak reduces margin.",
            knownCrosslinks: [
                CrosslinkWarning(
                    warning: "Adding timing without re-verifying boost/fuel table consistency risks detonation, especially at high load cells near redline",
                    relatedTables: ["Boost Target Table", "Fuel Rail Pressure Target Table"],
                    consequence: "Knock events, potential piston/ring damage under sustained high-load track use",
                    validation: "Log per-cylinder knock retard across a full WOT pull and a repeated-session track scenario before trusting a timing revision"
                )
            ],
            sources: [source],
            historicalData: nil
        )
    }

    static func injectorPulseWidthTable() -> CalibrationRecord {
        let source = TechnicalSource(title: "GT500 Injector Pulse Width Calculation", sourceType: "HP Tuners Doc", reference: "VCM Editor injector characterization tables", grade: .b_professional, confidence: .c3)
        return CalibrationRecord(
            id: UUID(),
            name: "Injector Pulse Width / Flow Characterization Table",
            section: "Fuel System",
            tableType: "Transfer function",
            vcmPath: "Engine → Fuel → Injector Characterization → Flow vs Pulse Width/Pressure",
            vcmDisplayName: "INJ_PW_XFER_TBL",
            parameterID: "INJ_FLOW_XFER",
            axes: CalibrationAxes(xAxis: "Commanded Pulse Width", xMin: 0.5, xMax: 10.0, xStep: 0.5, yAxis: "Fuel Rail Pressure", yMin: 40, yMax: 100, yStep: 10, zAxis: nil, zMin: nil, zMax: nil),
            stockValues: [
                [3.2, 6.8, 10.5, 14.1, 17.8, 21.4, 25.0],
                [3.8, 8.0, 12.3, 16.6, 20.9, 25.1, 29.4],
                [4.3, 9.1, 13.9, 18.7, 23.5, 28.3, 33.1]
            ],
            units: "lb/hr delivered",
            resolution: 0.1,
            displayFormat: "0.0",
            function: "Converts a commanded injector pulse width and actual fuel rail pressure into an expected delivered fuel mass, which the fueling strategy uses to hit the target air/fuel ratio",
            role: "Intermediate",
            controlStrategy: "Injector flow modeling feeding the fuel mass/AFR closed-loop control alongside wideband O2 trim correction",
            relatedSensors: [],
            relatedDTCs: [],
            relatedComponents: [],
            upstream: [
                CalibrationLink(relatedTable: "Fuel Rail Pressure Target Table", relationship: "Validates against", consequence: "Table accuracy depends on actual rail pressure matching the assumed pressure axis value", evidence: "Y-axis is fuel rail pressure directly")
            ],
            downstream: [
                CalibrationLink(relatedTable: "WOT Enrichment / Commanded Lambda Table", relationship: "Feeds input to", consequence: "Delivered fuel mass estimate is compared against the lambda target to close the loop", evidence: "AFR closed-loop control consumes both the flow estimate and wideband feedback")
            ],
            modificationPrerequisites: ["Correct injector flow data (manufacturer flow bench sheet) when installing non-stock injectors", "Verified fuel rail pressure control before trusting this table's output"],
            modificationGuidance: "When upgrading injectors (e.g. to ID1050X), this table must be replaced with the new injector's flow-vs-pressure characterization data, not just scaled from the stock EV14 curve — injector dynamics (dead time, linearity) differ between models and using the wrong curve causes AFR errors especially at low pulse widths (idle/cruise).",
            knownCrosslinks: [
                CrosslinkWarning(
                    warning: "Using a scaled version of the stock injector curve instead of the actual new injector's characterization data",
                    relatedTables: ["Fuel Rail Pressure Target Table", "WOT Enrichment / Commanded Lambda Table"],
                    consequence: "AFR errors most pronounced at idle and light cruise load, where injector dead-time nonlinearity matters most",
                    validation: "Compare commanded vs wideband-observed lambda across idle, cruise, and WOT after any injector or curve change; adjust curve until deviation is minimal at all three"
                )
            ],
            sources: [source],
            historicalData: nil
        )
    }
}
