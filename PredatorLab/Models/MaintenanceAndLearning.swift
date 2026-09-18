// PredatorLab/Models/MaintenanceAndLearning.swift
// Maintenance procedures, service history, YouTube library, control-strategy lessons, "show me" infrastructure

import Foundation

// MARK: - 1. Maintenance Procedure Models

enum ServiceIntensity: String, Codable, CaseIterable, Identifiable {
    case street = "Street"
    case performanceStreet = "Performance / Drag"
    case hpde = "HPDE / Track"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .street:
            return "Normal road usage"
        case .performanceStreet:
            return "Street performance or occasional drag use"
        case .hpde:
            return "High-performance driving, track days, or frequent drag racing"
        }
    }
}

enum MaintenanceSystem: String, Codable, CaseIterable, Identifiable {
    case engine = "Engine"
    case supercharger = "Supercharger"
    case fuel = "Fuel System"
    case dct = "DCT"
    case differential = "Differential"
    case brakes = "Brakes"
    case suspension = "Suspension"
    case cooling = "Cooling & Thermal"
    case electrical = "Electrical"
    case wheels = "Wheels & Tires"
    case track = "Track Preparation"
    case storage = "Storage & Winterization"

    var id: String { rawValue }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    var id: String { rawValue }
}

struct MaintenanceProcedure: Identifiable, Codable {
    let id: UUID

    var title: String
    var system: MaintenanceSystem
    var subsystem: String // "Oil Change", "Filter Service", "Fluid Drain/Fill", etc.

    var youTubeVideoID: String?
    var youTubeTimestamp: TimeInterval?
    var youTubeChannelName: String?
    var workshopManualReference: String?

    var steps: [MaintenanceProcedureStep]
    var parts: [MaintenancePart]
    var tools: [MaintenanceTool]
    var torqueSpecifications: [MaintenanceTorqueSpec]
    var fluids: [Fluid]
    var safetyWarnings: [String]

    var estimatedTime: TimeInterval // minutes
    var difficulty: DifficultyLevel

    var applicableIntensities: [ServiceIntensity]
    var applicableModelYears: [Int]

    var sourceChannel: String
    var sourceConfidence: ConfidenceLevel
    var workshopAlignment: String? // "Direct match", "Aligned", "Different approach"

    var relatedAtlasEntries: [String] // Parameter names
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        system: MaintenanceSystem,
        subsystem: String,
        youTubeVideoID: String? = nil,
        youTubeTimestamp: TimeInterval? = nil,
        youTubeChannelName: String? = nil,
        workshopManualReference: String? = nil,
        steps: [MaintenanceProcedureStep] = [],
        parts: [MaintenancePart] = [],
        tools: [MaintenanceTool] = [],
        torqueSpecifications: [MaintenanceTorqueSpec] = [],
        fluids: [Fluid] = [],
        safetyWarnings: [String] = [],
        estimatedTime: TimeInterval = 30,
        difficulty: DifficultyLevel = .intermediate,
        applicableIntensities: [ServiceIntensity] = [.street, .performanceStreet, .hpde],
        applicableModelYears: [Int] = [2020, 2021, 2022],
        sourceChannel: String = "",
        sourceConfidence: ConfidenceLevel = .c2,
        workshopAlignment: String? = nil,
        relatedAtlasEntries: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.system = system
        self.subsystem = subsystem
        self.youTubeVideoID = youTubeVideoID
        self.youTubeTimestamp = youTubeTimestamp
        self.youTubeChannelName = youTubeChannelName
        self.workshopManualReference = workshopManualReference
        self.steps = steps
        self.parts = parts
        self.tools = tools
        self.torqueSpecifications = torqueSpecifications
        self.fluids = fluids
        self.safetyWarnings = safetyWarnings
        self.estimatedTime = estimatedTime
        self.difficulty = difficulty
        self.applicableIntensities = applicableIntensities
        self.applicableModelYears = applicableModelYears
        self.sourceChannel = sourceChannel
        self.sourceConfidence = sourceConfidence
        self.workshopAlignment = workshopAlignment
        self.relatedAtlasEntries = relatedAtlasEntries
        self.notes = notes
    }
}

