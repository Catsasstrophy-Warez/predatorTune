// PredatorLab/Models/Core/SessionModels.swift
// Session management, event cards, flight recorder, controller ownership, evidence trails, and view hierarchy design

import Foundation

// MARK: - 0. Scanner Config (referenced by SessionMode/Session below; not defined elsewhere)

enum ScannerConfigType: String, Codable, CaseIterable, Identifiable {
    case aWOT = "Config A: WOT"
    case bFuel = "Config B: Fuel"
    case cDCT = "Config C: DCT"
    case dTorque = "Config D: Torque"
    case eControl = "Config E: Control"
    case fThermal = "Config F: Thermal"
    case gFull = "Config G: Full"

    var id: String { rawValue }
}

// MARK: - 1. Session Mode Types

enum SessionMode: String, Codable, CaseIterable, Identifiable {
    case diagnose = "Diagnose"
    case dynoPull = "Dyno Pull"
    case streetCruise = "Street Cruise"
    case steadyState = "Steady State"
    case heatSoakTest = "Heat-Soak Test"
    case dctShiftTest = "DCT Shift Test"
    case dragPass = "Drag Pass"
    case trackSession = "Track Session"
    case r04Reproduction = "R04 Investigation"
    case other = "Other"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .diagnose:
            return "Diagnostic logging at various conditions"
        case .dynoPull:
            return "Controlled dyno run with steady acceleration"
        case .streetCruise:
            return "Normal street driving, multiple conditions"
        case .steadyState:
            return "Constant RPM/load for tuning validation"
        case .heatSoakTest:
            return "Extended driving to reach thermal equilibrium"
        case .dctShiftTest:
            return "Focused shift behavior analysis"
        case .dragPass:
            return "Drag strip acceleration from standstill"
        case .trackSession:
            return "HPDE or track day session"
        case .r04Reproduction:
            return "Reproduce Insufficient Fuel Flow or other protection event"
        case .other:
            return "Custom session type"
        }
    }

    var recommendedConfig: ScannerConfigType {
        switch self {
        case .diagnose:
            return .dTorque
        case .dynoPull:
            return .dTorque
        case .streetCruise:
            return .bFuel
        case .steadyState:
            return .dTorque
        case .heatSoakTest:
            return .fThermal
        case .dctShiftTest:
            return .cDCT
        case .dragPass:
            return .aWOT
        case .trackSession:
            return .dTorque
        case .r04Reproduction:
            return .bFuel
        case .other:
            return .dTorque
        }
    }
}

// MARK: - 2. Session (Core Object)

struct Session: Identifiable, Codable {
    let id: UUID
    var vehicleID: UUID
    var buildStateID: UUID
    var tuningRevisionID: UUID?

    var mode: SessionMode
    var title: String
    var date: Date
    var duration: TimeInterval // seconds

    var location: String? // "Dyno - PBD", "Home Garage", "NJMP", etc.
    var ambient: SessionAmbient
    var weather: String? // "Clear", "Rainy", "Overcast"

    var scannerConfig: ScannerConfigType
    var logFileID: UUID? // Link to ImportedLog

    var eventCards: [EventCard]
    var flightRecords: [FlightRecord]
    var controllerTimeline: [ControllerOwnershipPoint]
    var evidenceTrail: EvidenceTrail
    var experimentContext: SessionExperimentContext?

    var notes: String
    var objectives: [String] // ["Reproduce R04", "Validate spark", "Check thermal"]
    var results: [String] // ["R04 confirmed at 5.8s", "Spark stable", "Heat-soaked to 58°C"]

    var photos: [URL]
    var externalReferences: [String] // Links to related investigations, procedures, etc.

    var tuneApplied: Bool
    var validatedAgainstDyno: Bool
    var dynoReference: String?

    var createdBy: String // username
    var lastModified: Date

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        buildStateID: UUID,
        tuningRevisionID: UUID? = nil,
        mode: SessionMode = .diagnose,
        title: String = "",
        date: Date = .now,
        duration: TimeInterval = 0,
        location: String? = nil,
        ambient: SessionAmbient = SessionAmbient(),
        weather: String? = nil,
        scannerConfig: ScannerConfigType = .dTorque,
        logFileID: UUID? = nil,
        eventCards: [EventCard] = [],
        flightRecords: [FlightRecord] = [],
        controllerTimeline: [ControllerOwnershipPoint] = [],
        evidenceTrail: EvidenceTrail = EvidenceTrail(),
        experimentContext: SessionExperimentContext? = nil,
        notes: String = "",
        objectives: [String] = [],
        results: [String] = [],
        photos: [URL] = [],
        externalReferences: [String] = [],
        tuneApplied: Bool = false,
        validatedAgainstDyno: Bool = false,
        dynoReference: String? = nil,
        createdBy: String = "owner",
        lastModified: Date = .now
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.buildStateID = buildStateID
        self.tuningRevisionID = tuningRevisionID
        self.mode = mode
        self.title = title
        self.date = date
        self.duration = duration
        self.location = location
        self.ambient = ambient
        self.weather = weather
        self.scannerConfig = scannerConfig
        self.logFileID = logFileID
        self.eventCards = eventCards
        self.flightRecords = flightRecords
        self.controllerTimeline = controllerTimeline
        self.evidenceTrail = evidenceTrail
        self.experimentContext = experimentContext
        self.notes = notes
        self.objectives = objectives
        self.results = results
        self.photos = photos
        self.externalReferences = externalReferences
        self.tuneApplied = tuneApplied
        self.validatedAgainstDyno = validatedAgainstDyno
        self.dynoReference = dynoReference
        self.createdBy = createdBy
        self.lastModified = lastModified
    }

    var displayTitle: String {
        title.isEmpty ? "\(mode.rawValue) — \(date.formatted(date: .abbreviated, time: .shortened))" : title
    }

    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

