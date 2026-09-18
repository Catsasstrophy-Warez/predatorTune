// PredatorLab/Models/Core/InvestigationModels.swift
// Evidence system, R04 hypothesis investigation, log events, calibration atlas
// (Split from PredatorLab_CoreModels.swift — AppState class extracted into State/AppState.swift)

import Foundation

// MARK: - Evidence System

enum EvidenceLevel: String, Codable, CaseIterable, Identifiable {
    case verified = "Verified"
    case observed = "Observed"
    case strategySpecific = "Strategy-Specific"
    case researchHypothesis = "Research Hypothesis"
    case rejected = "Rejected / Not Applicable"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .verified: return "green"
        case .observed: return "blue"
        case .strategySpecific: return "orange"
        case .researchHypothesis: return "yellow"
        case .rejected: return "red"
        }
    }
}

enum ConfidenceLevel: Int, Codable, CaseIterable, Identifiable {
    case c0 = 0
    case c1 = 1
    case c2 = 2
    case c3 = 3
    case c4 = 4
    case c5 = 5

    var id: Int { rawValue }

    static var high: Self { .c3 }

    var title: String {
        switch self {
        case .c0: return "Unknown"
        case .c1: return "Plausible"
        case .c2: return "Supported"
        case .c3: return "Reproduced"
        case .c4: return "Independently Validated"
        case .c5: return "Calibration Validated"
        }
    }
}

struct EvidenceSource: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var organization: String?
    var url: URL?
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        organization: String? = nil,
        url: URL? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.organization = organization
        self.url = url
        self.notes = notes
    }
}

struct EvidenceRecord: Identifiable, Codable {
    let id: UUID
    var statement: String
    var level: EvidenceLevel
    var confidence: ConfidenceLevel
    var supportingSources: [EvidenceSource]
    var contradictoryEvidence: [String]
    var missingEvidence: [String]

    init(
        id: UUID = UUID(),
        statement: String,
        level: EvidenceLevel,
        confidence: ConfidenceLevel,
        supportingSources: [EvidenceSource] = [],
        contradictoryEvidence: [String] = [],
        missingEvidence: [String] = []
    ) {
        self.id = id
        self.statement = statement
        self.level = level
        self.confidence = confidence
        self.supportingSources = supportingSources
        self.contradictoryEvidence = contradictoryEvidence
        self.missingEvidence = missingEvidence
    }
}

// MARK: - R04 Hypothesis Investigation

enum R04HypothesisID: String, Codable, CaseIterable, Identifiable {
    case h1aInjectorCapacity = "H1A"
    case h1bInjectionWindow = "H1B"
    case h2PumpPressure = "H2"
    case h3ModeledFlowLimit = "H3"
    case h4DCTTransient = "H4"
    case h5PIDIdentity = "H5"
    case h6SecondaryProtection = "H6"
    case h7PressureStrategy = "H7"

    var id: String { rawValue }
}

struct DiagnosticHypothesis: Identifiable, Codable {
    let id: R04HypothesisID

    var title: String
    var description: String

    var supportingEvidence: [String]
    var contradictingEvidence: [String]
    var requiredEvidence: [String]

    var confidence: ConfidenceLevel
    var isPlausible: Bool

    var nextMeasurements: [String]

    init(
        id: R04HypothesisID,
        title: String,
        description: String,
        supportingEvidence: [String] = [],
        contradictingEvidence: [String] = [],
        requiredEvidence: [String] = [],
        confidence: ConfidenceLevel = .c0,
        isPlausible: Bool = false,
        nextMeasurements: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.supportingEvidence = supportingEvidence
        self.contradictingEvidence = contradictingEvidence
        self.requiredEvidence = requiredEvidence
        self.confidence = confidence
        self.isPlausible = isPlausible
        self.nextMeasurements = nextMeasurements
    }
}

struct Investigation: Identifiable, Codable {
    let id: UUID
    var vehicleID: UUID
    var phase: TuningPhase
    var problem: String

    var hypotheses: [DiagnosticHypothesis]
    var supportingLogs: [UUID]
    var evidence: [EvidenceRecord]

    var conclusion: String?
    var recommendedAction: String?

    var startDate: Date
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        phase: TuningPhase,
        problem: String,
        hypotheses: [DiagnosticHypothesis] = [],
        supportingLogs: [UUID] = [],
        evidence: [EvidenceRecord] = [],
        conclusion: String? = nil,
        recommendedAction: String? = nil,
        startDate: Date = .now,
        lastUpdated: Date = .now
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.phase = phase
        self.problem = problem
        self.hypotheses = hypotheses
        self.supportingLogs = supportingLogs
        self.evidence = evidence
        self.conclusion = conclusion
        self.recommendedAction = recommendedAction
        self.startDate = startDate
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Logging & Events

struct ImportedLog: Identifiable, Codable {
    let id: UUID
    var filename: String
    var fileURL: URL?
    var vehicleID: UUID
    var buildStateID: UUID?