struct MaintenanceProcedureStep: Identifiable, Codable {
    let id: UUID
    var order: Int
    var instruction: String
    var diagramReference: String?
    var youTubeTimestamp: TimeInterval?
    var warning: String?
    var torqueSpec: MaintenanceTorqueSpec?
    var photo: String? // filename or URL

    init(
        id: UUID = UUID(),
        order: Int,
        instruction: String,
        diagramReference: String? = nil,
        youTubeTimestamp: TimeInterval? = nil,
        warning: String? = nil,
        torqueSpec: MaintenanceTorqueSpec? = nil,
        photo: String? = nil
    ) {
        self.id = id
        self.order = order
        self.instruction = instruction
        self.diagramReference = diagramReference
        self.youTubeTimestamp = youTubeTimestamp
        self.warning = warning
        self.torqueSpec = torqueSpec
        self.photo = photo
    }
}

struct MaintenancePart: Identifiable, Codable {
    let id: UUID
    var name: String
    var partNumber: String
    var quantity: Int
    var vendorReference: String? // "Motorcraft", "OEM", "Aftermarket", etc.
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        partNumber: String,
        quantity: Int = 1,
        vendorReference: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.quantity = quantity
        self.vendorReference = vendorReference
        self.notes = notes
    }
}

struct MaintenanceTool: Identifiable, Codable {
    let id: UUID
    var name: String
    var optional: Bool
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        optional: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.optional = optional
        self.notes = notes
    }
}

struct Fluid: Identifiable, Codable {
    let id: UUID
    var name: String
    var specification: String // "5W-50", "Dex IV", etc.
    var quantity: Double
    var unit: String // "quarts", "liters", "ounces"
    var vendorReference: String?

    init(
        id: UUID = UUID(),
        name: String,
        specification: String,
        quantity: Double,
        unit: String = "quarts",
        vendorReference: String? = nil
    ) {
        self.id = id
        self.name = name
        self.specification = specification
        self.quantity = quantity
        self.unit = unit
        self.vendorReference = vendorReference
    }
}

struct MaintenanceTorqueSpec: Identifiable, Codable {
    let id: UUID
    var component: String
    var value: Double // lb-ft
    var sequence: String? // "in an X pattern", "alternating sides", etc.
    var note: String?

    init(
        id: UUID = UUID(),
        component: String,
        value: Double,
        sequence: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.component = component
        self.value = value
        self.sequence = sequence
        self.note = note
    }
}

// MARK: - 2. Service History & Records

struct ServiceRecord: Identifiable, Codable {
    let id: UUID
    var vehicleID: UUID
    var procedureID: UUID?
    var date: Date
    var mileage: Int

    var procedure: String // "Oil Change", "DCT Filter", etc.
    var parts: [String] // ["FL-2087", "Motorcraft 5W-50"]
    var tools: [String]
    var condition: String // what the technician found
    var notes: String
    var photos: [URL]
    var nextServiceDue: Date?

    var technician: String? // "owner DIY" or "shop name"
    var cost: Double?
    var billURL: URL?

    var recordedBy: String // user email or name
    var recordedDate: Date

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        procedureID: UUID? = nil,
        date: Date = .now,
        mileage: Int = 0,
        procedure: String = "",
        parts: [String] = [],
        tools: [String] = [],
        condition: String = "",
        notes: String = "",
        photos: [URL] = [],
        nextServiceDue: Date? = nil,
        technician: String? = nil,
        cost: Double? = nil,
        billURL: URL? = nil,
        recordedBy: String = "owner",
        recordedDate: Date = .now
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.procedureID = procedureID
        self.date = date
        self.mileage = mileage
        self.procedure = procedure
        self.parts = parts
        self.tools = tools
        self.condition = condition
        self.notes = notes
        self.photos = photos
        self.nextServiceDue = nextServiceDue
        self.technician = technician
        self.cost = cost
        self.billURL = billURL
        self.recordedBy = recordedBy
        self.recordedDate = recordedDate
    }
}

// MARK: - 3. YouTube Research Library

struct YouTubeReference: Identifiable, Codable {
    let id: UUID
    var title: String
    var channelName: String
    var youTubeID: String
    var publishDate: Date

    var gt500Specific: Bool
    var modelYears: [Int] // [2020, 2021, 2022]
    var systems: [MaintenanceSystem]
    var procedure: String?