struct SessionAmbient: Codable {
    var temperature: Double? // °F
    var humidity: Double? // %
    var barometricPressure: Double? // psia
    var elevation: Int? // feet
    var windSpeed: Double? // mph

    init(
        temperature: Double? = nil,
        humidity: Double? = nil,
        barometricPressure: Double? = nil,
        elevation: Int? = nil,
        windSpeed: Double? = nil
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.barometricPressure = barometricPressure
        self.elevation = elevation
        self.windSpeed = windSpeed
    }
}

// MARK: - 3. Event Card (First-Class Object)

struct EventCard: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval // seconds from session start
    var eventType: String // "protection", "knock", "shift", "throttle_closure", etc.

    var title: String
    var description: String
    var severity: String // "info", "warning", "critical"

    var channelSnapshot: [String: Double] // RPM, load, torque, pressure, lambda, etc.
    var sourceStates: [String: String] // Torque Source, Spark Source, Throttle Source, etc.

    var hypothesis: String? // "H1B Injector Window Limit"
    var evidence: [String] // Supporting evidence points
    var nextMeasurement: String? // "Add Maximum Injector PW"

    var tags: [String] // ["R04", "H1B", "shift-related", "heat-soaked"]
    var relatedInvestigations: [UUID] // Link to Investigation objects
    var relatedProcedures: [UUID] // Link to Maintenance procedures

    var notes: String
    var photo: URL?

    var comparable: Bool // Can this be compared with other sessions?
    var comparisonHash: String? // Hash for similarity matching

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval = 0,
        eventType: String = "",
        title: String = "",
        description: String = "",
        severity: String = "info",
        channelSnapshot: [String: Double] = [:],
        sourceStates: [String: String] = [:],
        hypothesis: String? = nil,
        evidence: [String] = [],
        nextMeasurement: String? = nil,
        tags: [String] = [],
        relatedInvestigations: [UUID] = [],
        relatedProcedures: [UUID] = [],
        notes: String = "",
        photo: URL? = nil,
        comparable: Bool = true,
        comparisonHash: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.title = title
        self.description = description
        self.severity = severity
        self.channelSnapshot = channelSnapshot
        self.sourceStates = sourceStates
        self.hypothesis = hypothesis
        self.evidence = evidence
        self.nextMeasurement = nextMeasurement
        self.tags = tags
        self.relatedInvestigations = relatedInvestigations
        self.relatedProcedures = relatedProcedures
        self.notes = notes
        self.photo = photo
        self.comparable = comparable
        self.comparisonHash = comparisonHash
    }
}

// MARK: - 4. Flight Recorder (Auto-Capture Logic)

enum FlightRecorderTrigger: Codable {
    case rpm(min: Int, max: Int)
    case load(min: Double, max: Double)
    case protection(String) // "Insufficient Fuel Flow", "Knock Retard >3°", etc.
    case knockRetard(threshold: Double) // degrees
    case lambdaDeviation(threshold: Double) // lambda units
    case throttleClosure(threshold: Double) // degrees change
    case dctShift
    case overtemperature(threshold: Double) // °C
    case dtcActive
    case userTap
    case custom(String) // Custom trigger name

    var description: String {
        switch self {
        case .rpm(let min, let max):
            return "RPM between \(min)–\(max)"
        case .load(let min, let max):
            return "Load between \(String(format: "%.2f", min))–\(String(format: "%.2f", max))"
        case .protection(let name):
            return "Protection: \(name)"
        case .knockRetard(let threshold):
            return "Knock Retard >\(String(format: "%.1f", threshold))°"
        case .lambdaDeviation(let threshold):
            return "Lambda deviation >\(String(format: "%.3f", threshold))"
        case .throttleClosure(let threshold):
            return "Throttle closure >\(String(format: "%.1f", threshold))°"
        case .dctShift:
            return "DCT shift event"
        case .overtemperature(let threshold):
            return "Temperature >\(String(format: "%.0f", threshold))°C"
        case .dtcActive:
            return "DTC becomes active"
        case .userTap:
            return "User manual capture"
        case .custom(let name):
            return name
        }
    }
}

