// PredatorLab/Services/TechnicalQueryEngine.swift
// Cross-domain query interface for integrated technical knowledge

import Foundation
import Combine

class TechnicalQueryEngine: ObservableObject {

    // In-memory database (in production: CoreData, CloudKit, or backend)
    @Published var components: [ComponentRecord] = []
    @Published var circuits: [CircuitRecord] = []
    @Published var sensors: [SensorRecord] = []
    @Published var dtcs: [DTCRecord] = []
    @Published var procedures: [ProcedureRecord] = []
    @Published var calibration: [CalibrationRecord] = []

    // MARK: - Query Type 1: Component Deep Dive

    /// Retrieve everything about a component and its relationships
    func queryComponent(named name: String) -> ComponentDeepDive? {
        guard let component = components.first(where: { $0.name.lowercased().contains(name.lowercased()) }) else {
            return nil
        }

        return ComponentDeepDive(
            component: component,

            // Find all upstream components
            upstream: components.filter { comp in
                component.upstreamComponents.contains(comp.id)
            },

            // Find all downstream components
            downstream: components.filter { comp in
                component.downstreamComponents.contains(comp.id)
            },

            // Find all related circuits
            relatedCircuits: circuits.filter { circ in
                component.relatedCircuits.contains(circ.id)
            },

            // Find all related sensors
            relatedSensors: sensors.filter { sensor in
                component.relatedSensors.contains(sensor.id)
            },

            // Find all related calibration tables
            relatedCalibration: calibration.filter { cal in
                component.relatedCalibration.contains(cal.id)
            },

            // Find all procedures that involve this component
            relatedProcedures: procedures.filter { proc in
                proc.relatedComponents.contains(component.id)
            },

            // Find all DTCs related to component failure
            relatedDTCs: dtcs.filter { dtc in
                dtc.relatedComponent == component.id
            }
        )
    }

    // MARK: - Query Type 2: Symptom-to-Root-Cause

    /// Diagnose a symptom and find related components, tests, procedures
    func diagnoseSymptom(_ symptom: String) -> SymptomDiagnosis {

        var diagnosis = SymptomDiagnosis(symptom: symptom)

        // Find DTCs that mention this symptom
        let relevantDTCs = dtcs.filter { dtc in
            dtc.knownIssues.contains { issue in
                issue.symptoms.contains { s in
                    s.lowercased().contains(symptom.lowercased())
                }
            }
        }
        diagnosis.possibleDTCs = relevantDTCs

        // For each DTC, find related components, circuits, sensors
        for dtc in relevantDTCs {
            if let componentId = dtc.relatedComponent {
                if let component = components.first(where: { $0.id == componentId }) {
                    diagnosis.relatedComponents.append(component)
                }
            }

            diagnosis.relatedCircuits.append(contentsOf: circuits.filter { circ in
                dtc.relatedCircuits.contains(circ.id)
            })

            diagnosis.relatedSensors.append(contentsOf: sensors.filter { sensor in
                dtc.relatedSensors.contains(sensor.id)
            })
        }

        // Find diagnostic procedures
        for dtc in relevantDTCs {
            diagnosis.diagnosticProcedures.append(dtc.pinpointTest)
        }

        // Find service procedures that address this
        diagnosis.remediationProcedures = procedures.filter { proc in
            proc.purpose.lowercased().contains(symptom.lowercased()) ||
            proc.relatedDTCs.contains { dtc_id in
                relevantDTCs.contains { $0.id == dtc_id }
            }
        }

        return diagnosis
    }

    // MARK: - Query Type 3: Circuit Tracing

    /// Trace a circuit from power source to ground
    func traceCircuit(_ circuitName: String) -> CircuitTrace? {
        guard let circuit = circuits.first(where: { $0.name.lowercased().contains(circuitName.lowercased()) }) else {
            return nil
        }

        return CircuitTrace(
            circuit: circuit,
            path: circuit.path, // Already in order

            // Find test points along the path
            testPoints: circuit.testPoints,

            // Find all connectors in this circuit
            connectors: circuit.connectors,

            // Find related DTCs
            relatedDTCs: dtcs.filter { dtc in
                dtc.relatedCircuits.contains(circuit.id)
            },

            // Find related sensors on this circuit
            relatedSensors: sensors.filter { sensor in
                sensor.relatedCircuit == circuit.id
            },

            // Find troubleshooting procedures
            troubleshootingGuides: procedures.filter { proc in
                proc.relatedCircuits.contains(circuit.id)
            }
        )
    }

    // MARK: - Query Type 4: PID/Sensor Deep Dive