    var workshopManualAlignment: String? // "Direct match", "Aligned", "Different approach"
    var authorityLevel: String // "Ford official", "Professional shop", "Owner/track user"
    var evidenceConfidence: ConfidenceLevel

    var relevantTimestamps: [TimeInterval: String] // timestamp → description
    var parts: [String]
    var tools: [String]
    var torqueSpecs: [MaintenanceTorqueSpec]

    var notes: String
    var disputedClaims: String? // "Creator claims low fluid is universal — unverified"
    var lastReviewed: Date

    var linkedProcedureID: UUID? // if this video is the source for a procedure

    init(
        id: UUID = UUID(),
        title: String,
        channelName: String,
        youTubeID: String,
        publishDate: Date = .now,
        gt500Specific: Bool = true,
        modelYears: [Int] = [2020, 2021, 2022],
        systems: [MaintenanceSystem] = [],
        procedure: String? = nil,
        workshopManualAlignment: String? = nil,
        authorityLevel: String = "Professional",
        evidenceConfidence: ConfidenceLevel = .c2,
        relevantTimestamps: [TimeInterval: String] = [:],
        parts: [String] = [],
        tools: [String] = [],
        torqueSpecs: [MaintenanceTorqueSpec] = [],
        notes: String = "",
        disputedClaims: String? = nil,
        lastReviewed: Date = .now,
        linkedProcedureID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.channelName = channelName
        self.youTubeID = youTubeID
        self.publishDate = publishDate
        self.gt500Specific = gt500Specific
        self.modelYears = modelYears
        self.systems = systems
        self.procedure = procedure
        self.workshopManualAlignment = workshopManualAlignment
        self.authorityLevel = authorityLevel
        self.evidenceConfidence = evidenceConfidence
        self.relevantTimestamps = relevantTimestamps
        self.parts = parts
        self.tools = tools
        self.torqueSpecs = torqueSpecs
        self.notes = notes
        self.disputedClaims = disputedClaims
        self.lastReviewed = lastReviewed
        self.linkedProcedureID = linkedProcedureID
    }

    var youTubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(youTubeID)")
    }
}

// MARK: - 4. Control-Strategy Lessons

struct ControlStrategyLesson: Identifiable, Codable {
    let id: UUID
    var title: String
    var order: Int
    var category: String // "Torque Control", "Fuel Strategy", "Protection Logic", "DCT Coordination"

    var conceptualExplanation: String
    var fordArchitecture: String // How TC-298B actually does this
    var keyPIDs: [String] // Required scanner channels
    var requiredConfigs: [ScannerConfigType]

    var typicalDatalogSignature: String // What to look for
    var commonProblems: [String]
    var exampleVideoID: String? // YouTube video ID
    var relatedAtlasEntries: [String] // Parameter names to link to
    var relatedInvestigations: [R04HypothesisID]?

    var nextLessonID: UUID?
    var prerequisiteLessonIDs: [UUID]

    var estimatedReadTime: TimeInterval // minutes
    var difficulty: DifficultyLevel

    init(
        id: UUID = UUID(),
        title: String,
        order: Int = 0,
        category: String = "",
        conceptualExplanation: String = "",
        fordArchitecture: String = "",
        keyPIDs: [String] = [],
        requiredConfigs: [ScannerConfigType] = [],
        typicalDatalogSignature: String = "",
        commonProblems: [String] = [],
        exampleVideoID: String? = nil,
        relatedAtlasEntries: [String] = [],
        relatedInvestigations: [R04HypothesisID]? = nil,
        nextLessonID: UUID? = nil,
        prerequisiteLessonIDs: [UUID] = [],
        estimatedReadTime: TimeInterval = 10,
        difficulty: DifficultyLevel = .intermediate
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.category = category
        self.conceptualExplanation = conceptualExplanation
        self.fordArchitecture = fordArchitecture
        self.keyPIDs = keyPIDs
        self.requiredConfigs = requiredConfigs
        self.typicalDatalogSignature = typicalDatalogSignature
        self.commonProblems = commonProblems
        self.exampleVideoID = exampleVideoID
        self.relatedAtlasEntries = relatedAtlasEntries
        self.relatedInvestigations = relatedInvestigations
        self.nextLessonID = nextLessonID
        self.prerequisiteLessonIDs = prerequisiteLessonIDs
        self.estimatedReadTime = estimatedReadTime
        self.difficulty = difficulty
    }
}

