import Foundation

// MARK: - Query Result Types

struct ComponentDeepDive: Codable {
    var component: ComponentRecord
    var upstream: [ComponentRecord]
    var downstream: [ComponentRecord]
    var relatedCircuits: [CircuitRecord]
    var relatedSensors: [SensorRecord]
    var relatedCalibration: [CalibrationRecord]
    var relatedProcedures: [ProcedureRecord]
    var relatedDTCs: [DTCRecord]
}

struct SymptomDiagnosis: Codable {
    var symptom: String
    var possibleDTCs: [DTCRecord] = []
    var relatedComponents: [ComponentRecord] = []
    var relatedCircuits: [CircuitRecord] = []
    var relatedSensors: [SensorRecord] = []
    var diagnosticProcedures: [PinpointProcedure] = []
    var remediationProcedures: [ProcedureRecord] = []
}

struct CircuitTrace: Codable {
    var circuit: CircuitRecord
    var path: [CircuitNode]
    var testPoints: [TestPoint]
    var connectors: [ConnectorDetail]
    var relatedDTCs: [DTCRecord]
    var relatedSensors: [SensorRecord]
    var troubleshootingGuides: [ProcedureRecord]
}

struct SensorDeepDive: Codable {
    var sensor: SensorRecord
    var physicalComponent: ComponentRecord?
    var circuit: CircuitRecord?
    var calibrationTables: [CalibrationRecord]
    var relatedDTCs: [DTCRecord]
    var diagnosticProcedures: [ProcedureRecord]
    var upstreamFactors: [String]
    var downstreamDependents: [String]
}

struct DTCDiagnosisTree: Codable {
    var dtc: DTCRecord
    var relatedComponent: ComponentRecord?
    var circuits: [CircuitRecord]
    var sensors: [SensorRecord]
    var pinpointProcedure: PinpointProcedure
    var knownIssues: [KnownIssue]
    var remediationProcedures: [ProcedureRecord]
    var commonlyOccursWith: [DTCRecord]
}

struct ModificationImpactAnalysis: Codable {
    var modification: ModificationChange
    var affectedCalibration: [CalibrationRecord] = []
    var relatedProcedures: [ProcedureRecord] = []
    var validationSteps: [String] = []
    var riskFactors: [String] = []

    func summary() -> String {
        """
        Modification: \(modification.description)

        Affected calibration tables: \(affectedCalibration.count)
        Related procedures: \(relatedProcedures.count)

        Validation steps:
        \(validationSteps.enumerated().map { "  \($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        """
    }
}

enum ModificationChange: Codable {
    case injectorUpgrade(cc: Double)
    case pulleyDownsize(ratio: Double)
    case brakePadUpgrade(compound: String)
    case suspensionChange(type: String)

    var description: String {
        switch self {
        case .injectorUpgrade(let cc):
            return "Injector upgrade to \(cc) cc/min"
        case .pulleyDownsize(let ratio):
            return "Pulley downsized to \(String(format: "%.2f", ratio)):1 ratio"
        case .brakePadUpgrade(let compound):
            return "Brake pad upgrade: \(compound)"
        case .suspensionChange(let type):
            return "Suspension modification: \(type)"
        }
    }
}

struct ProcedureWithContext: Codable {
    var procedure: ProcedureRecord
    var components: [ComponentRecord]
    var circuits: [CircuitRecord]
    var sensors: [SensorRecord]
    var clearedDTCs: [DTCRecord]
    var relatedCalibration: [CalibrationRecord]
    var prerequisites: [ProcedureRecord]
    var followUps: [ProcedureRecord]

    var completeProcedure: Bool {
        prerequisites.isEmpty // Can start immediately
    }
}

struct CrossDomainSearchResults: Codable {
    var query: String
    var components: [ComponentRecord] = []
    var circuits: [CircuitRecord] = []
    var sensors: [SensorRecord] = []
    var dtcs: [DTCRecord] = []
    var procedures: [ProcedureRecord] = []
    var calibration: [CalibrationRecord] = []

    var totalResults: Int {
        components.count + circuits.count + sensors.count + dtcs.count + procedures.count + calibration.count
    }

    var summary: String {
        """
        Search results for: "\(query)"

        Components: \(components.count)
        Circuits: \(circuits.count)
        Sensors: \(sensors.count)
        DTCs: \(dtcs.count)
        Procedures: \(procedures.count)
        Calibration: \(calibration.count)

        Total: \(totalResults) results
        """
    }
}

struct DiagnosisConfidenceScore: Codable {
    var componentKnown: Bool = false
    var circuitCoverage: Double = 0.0 // 0.0-1.0
    var sensorCoverage: Double = 0.0
    var pinpointProcedureExists: Bool = false
    var knownIssuesDocumented: Bool = false
    var remediationAvailable: Bool = false
    var averageSourceGrade: Double = 0.0 // 0.4-1.0 based on SourceGrade.weight

    var overallConfidence: Double {
        let factors = [
            componentKnown ? 1.0 : 0.0,
            circuitCoverage,
            sensorCoverage,
            pinpointProcedureExists ? 1.0 : 0.0,
            knownIssuesDocumented ? 1.0 : 0.0,
            remediationAvailable ? 1.0 : 0.0,
            averageSourceGrade
        ]
        return factors.reduce(0, +) / Double(factors.count)
    }

    var confidenceLevel: String {
        switch overallConfidence {
        case 0.85...: return "High confidence"
        case 0.70..<0.85: return "Good confidence"
        case 0.50..<0.70: return "Moderate confidence"
        case 0.30..<0.50: return "Low confidence"
        default: return "Insufficient data"
        }
    }
}