    var channels: [String]
    var sampleCount: Int
    var duration: TimeInterval
    var timestamps: [TimeInterval]

    var condition: String // "cold", "intermediate", "heat-soak"
    var temperature: String // IAT2 range
    var notes: String

    var importDate: Date
    var analyzedDate: Date?

    var events: [LogEvent]
    var sourceSHA256: String?
    var analysisEngineVersion: AnalysisEngineVersion?
    var analysisRevisions: [AnalysisRevision]?

    init(
        id: UUID = UUID(),
        filename: String,
        fileURL: URL? = nil,
        vehicleID: UUID,
        buildStateID: UUID? = nil,
        channels: [String] = [],
        sampleCount: Int = 0,
        duration: TimeInterval = 0,
        timestamps: [TimeInterval] = [],
        condition: String = "unknown",
        temperature: String = "unknown",
        notes: String = "",
        importDate: Date = .now,
        analyzedDate: Date? = nil,
        events: [LogEvent] = [],
        sourceSHA256: String? = nil,
        analysisEngineVersion: AnalysisEngineVersion? = nil,
        analysisRevisions: [AnalysisRevision]? = nil
    ) {
        self.id = id
        self.filename = filename
        self.fileURL = fileURL
        self.vehicleID = vehicleID
        self.buildStateID = buildStateID
        self.channels = channels
        self.sampleCount = sampleCount
        self.duration = duration
        self.timestamps = timestamps
        self.condition = condition
        self.temperature = temperature
        self.notes = notes
        self.importDate = importDate
        self.analyzedDate = analyzedDate
        self.events = events
        self.sourceSHA256 = sourceSHA256
        self.analysisEngineVersion = analysisEngineVersion
        self.analysisRevisions = analysisRevisions
    }
}

struct LogEvent: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval
    var eventType: String // "protection", "shift", "knock", "throttle_closure", "fuel_pressure", "lambda_deviation"

    var description: String
    var severity: String // "info", "warning", "critical"

    var channelValues: [String: Double]
    var sourceStates: [String: String]

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        eventType: String,
        description: String,
        severity: String = "info",
        channelValues: [String: Double] = [:],
        sourceStates: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.description = description
        self.severity = severity
        self.channelValues = channelValues
        self.sourceStates = sourceStates
    }
}

struct SourceState: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval
    var source: String
    var previousValue: String
    var newValue: String

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        source: String,
        previousValue: String,
        newValue: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.previousValue = previousValue
        self.newValue = newValue
    }
}

// MARK: - Calibration Atlas

enum AtlasSection: String, Codable, CaseIterable, Identifiable {
    case airflow = "Airflow"
    case fuel = "Fuel"
    case spark = "Spark"
    case torque = "Torque"
    case etc = "ETC"
    case protection = "Protection"
    case supercharger = "Supercharger"
    case driverDemand = "Driver Demand"
    case dct = "DCT"
    case thermal = "Thermal"

    var id: String { rawValue }
}

enum DangerLevel: String, Codable {
    case low
    case moderate
    case high
    case critical
}

struct AtlasEntry: Identifiable, Codable {
    let id: UUID

    var section: AtlasSection
    var name: String
    var controller: String

    var evidenceLevel: EvidenceLevel
    var confidence: ConfidenceLevel

    var function: String
    var upstream: [String]
    var downstream: [String]

    var symptomsWhenWrong: [String]

    var danger: DangerLevel
    var eligiblePhase: TuningPhase

    var doNotModifyWhen: [String]
    var evidenceRequired: [String]
    var rollbackTriggers: [String]
    var noChangeGate: [String]

    init(
        id: UUID = UUID(),
        section: AtlasSection,
        name: String,
        controller: String,
        evidenceLevel: EvidenceLevel = .observed,
        confidence: ConfidenceLevel = .c2,
        function: String = "",
        upstream: [String] = [],
        downstream: [String] = [],
        symptomsWhenWrong: [String] = [],
        danger: DangerLevel = .moderate,
        eligiblePhase: TuningPhase = .r02Baseline,
        doNotModifyWhen: [String] = [],
        evidenceRequired: [String] = [],
        rollbackTriggers: [String] = [],
        noChangeGate: [String] = []
    ) {
        self.id = id
        self.section = section
        self.name = name
        self.controller = controller
        self.evidenceLevel = evidenceLevel
        self.confidence = confidence
        self.function = function
        self.upstream = upstream
        self.downstream = downstream
        self.symptomsWhenWrong = symptomsWhenWrong
        self.danger = danger
        self.eligiblePhase = eligiblePhase
        self.doNotModifyWhen = doNotModifyWhen
        self.evidenceRequired = evidenceRequired
        self.rollbackTriggers = rollbackTriggers
        self.noChangeGate = noChangeGate
    }
}