// MARK: - 5. "Show Me" Button Infrastructure

struct ProcedureMediaLinks: Identifiable, Codable {
    let id: UUID

    var youTubeVideoID: String?
    var youTubeTimestamp: TimeInterval?

    var diagramURL: URL?
    var schematicURL: URL?

    var atlasEntryNames: [String]
    var investigationIDs: [UUID]

    var workshopManualReference: String?
    var workshopManualURL: URL?

    init(
        id: UUID = UUID(),
        youTubeVideoID: String? = nil,
        youTubeTimestamp: TimeInterval? = nil,
        diagramURL: URL? = nil,
        schematicURL: URL? = nil,
        atlasEntryNames: [String] = [],
        investigationIDs: [UUID] = [],
        workshopManualReference: String? = nil,
        workshopManualURL: URL? = nil
    ) {
        self.id = id
        self.youTubeVideoID = youTubeVideoID
        self.youTubeTimestamp = youTubeTimestamp
        self.diagramURL = diagramURL
        self.schematicURL = schematicURL
        self.atlasEntryNames = atlasEntryNames
        self.investigationIDs = investigationIDs
        self.workshopManualReference = workshopManualReference
        self.workshopManualURL = workshopManualURL
    }

    var youTubeURL: URL? {
        guard let videoID = youTubeVideoID else { return nil }
        if let timestamp = youTubeTimestamp, timestamp > 0 {
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)&t=\(Int(timestamp))s")
        }
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }
}

// MARK: - Service Schedule Models

enum ServiceIntervalType: Codable {
    case miles(Int)
    case months(Int)
    case sessions(Int)
    case combined([ServiceIntervalType]) // "5,000 miles OR 3 sessions, whichever is first"

    func description() -> String {
        switch self {
        case .miles(let m):
            return "every \(m) miles"
        case .months(let mo):
            return "every \(mo) months"
        case .sessions(let s):
            return "every \(s) sessions"
        case .combined(let intervals):
            let descriptions = intervals.map { $0.description() }
            return descriptions.joined(separator: " or ")
        }
    }
}

struct ScheduledProcedure: Identifiable, Codable {
    let id: UUID
    var procedureID: UUID
    var procedureTitle: String
    var interval: ServiceIntervalType
    var notes: String?

    init(
        id: UUID = UUID(),
        procedureID: UUID,
        procedureTitle: String,
        interval: ServiceIntervalType,
        notes: String? = nil
    ) {
        self.id = id
        self.procedureID = procedureID
        self.procedureTitle = procedureTitle
        self.interval = interval
        self.notes = notes
    }
}

struct ServiceSchedule: Identifiable, Codable {
    let id: UUID
    var intensity: ServiceIntensity
    var procedures: [ScheduledProcedure]
    var notes: String?

    init(
        id: UUID = UUID(),
        intensity: ServiceIntensity,
        procedures: [ScheduledProcedure] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.intensity = intensity
        self.procedures = procedures
        self.notes = notes
    }
}

// MARK: - Seed Data: Core Maintenance Procedures

class MaintenanceProcedureSeedData {

    static func seedAllProcedures() -> [MaintenanceProcedure] {
        return [
            engineOilChange(),
            dtcFilterService(),
            brakeFluidBleed(),
            wheelRemoval(),
            dtcFluidCheck(),
            alignmentReference(),
            plugInspection(),
            beltInspection()
        ]
    }