    /// Get complete sensor information including circuit, component, and typical values
    func querySensor(_ pidName: String) -> SensorDeepDive? {
        guard let sensor = sensors.first(where: {
            $0.pidName?.lowercased() == pidName.lowercased() ||
            $0.name.lowercased().contains(pidName.lowercased())
        }) else {
            return nil
        }

        return SensorDeepDive(
            sensor: sensor,

            // Physical component this sensor measures
            physicalComponent: sensor.physicalComponent.flatMap { id in
                components.first(where: { $0.id == id })
            },

            // Circuit the sensor is on
            circuit: sensor.relatedCircuit.flatMap { id in
                circuits.first(where: { $0.id == id })
            },

            // Calibration tables that use this sensor
            calibrationTables: calibration.filter { cal in
                cal.relatedSensors.contains(sensor.id)
            },

            // DTCs related to this sensor
            relatedDTCs: dtcs.filter { dtc in
                dtc.relatedSensors.contains(sensor.id)
            },

            // Diagnostic procedures for this sensor
            diagnosticProcedures: procedures.filter { proc in
                proc.relatedSensors.contains(sensor.id)
            },

            // What inputs affect this sensor's reading
            upstreamFactors: sensor.upstreamInputs,

            // What systems depend on this sensor's accuracy
            downstreamDependents: sensor.downstreamOutputs
        )
    }

    // MARK: - Query Type 5: DTC Complete Diagnosis Tree

    /// Get everything needed to diagnose a specific DTC
    func diagnoseDTC(_ dtcCode: String) -> DTCDiagnosisTree? {
        guard let dtc = dtcs.first(where: { $0.code == dtcCode }) else {
            return nil
        }

        return DTCDiagnosisTree(
            dtc: dtc,

            // Physical component this DTC relates to
            relatedComponent: dtc.relatedComponent.flatMap { id in
                components.first(where: { $0.id == id })
            },

            // Circuits involved
            circuits: circuits.filter { circ in
                dtc.relatedCircuits.contains(circ.id)
            },

            // Sensors involved
            sensors: sensors.filter { sensor in
                dtc.relatedSensors.contains(sensor.id)
            },

            // Step-by-step pinpoint test
            pinpointProcedure: dtc.pinpointTest,

            // Known issues / TSBs
            knownIssues: dtc.knownIssues,

            // Service procedures to fix it
            remediationProcedures: procedures.filter { proc in
                proc.relatedDTCs.contains(dtc.id)
            },

            // Related DTCs that often occur together
            commonlyOccursWith: dtcs.filter { other in
                other.relatedComponent == dtc.relatedComponent &&
                other.id != dtc.id
            }
        )
    }

    // MARK: - Query Type 6: Modification Impact Analysis

    /// Analyze the impact of a modification across all systems
    func analyzeModificationImpact(_ modification: ModificationChange) -> ModificationImpactAnalysis {

        var analysis = ModificationImpactAnalysis(modification: modification)

        switch modification {
        case .injectorUpgrade:
            // Find all calibration tables that depend on injector specs
            analysis.affectedCalibration = calibration.filter { cal in
                cal.function.lowercased().contains("fuel") ||
                cal.function.lowercased().contains("injector") ||
                cal.function.lowercased().contains("pressure")
            }

            // Find all procedures related to fuel
            analysis.relatedProcedures = procedures.filter { proc in
                proc.relatedComponents.contains { id in
                    components.first(where: { $0.id == id })?.name.lowercased().contains("injector") ?? false
                }
            }

            // Validation requirements
            analysis.validationSteps = [
                "Characterize new injector flow rate in HP Tuners",
                "Update Torque Inverse Calculator with new spec",
                "Verify fuel pressure during WOT pull",
                "Confirm lambda response to commands",
                "Dyno validation: compare torque curve",
                "Log R04 insufficient fuel flow during extended load test"
            ]

        case .pulleyDownsize:
            // Find boost-related calibration
            analysis.affectedCalibration = calibration.filter { cal in
                cal.function.lowercased().contains("boost") ||
                cal.function.lowercased().contains("supercharger") ||
                cal.function.lowercased().contains("blower")
            }

            // All fuel calibration needs revalidation
            analysis.affectedCalibration.append(contentsOf: calibration.filter { cal in
                cal.function.lowercased().contains("fuel")
            })

            analysis.validationSteps = [
                "Confirm belt tension and alignment",
                "Dyno validation: boost curve vs. engine RPM",
                "Verify fuel response to new boost levels",
                "Thermal validation: IAT2 stability",
                "DCT thermal validation: shift quality",
                "Extended load test: no protection events"
            ]

        case .brakePadUpgrade, .suspensionChange:
            // These don't affect calibration but need procedures
            analysis.relatedProcedures = procedures.filter { proc in
                proc.relatedComponents.contains { id in
                    let comp = components.first(where: { $0.id == id })
                    return comp?.section == .brakes || comp?.section == .suspension
                }
            }
        }

        return analysis
    }

