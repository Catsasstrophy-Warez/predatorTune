import Foundation

enum RCAConfidence: String, Codable, CaseIterable { case insufficient, low, moderate, high }

struct RCAEvidenceStep: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: TimeInterval?
    var kind: String
    var statement: String
    var sourceID: String?
    init(id: UUID = UUID(), timestamp: TimeInterval? = nil, kind: String, statement: String, sourceID: String? = nil) {
        self.id=id; self.timestamp=timestamp; self.kind=kind; self.statement=statement; self.sourceID=sourceID
    }
}

struct PostJobRCA: Identifiable, Codable, Equatable {
    let id: UUID
    var vehicleID: UUID
    var investigationID: UUID?
    var buildStateID: UUID?
    var symptom: String
    var firstOut: [RCAEvidenceStep]
    var hypothesesConsidered: [String]
    var testsPerformed: [String]
    var changePerformed: String?
    var validationSummary: String?
    var confidence: RCAConfidence
    var unresolvedUnknowns: [String]
    var boundary: String
    var createdAt: Date
}

enum PostJobRCAEngine {
    static func build(vehicleID: UUID, investigationID: UUID? = nil, buildStateID: UUID? = nil, symptom: String, firstOut: [RCAEvidenceStep], hypotheses: [String], tests: [String], change: String?, validation: ValidationAssessment?, unknowns: [String]) -> PostJobRCA {
        let confidence: RCAConfidence
        if validation == nil { confidence = .insufficient }
        else if !unknowns.isEmpty { confidence = .moderate }
        else { confidence = .high }
        return .init(id: UUID(), vehicleID: vehicleID, investigationID: investigationID, buildStateID: buildStateID, symptom: symptom, firstOut: firstOut.sorted { ($0.timestamp ?? .greatestFiniteMagnitude) < ($1.timestamp ?? .greatestFiniteMagnitude) }, hypothesesConsidered: hypotheses, testsPerformed: tests, changePerformed: change, validationSummary: validation.map { String(describing: $0) }, confidence: confidence, unresolvedUnknowns: unknowns, boundary: "RCA summarizes recorded evidence and validation. Temporal association and improvement do not by themselves prove a unique physical cause.", createdAt: .now)
    }
}