struct FlightRecorderRule: Identifiable, Codable {
    let id: UUID
    var trigger: FlightRecorderTrigger
    var captureWindow: TimeInterval // seconds before + after trigger
    var enabled: Bool
    var priority: Int // Higher = fires first

    init(
        id: UUID = UUID(),
        trigger: FlightRecorderTrigger,
        captureWindow: TimeInterval = 10, // 5 sec before + 5 sec after by default
        enabled: Bool = true,
        priority: Int = 1
    ) {
        self.id = id
        self.trigger = trigger
        self.captureWindow = captureWindow
        self.enabled = enabled
        self.priority = priority
    }
}

struct FlightRecord: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval // When captured
    var rule: FlightRecorderTrigger // Which rule fired
    var windowStart: TimeInterval
    var windowEnd: TimeInterval
    var dataPoints: [[String: Double]] // Full channel data for window
    var notes: String

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        rule: FlightRecorderTrigger,
        windowStart: TimeInterval,
        windowEnd: TimeInterval,
        dataPoints: [[String: Double]] = [],
        notes: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.rule = rule
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.dataPoints = dataPoints
        self.notes = notes
    }
}

// MARK: - 5. Controller Ownership (Decision Attribution)

struct ControllerOwnershipPoint: Identifiable, Codable {
    let id: UUID
    var timestamp: TimeInterval

    var torqueOwner: String // "Driver Demand", "Transmission", "Protection", "Spark Limit", etc.
    var sparkOwner: String // "Normal", "Knock Retard", "Rev Limiter", etc.
    var throttleOwner: String // "Driver", "Torque Model", "Protection Override", etc.

    var explanation: String? // "Transmission requested torque reduction during shift"
    var channels: [String: Double]? // Context at this point (RPM, load, temp, etc.)

    init(
        id: UUID = UUID(),
        timestamp: TimeInterval = 0,
        torqueOwner: String = "Driver Demand",
        sparkOwner: String = "Normal",
        throttleOwner: String = "Driver",
        explanation: String? = nil,
        channels: [String: Double]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.torqueOwner = torqueOwner
        self.sparkOwner = sparkOwner
        self.throttleOwner = throttleOwner
        self.explanation = explanation
        self.channels = channels
    }
}

// MARK: - 6. Evidence Trail (Full Provenance)

struct EvidenceTrail: Codable {
    var level: EvidenceLevel
    var confidence: ConfidenceLevel

    var sources: [EvidenceSource]
    var observations: [String] // What we directly saw in the log
    var inferences: [String] // What we concluded
    var missingEvidence: [String] // What would strengthen the case

    var supportingEvents: [UUID] // Event cards that support this
    var contradictingEvents: [UUID] // Event cards that contradict

    var lastUpdated: Date
    var updatedBy: String

    init(
        level: EvidenceLevel = .observed,
        confidence: ConfidenceLevel = .c0,
        sources: [EvidenceSource] = [],
        observations: [String] = [],
        inferences: [String] = [],
        missingEvidence: [String] = [],
        supportingEvents: [UUID] = [],
        contradictingEvents: [UUID] = [],
        lastUpdated: Date = .now,
        updatedBy: String = "system"
    ) {
        self.level = level
        self.confidence = confidence
        self.sources = sources
        self.observations = observations
        self.inferences = inferences
        self.missingEvidence = missingEvidence
        self.supportingEvents = supportingEvents
        self.contradictingEvents = contradictingEvents
        self.lastUpdated = lastUpdated
        self.updatedBy = updatedBy
    }
}

// MARK: - Rev13 Experiment Context

/// Optional reproducibility metadata for a session. Kept separate from the core Session fields so
/// historical records can migrate without inventing values that were never recorded.
struct SessionExperimentContext: Codable, Equatable {
    var purpose: String?
    var calibrationIdentifier: String?
    var fuelDescription: String?
    var fuelLevelPercent: Double?
    var tireConfiguration: String?
    var tirePressureNotes: String?
    var recordedChanges: [String]
    var operatorObservations: [String]
    var testProtocol: String?

    init(purpose: String? = nil, calibrationIdentifier: String? = nil, fuelDescription: String? = nil,
         fuelLevelPercent: Double? = nil, tireConfiguration: String? = nil, tirePressureNotes: String? = nil,
         recordedChanges: [String] = [], operatorObservations: [String] = [], testProtocol: String? = nil) {
        self.purpose = purpose; self.calibrationIdentifier = calibrationIdentifier; self.fuelDescription = fuelDescription
        self.fuelLevelPercent = fuelLevelPercent; self.tireConfiguration = tireConfiguration; self.tirePressureNotes = tirePressureNotes
        self.recordedChanges = recordedChanges; self.operatorObservations = operatorObservations; self.testProtocol = testProtocol
    }
}