    // MARK: - Query Type 7: Workshop Procedure with Full Context

    /// Get a procedure with all linked technical information
    func getProcedureWithContext(_ procedureName: String) -> ProcedureWithContext? {
        guard let procedure = procedures.first(where: {
            $0.name.lowercased().contains(procedureName.lowercased())
        }) else {
            return nil
        }

        return ProcedureWithContext(
            procedure: procedure,

            // Components involved
            components: components.filter { comp in
                procedure.relatedComponents.contains(comp.id)
            },

            // Circuits touched
            circuits: circuits.filter { circ in
                procedure.relatedCircuits.contains(circ.id)
            },

            // Sensors involved
            sensors: sensors.filter { sensor in
                procedure.relatedSensors.contains(sensor.id)
            },

            // DTCs cleared by this procedure
            clearedDTCs: dtcs.filter { dtc in
                procedure.relatedDTCs.contains(dtc.id)
            },

            // Calibration that affects this procedure
            relatedCalibration: calibration.filter { cal in
                procedure.relatedCalibration.contains(cal.id)
            },

            // Prerequisites that must be done first
            prerequisites: procedures.filter { prep in
                procedure.relatedProcedures.contains(prep.id)
            },

            // Follow-up procedures to do after
            followUps: procedures.filter { followup in
                followup.relatedProcedures.contains(procedure.id)
            }
        )
    }

    // MARK: - Query Type 8: Cross-Domain Search

    /// Search across all databases for a keyword
    func crossDomainSearch(_ query: String, gradeFilter: SourceGrade? = nil) -> CrossDomainSearchResults {

        var results = CrossDomainSearchResults(query: query)
        let queryLower = query.lowercased()

        // Search components
        results.components = components.filter { comp in
            (comp.name.lowercased().contains(queryLower) ||
             comp.specifications.contains { $0.parameter.lowercased().contains(queryLower) }) &&
            (gradeFilter == nil || comp.sources.contains { $0.grade == gradeFilter })
        }

        // Search circuits
        results.circuits = circuits.filter { circ in
            (circ.name.lowercased().contains(queryLower) ||
             circ.path.contains { $0.designation.lowercased().contains(queryLower) }) &&
            (gradeFilter == nil || circ.sources.contains { $0.grade == gradeFilter })
        }

        // Search sensors
        results.sensors = sensors.filter { sensor in
            (sensor.name.lowercased().contains(queryLower) ||
             sensor.pidName?.lowercased().contains(queryLower) ?? false) &&
            (gradeFilter == nil || sensor.sources.contains { $0.grade == gradeFilter })
        }

        // Search DTCs
        results.dtcs = dtcs.filter { dtc in
            (dtc.code.lowercased().contains(queryLower) ||
             dtc.title.lowercased().contains(queryLower) ||
             dtc.description.lowercased().contains(queryLower)) &&
            (gradeFilter == nil || dtc.sources.contains { $0.grade == gradeFilter })
        }

        // Search procedures
        results.procedures = procedures.filter { proc in
            (proc.name.lowercased().contains(queryLower) ||
             proc.purpose.lowercased().contains(queryLower)) &&
            (gradeFilter == nil || proc.sources.contains { $0.grade == gradeFilter })
        }

        // Search calibration
        results.calibration = calibration.filter { cal in
            (cal.name.lowercased().contains(queryLower) ||
             cal.vcmPath?.lowercased().contains(queryLower) ?? false) &&
            (gradeFilter == nil || cal.sources.contains { $0.grade == gradeFilter })
        }

        return results
    }

    // MARK: - Confidence Scoring

    /// Score how complete and trustworthy a diagnosis is
    func scoreCompleteness(diagnosis: DTCDiagnosisTree) -> DiagnosisConfidenceScore {

        var score = DiagnosisConfidenceScore()

        // Component documented?
        if diagnosis.relatedComponent != nil {
            score.componentKnown = true
        }

        // All circuits documented?
        score.circuitCoverage = Double(diagnosis.circuits.count) / max(1.0, Double(diagnosis.dtc.relatedCircuits.count))

        // All sensors documented?
        score.sensorCoverage = Double(diagnosis.sensors.count) / max(1.0, Double(diagnosis.dtc.relatedSensors.count))

        // Pinpoint procedure exists?
        score.pinpointProcedureExists = true

        // Known issues documented?
        score.knownIssuesDocumented = !diagnosis.knownIssues.isEmpty

        // Remediation procedures available?
        score.remediationAvailable = !diagnosis.remediationProcedures.isEmpty

        // Source grades
        let sourceGrades = diagnosis.dtc.sources.map { $0.grade.weight }
        score.averageSourceGrade = sourceGrades.isEmpty ? 0.4 : sourceGrades.reduce(0, +) / Double(sourceGrades.count)

        return score
    }
}