    static func engineOilChange() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Engine Oil & Filter Change",
            system: .engine,
            subsystem: "Oil Service",
            youTubeVideoID: "exampleID123",
            youTubeChannelName: "Late Model Restoration",
            workshopManualReference: "Engine - Fluids - Oil Service",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Raise vehicle safely on lift"),
                MaintenanceProcedureStep(order: 2, instruction: "Remove undercarriage access panel"),
                MaintenanceProcedureStep(order: 3, instruction: "Locate oil drain plug (bottom of oil pan)"),
                MaintenanceProcedureStep(order: 4, instruction: "Place drain pan underneath", warning: "Oil will be hot if engine was recently run"),
                MaintenanceProcedureStep(order: 5, instruction: "Remove drain plug (19 mm socket)", torqueSpec: MaintenanceTorqueSpec(component: "Oil drain plug", value: 25)),
                MaintenanceProcedureStep(order: 6, instruction: "Allow oil to drain completely (5-10 minutes)"),
                MaintenanceProcedureStep(order: 7, instruction: "Reinstall drain plug", torqueSpec: MaintenanceTorqueSpec(component: "Oil drain plug reinstall", value: 25)),
                MaintenanceProcedureStep(order: 8, instruction: "Locate oil filter cartridge (top of engine)"),
                MaintenanceProcedureStep(order: 9, instruction: "Remove filter housing cap (86 mm socket)"),
                MaintenanceProcedureStep(order: 10, instruction: "Replace both O-rings on new filter"),
                MaintenanceProcedureStep(order: 11, instruction: "Pre-oil new filter element before installation"),
                MaintenanceProcedureStep(order: 12, instruction: "Install new filter", torqueSpec: MaintenanceTorqueSpec(component: "Oil filter housing", value: 18)),
                MaintenanceProcedureStep(order: 13, instruction: "Lower vehicle"),
                MaintenanceProcedureStep(order: 14, instruction: "Add 5W-50 full synthetic oil (11.5 quarts total)")
            ],
            parts: [
                MaintenancePart(name: "Oil filter cartridge", partNumber: "FL-2087", vendorReference: "Motorcraft"),
                MaintenancePart(name: "Filter O-ring kit", partNumber: "OEM-OR-1234", quantity: 2)
            ],
            tools: [
                MaintenanceTool(name: "Lift or jack + jack stands"),
                MaintenanceTool(name: "19mm socket + ratchet"),
                MaintenanceTool(name: "86mm oil filter socket"),
                MaintenanceTool(name: "Oil drain pan"),
                MaintenanceTool(name: "Oil level checking tool")
            ],
            torqueSpecifications: [
                MaintenanceTorqueSpec(component: "Oil drain plug", value: 25),
                MaintenanceTorqueSpec(component: "Oil filter housing", value: 18)
            ],
            fluids: [
                Fluid(name: "Engine oil", specification: "5W-50 full synthetic", quantity: 11.5, unit: "quarts", vendorReference: "Motorcraft")
            ],
            estimatedTime: 30,
            difficulty: .beginner,
            sourceChannel: "Late Model Restoration",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            relatedAtlasEntries: ["Engine Oil Temperature", "Oil Pressure"],
            notes: "Stock interval is 7,500 miles on street. Reduce to 5,000 for performance use, 2,000 for track."
        )
    }

    static func dtcFilterService() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "DCT Transmission Filter Service",
            system: .dct,
            subsystem: "Filter & Fluid",
            youTubeVideoID: "shelbyflyer456",
            youTubeTimestamp: 210,
            youTubeChannelName: "ShelbyFlyer",
            workshopManualReference: "Transmission - TR-9070 - Fluid & Filter",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Raise vehicle on lift", warning: "Support safely on jack stands"),
                MaintenanceProcedureStep(order: 2, instruction: "Remove undercarriage shields for transmission access"),
                MaintenanceProcedureStep(order: 3, instruction: "Locate side filter (passenger side of transmission)"),
                MaintenanceProcedureStep(order: 4, instruction: "Drain transmission fluid into clean pan", warning: "Fluid should be changed warm for best drainage"),
                MaintenanceProcedureStep(order: 5, instruction: "Remove side filter bowl", torqueSpec: MaintenanceTorqueSpec(component: "Side filter bowl", value: 12)),
                MaintenanceProcedureStep(order: 6, instruction: "Replace side filter element"),
                MaintenanceProcedureStep(order: 7, instruction: "Reinstall bowl", torqueSpec: MaintenanceTorqueSpec(component: "Side filter bowl reinstall", value: 12)),
                MaintenanceProcedureStep(order: 8, instruction: "Locate pan filter (bottom of transmission pan)"),
                MaintenanceProcedureStep(order: 9, instruction: "Remove transmission pan mounting bolts", torqueSpec: MaintenanceTorqueSpec(component: "Pan bolts", value: 9, sequence: "alternating pattern")),
                MaintenanceProcedureStep(order: 10, instruction: "Remove pan and replace filter element"),
                MaintenanceProcedureStep(order: 11, instruction: "Inspect pan for metal debris", warning: "Excessive debris indicates internal wear"),
                MaintenanceProcedureStep(order: 12, instruction: "Reinstall pan with new gasket", torqueSpec: MaintenanceTorqueSpec(component: "Pan bolts reinstall", value: 9, sequence: "alternating pattern"))
            ],
            parts: [
                MaintenancePart(name: "Side filter element", partNumber: "TR-9070-SF-01"),
                MaintenancePart(name: "Pan filter element", partNumber: "TR-9070-PF-01"),
                MaintenancePart(name: "Transmission pan gasket", partNumber: "TR-9070-GSK-01")
            ],
            tools: [
                MaintenanceTool(name: "Lift or jack + jack stands"),
                MaintenanceTool(name: "10mm socket"),
                MaintenanceTool(name: "12mm socket"),
                MaintenanceTool(name: "Transmission fluid drain pan"),
                MaintenanceTool(name: "Gasket scraper")
            ],
            fluids: [
                Fluid(name: "Transmission fluid", specification: "Motorcraft MERCON ULV", quantity: 8.0, unit: "quarts", vendorReference: "Motorcraft")
            ],
            estimatedTime: 60,
            difficulty: .intermediate,
            applicableIntensities: [.performanceStreet, .hpde],
            sourceChannel: "ShelbyFlyer",
            sourceConfidence: .c4,
            workshopAlignment: "Direct match",
            notes: "Street: 20,000 miles. Performance: 10,000 miles. Track: every 3-5 sessions. Inspect metal debris on pan for transmission health."
        )
    }

    static func brakeFluidBleed() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Brake Fluid Bleed & Fill",
            system: .brakes,
            subsystem: "Brake Fluid Service",
            workshopManualReference: "Brakes - Fluid - Bleeding Procedure",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Inspect brake fluid reservoir level"),
                MaintenanceProcedureStep(order: 2, instruction: "Position vehicle on level ground"),
                MaintenanceProcedureStep(order: 3, instruction: "Start with driver-side rear caliper"),
                MaintenanceProcedureStep(order: 4, instruction: "Locate bleeder screw (top of caliper)"),
                MaintenanceProcedureStep(order: 5, instruction: "Connect clear tubing to bleeder, submerge in container of brake fluid"),
                MaintenanceProcedureStep(order: 6, instruction: "Open bleeder screw 1/2 turn"),
                MaintenanceProcedureStep(order: 7, instruction: "Pump brake pedal until clear (no air bubbles visible)"),
                MaintenanceProcedureStep(order: 8, instruction: "Close bleeder screw", torqueSpec: MaintenanceTorqueSpec(component: "Bleeder screw", value: 8)),
                MaintenanceProcedureStep(order: 9, instruction: "Repeat for remaining calipers: passenger-rear, driver-front, passenger-front"),
                MaintenanceProcedureStep(order: 10, instruction: "Fill reservoir to proper level", warning: "Low fluid during bleeding introduces air into system")
            ],
            parts: [
                MaintenancePart(name: "Brake fluid", partNumber: "Motorcraft DOT-3", quantity: 1)
            ],
            tools: [
                MaintenanceTool(name: "Brake bleeder kit or clear tubing"),
                MaintenanceTool(name: "8mm wrench"),
                MaintenanceTool(name: "Container for fluid"),
                MaintenanceTool(name: "Jack + jack stands")
            ],
            estimatedTime: 45,
            difficulty: .intermediate,
            sourceChannel: "Ford Workshop Manual",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            notes: "Bleed sequence: RR → LR → RF → LF. Do not allow reservoir to empty during procedure. Street: every 2 years. Track: annually or before intensive use."
        )
    }

    static func wheelRemoval() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Wheel Removal & Reinstallation",
            system: .wheels,
            subsystem: "Wheel Service",
            workshopManualReference: "Wheels & Tires - Removal & Installation",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Park on level ground", warning: "Always use proper lift procedure with jack stands"),
                MaintenanceProcedureStep(order: 2, instruction: "Using 21mm socket, loosen lug nuts 1/2 turn (do not remove)"),
                MaintenanceProcedureStep(order: 3, instruction: "Raise vehicle on lift or use jack + jack stands"),
                MaintenanceProcedureStep(order: 4, instruction: "Remove lug nuts completely (store in container)"),
                MaintenanceProcedureStep(order: 5, instruction: "Remove wheel straight toward you"),
                MaintenanceProcedureStep(order: 6, instruction: "Inspect rotor, caliper, brake lines, bearings for damage"),
                MaintenanceProcedureStep(order: 7, instruction: "When reinstalling, align holes and push wheel onto hub"),
                MaintenanceProcedureStep(order: 8, instruction: "Hand-thread lug nuts"),
                MaintenanceProcedureStep(order: 9, instruction: "Torque lug nuts to 150 lb-ft in X pattern", torqueSpec: MaintenanceTorqueSpec(component: "Wheel lug nuts", value: 150, sequence: "X pattern: cross opposing corners")),
                MaintenanceProcedureStep(order: 10, instruction: "Lower vehicle")
            ],
            tools: [
                MaintenanceTool(name: "Jack and jack stands"),
                MaintenanceTool(name: "21mm socket"),
                MaintenanceTool(name: "Torque wrench (50-150 lb-ft range)"),
                MaintenanceTool(name: "Wheel chocks (safety)")
            ],
            estimatedTime: 20,
            difficulty: .beginner,
            applicableIntensities: [.street, .performanceStreet, .hpde],
            sourceChannel: "Ford Workshop Manual",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            notes: "Critical: Use 150 lb-ft for all GT500 wheels. Under-torqued lugs can loosen; over-torqued studs can break. Recheck torque after 50 miles of driving."
        )
    }

    static func dtcFluidCheck() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "DCT Transmission Fluid Level Check",
            system: .dct,
            subsystem: "Fluid Level",
            workshopManualReference: "Transmission - TR-9070 - Fluid Level",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Park vehicle on level ground, engine off"),
                MaintenanceProcedureStep(order: 2, instruction: "Allow transmission to cool (5-10 minutes)"),
                MaintenanceProcedureStep(order: 3, instruction: "Remove underbody shield for transmission access"),
                MaintenanceProcedureStep(order: 4, instruction: "Locate transmission fluid level check hole (driver side)"),
                MaintenanceProcedureStep(order: 5, instruction: "Remove fill plug"),
                MaintenanceProcedureStep(order: 6, instruction: "Fluid should be level with bottom of fill hole", warning: "Do not overfill; excess fluid causes pressure issues"),
                MaintenanceProcedureStep(order: 7, instruction: "If low, add Motorcraft MERCON ULV through fill plug"),
                MaintenanceProcedureStep(order: 8, instruction: "Check again; repeat until at proper level"),
                MaintenanceProcedureStep(order: 9, instruction: "Reinstall fill plug", torqueSpec: MaintenanceTorqueSpec(component: "DCT fill plug", value: 20))
            ],
            tools: [
                MaintenanceTool(name: "Jack + jack stands"),
                MaintenanceTool(name: "Fluid container (clean)")
            ],
            fluids: [
                Fluid(name: "Transmission fluid", specification: "Motorcraft MERCON ULV", quantity: 1, unit: "quarts", vendorReference: "Motorcraft")
            ],
            estimatedTime: 15,
            difficulty: .beginner,
            sourceChannel: "Ford Workshop Manual",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            notes: "Check monthly on track vehicles. Symptom of low fluid: transmission overheating, clutch slip. Never mix fluid types."
        )
    }

    static func alignmentReference() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Track Alignment Reference & Setup",
            system: .suspension,
            subsystem: "Alignment",
            workshopManualReference: "Suspension - Alignment - Adjustable Parameters",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Record current alignment at street setup"),
                MaintenanceProcedureStep(order: 2, instruction: "Document: front camber, caster, toe; rear camber, toe"),
                MaintenanceProcedureStep(order: 3, instruction: "Note tire pressures at setup"),
                MaintenanceProcedureStep(order: 4, instruction: "After track session, measure tire temps and wear patterns"),
                MaintenanceProcedureStep(order: 5, instruction: "Adjust for track if needed: typically -2° front camber, -1.5° rear camber, minimal toe"),
                MaintenanceProcedureStep(order: 6, instruction: "Record new settings and corresponding tire behavior"),
                MaintenanceProcedureStep(order: 7, instruction: "Return to street setup after track use")
            ],
            tools: [
                MaintenanceTool(name: "Alignment rack or laser alignment tool"),
                MaintenanceTool(name: "Tire temperature gun"),
                MaintenanceTool(name: "Tire wear gauge")
            ],
            estimatedTime: 120,
            difficulty: .advanced,
            applicableIntensities: [.hpde],
            sourceChannel: "ShelbyFlyer",
            sourceConfidence: .c3,
            workshopAlignment: "Strategy-based",
            notes: "Street: 0.5° front camber, 0.0° rear, slight toe-in. Track: more negative camber for tire contact. Document both setups for reference."
        )
    }

    static func plugInspection() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Spark Plug Inspection & Change",
            system: .engine,
            subsystem: "Ignition",
            workshopManualReference: "Engine - Ignition - Spark Plugs",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Locate spark plugs (8 total, one per cylinder)"),
                MaintenanceProcedureStep(order: 2, instruction: "Remove coil pack from cylinder 1 (number location marked on cover)"),
                MaintenanceProcedureStep(order: 3, instruction: "Use spark-plug socket to remove plug"),
                MaintenanceProcedureStep(order: 4, instruction: "Inspect electrode gap (should be 0.024-0.028 inches)", warning: "Black/wet plugs indicate rich condition; white plugs indicate lean"),
                MaintenanceProcedureStep(order: 5, instruction: "If replacing, gap new plugs to 0.024-0.028 inches"),
                MaintenanceProcedureStep(order: 6, instruction: "Install new plug and torque to 10 lb-ft", torqueSpec: MaintenanceTorqueSpec(component: "Spark plug", value: 10)),
                MaintenanceProcedureStep(order: 7, instruction: "Reinstall coil pack"),
                MaintenanceProcedureStep(order: 8, instruction: "Repeat for all 8 cylinders")
            ],
            parts: [
                MaintenancePart(name: "Spark plug", partNumber: "Motorcraft SP-532", quantity: 8, vendorReference: "Motorcraft")
            ],
            tools: [
                MaintenanceTool(name: "Spark plug socket (5/8 inch)"),
                MaintenanceTool(name: "Ratchet"),
                MaintenanceTool(name: "Spark plug gap tool"),
                MaintenanceTool(name: "Torque wrench")
            ],
            estimatedTime: 45,
            difficulty: .intermediate,
            sourceChannel: "Ford Workshop Manual",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            notes: "Street: 30,000 miles or when gap exceeds spec. Performance: 10,000 miles. Inspect before any tuning change as baseline."
        )
    }

    static func beltInspection() -> MaintenanceProcedure {
        MaintenanceProcedure(
            title: "Serpentine Belt Inspection",
            system: .engine,
            subsystem: "Belts & Hoses",
            workshopManualReference: "Engine - Belts - Serpentine Drive",
            steps: [
                MaintenanceProcedureStep(order: 1, instruction: "Locate serpentine belt routing (diagram inside engine cover)"),
                MaintenanceProcedureStep(order: 2, instruction: "Inspect belt for cracks, fraying, or glazing", warning: "Cracked belts can break suddenly; do not ignore visible damage"),
                MaintenanceProcedureStep(order: 3, instruction: "Check belt tension: should deflect 1/4 inch at midspan with moderate thumb pressure"),
                MaintenanceProcedureStep(order: 4, instruction: "Inspect pulley condition (idler, tensioner, alternator)"),
                MaintenanceProcedureStep(order: 5, instruction: "If belt is damaged or over 60k miles, plan replacement"),
                MaintenanceProcedureStep(order: 6, instruction: "Document belt condition in service record")
            ],
            tools: [
                MaintenanceTool(name: "Visual inspection only")
            ],
            estimatedTime: 10,
            difficulty: .beginner,
            sourceChannel: "Ford Workshop Manual",
            sourceConfidence: .c5,
            workshopAlignment: "Direct match",
            notes: "Street: inspect every 30,000 miles. Performance/Track: inspect before each event. Supercharger load increases belt stress."
        )
    }
}
