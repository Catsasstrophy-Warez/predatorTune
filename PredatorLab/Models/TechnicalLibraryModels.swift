// PredatorLab/Models/TechnicalLibraryModels.swift
// Six normalized databases: Components, Circuits, Sensors/PIDs, DTCs, Calibration, Procedures
// All records sourced, graded (A-D), and cross-linked for integrated query

import Foundation

// MARK: - Evidence & Sourcing (Foundation for all six databases)

enum SourceGrade: String, Codable, CaseIterable {
    case a_factory = "A-Factory"
    case b_professional = "B-Professional"
    case c_owner = "C-Owner"
    case d_reference = "D-Reference"

    var description: String {
        switch self {
        case .a_factory:
            return "Ford/Ford Performance official documentation (highest authority)"
        case .b_professional:
            return "Manufacturer/tuner/supplier professional documentation"
        case .c_owner:
            return "Verified GT500-specific real-world owner procedures"
        case .d_reference:
            return "Transferable adjacent content requiring verification"
        }
    }

    var weight: Double {
        switch self {
        case .a_factory: return 1.0
        case .b_professional: return 0.8
        case .c_owner: return 0.6
        case .d_reference: return 0.4
        }
    }
}

struct TechnicalSource: Codable, Equatable {
    var title: String
    var sourceType: String // "Ford WSM", "HP Tuners Doc", "YouTube", "TREMEC Spec", etc.
    var reference: String // Section number, URL, timestamp, etc.
    var grade: SourceGrade
    var confidence: ConfidenceLevel
    var url: String?
    var accessMethod: String? // "Ford Service Info subscription", "Public NHTSA", "Professional manual", etc.
    var notes: String?

    // None of these fields have inline defaults (kept that way so the ingestion pipeline's
    // memberwise construction stays untouched), so this convenience init exists purely to make
    // authoring seed/reference data less verbose.
    init(
        title: String,
        sourceType: String,
        reference: String,
        grade: SourceGrade,
        confidence: ConfidenceLevel,
        url: String? = nil,
        accessMethod: String? = nil,
        notes: String? = nil
    ) {
        self.title = title
        self.sourceType = sourceType
        self.reference = reference
        self.grade = grade
        self.confidence = confidence
        self.url = url
        self.accessMethod = accessMethod
        self.notes = notes
    }
}

// MARK: - 1. COMPONENT DATABASE

struct ComponentRecord: Identifiable, Codable {
    let id: UUID

    var name: String // "R2650 Supercharger Pulley", "TR-9070 DCT", etc.
    var section: ComponentSection // Organized by major subsystem
    var oem: String? // OEM part name/number
    var manufacturer: String? // Eaton, TREMEC, Ford, etc.

    // Physical specs
    var specifications: [ComponentSpec]
    var physicalLocation: ComponentLocation?
    var assemblyDiagram: String? // Reference to diagram in app

    // Variants (stock vs aftermarket)
    var variants: [ComponentVariant]

    // Relationships
    var upstreamComponents: [UUID] // What feeds into this
    var downstreamComponents: [UUID] // What this feeds into
    var relatedCircuits: [UUID]
    var relatedSensors: [UUID]
    var relatedCalibration: [UUID]

    // Service & failure
    var failureModes: [FailureMode]
    var maintenanceIntervals: [MaintenanceInterval]

    // Evidence
    var sources: [TechnicalSource]
    var lastUpdated: Date
    var updatedBy: String

    /// Full designated init (mirrors the original memberwise init) — kept so a completed
    /// ingestion pipeline can still populate every field, including cross-links.
    init(
        id: UUID = UUID(),
        name: String,
        section: ComponentSection,
        oem: String?,
        manufacturer: String?,
        specifications: [ComponentSpec],
        physicalLocation: ComponentLocation?,
        assemblyDiagram: String?,
        variants: [ComponentVariant],
        upstreamComponents: [UUID],
        downstreamComponents: [UUID],
        relatedCircuits: [UUID],
        relatedSensors: [UUID],
        relatedCalibration: [UUID],
        failureModes: [FailureMode],
        maintenanceIntervals: [MaintenanceInterval],
        sources: [TechnicalSource],
        lastUpdated: Date,
        updatedBy: String
    ) {
        self.id = id
        self.name = name
        self.section = section
        self.oem = oem
        self.manufacturer = manufacturer
        self.specifications = specifications
        self.physicalLocation = physicalLocation
        self.assemblyDiagram = assemblyDiagram
        self.variants = variants
        self.upstreamComponents = upstreamComponents
        self.downstreamComponents = downstreamComponents
        self.relatedCircuits = relatedCircuits
        self.relatedSensors = relatedSensors
        self.relatedCalibration = relatedCalibration
        self.failureModes = failureModes
        self.maintenanceIntervals = maintenanceIntervals
        self.sources = sources
        self.lastUpdated = lastUpdated
        self.updatedBy = updatedBy
    }

    /// Convenience init for reference-library seed data: fills relationship/cross-link
    /// fields (populated later by the ingestion pipeline) with sensible empty defaults.
    init(
        name: String,
        section: ComponentSection,
        oem: String? = nil,
        manufacturer: String? = nil,
        specifications: [ComponentSpec] = [],
        physicalLocation: ComponentLocation? = nil,
        variants: [ComponentVariant] = [],
        failureModes: [FailureMode] = [],
        maintenanceIntervals: [MaintenanceInterval] = [],
        sources: [TechnicalSource] = []
    ) {
        self.id = UUID()
        self.name = name
        self.section = section
        self.oem = oem
        self.manufacturer = manufacturer
        self.specifications = specifications
        self.physicalLocation = physicalLocation
        self.assemblyDiagram = nil
        self.variants = variants
        self.upstreamComponents = []
        self.downstreamComponents = []
        self.relatedCircuits = []
        self.relatedSensors = []
        self.relatedCalibration = []
        self.failureModes = failureModes
        self.maintenanceIntervals = maintenanceIntervals
        self.sources = sources
        self.lastUpdated = .now
        self.updatedBy = "seed_data"
    }

    /// Best evidence grade among this component's sources — drives the badge shown in Reference Library.
    var evidenceGrade: SourceGrade? {
        sources.map(\.grade).min { $0.weight > $1.weight }
    }
}

enum ComponentSection: String, Codable, CaseIterable {
    case engine = "Engine"
    case supercharger = "Supercharger"
    case fuel = "Fuel System"
    case intake = "Intake & Airflow"
    case ignition = "Spark & Ignition"
    case dct = "DCT Transmission"
    case exhaust = "Exhaust"
    case cooling = "Cooling & Thermal"
    case suspension = "Suspension & Handling"
    case brakes = "Brakes"
    case electrical = "Electrical & CAN"
    case structural = "Chassis & Structure"
}

// Plain tuples aren't Codable — using a struct so ComponentSpec/SensorTypicalValue can synthesize Codable.
struct ValueRange: Codable {
    var min: Double
    var max: Double
}

struct ComponentSpec: Codable {
    var parameter: String // "Drive ratio", "Max RPM", "Torque rating"
    var value: String
    var units: String?
    var range: ValueRange? // For specs with ranges
    var tolerance: String? // "±0.5 mm"
    var source: TechnicalSource
    var notes: String?

    init(
        parameter: String,
        value: String,
        units: String? = nil,
        range: ValueRange? = nil,
        tolerance: String? = nil,
        source: TechnicalSource,
        notes: String? = nil
    ) {
        self.parameter = parameter
        self.value = value
        self.units = units
        self.range = range
        self.tolerance = tolerance
        self.source = source
        self.notes = notes
    }
}

struct ComponentLocation: Codable {
    var subsection: String // "Engine bay, driver side"
    var access: String // "Requires coolant reservoir removal"
    var connectors: [String] // "C105", "fuel line, -12AN quick disconnect"
    var references: [String] // "Ford diagram 303-14D-1", "VMP step 3"

    init(subsection: String, access: String, connectors: [String] = [], references: [String] = []) {
        self.subsection = subsection
        self.access = access
        self.connectors = connectors
        self.references = references
    }
}

struct ComponentVariant: Codable {
    var name: String // "Stock 3.35:1", "Lethal 3.73:1", etc.
    var application: String // "Base GT500", "High-boost tune", etc.
    var specifications: [ComponentSpec]
    var effects: [String] // "Increases boost by ~0.5 psi", "Requires tune change"
    var reliability: String? // "Multiple high-hour examples", "Limited data"
    var source: TechnicalSource
}

struct FailureMode: Codable {
    var name: String
    var symptoms: [String]
    var rootCause: String
    var diagnosticMethod: String
    var remedy: String
    var preventiveCare: String?
    var riskLevel: String // "Low", "Medium", "High", "Critical"

    init(
        name: String,
        symptoms: [String],
        rootCause: String,
        diagnosticMethod: String,
        remedy: String,
        riskLevel: String,
        preventiveCare: String? = nil
    ) {
        self.name = name
        self.symptoms = symptoms
        self.rootCause = rootCause
        self.diagnosticMethod = diagnosticMethod
        self.remedy = remedy
        self.riskLevel = riskLevel
        self.preventiveCare = preventiveCare
    }
}

struct MaintenanceInterval: Codable {
    var procedure: String // Link to procedure name
    var interval: String // "Every 10,000 miles", "After each track weekend", etc.
    var intensity: String // "Street", "Performance Street", "HPDE/Track"
    var reason: String
}

// MARK: - 2. CIRCUIT DATABASE

struct CircuitRecord: Identifiable, Codable {
    let id: UUID

    var name: String // "Fuel pump power supply", "TCM CAN bus", etc.
    var subsystem: String // Which major system this belongs to
    var function: String // What the circuit does

    // Complete circuit path
    var path: [CircuitNode] // Ordered from source to load

    // Connectors involved
    var connectors: [ConnectorDetail]

    // Wiring details
    var wireColor: String?
    var wireGauge: String?
    var circuitId: String? // Ford circuit ID

    // Electrical specs
    var nominalVoltage: String? // "12V", "5V signal"
    var expectedCurrent: String? // "Max 10 A"
    var groundPath: String?

    // CAN/Network
    var canNetwork: String? // "Body CAN", "Powertrain CAN"
    var canId: String? // CAN frame ID if applicable

    // Diagnostics
    var koeoExpected: String? // Key-off engine-off reading
    var koerExpected: String? // Key-on engine-running
    var loadedExpected: String? // Under load
    var relatedDTCs: [String]

    // Service & Troubleshooting
    var commonIssues: [CircuitIssue]
    var testPoints: [TestPoint]

    // Evidence
    var sources: [TechnicalSource]
    var wiring: WiringDiagramReference?
}

struct CircuitNode: Codable {
    var sequence: Int // Order in path
    var type: String // "Power source", "Fuse", "Relay", "Splice", "Connector", "Module pin", "Sensor", "Actuator", "Ground"
    var designation: String // "Battery positive", "Fuse 27", "C105", "TCM pin A32", "Fuel pump motor"
    var details: String? // "15 A maxi fuse", "4-pin connector, gray", etc.
    var voltage: String? // "12V", "5V", "0V (ground)"
    var expectedReading: String? // "12V with engine running", "5V signal square wave"
}

struct ConnectorDetail: Codable {
    var name: String // "C105", "Fuel pump connector"
    var location: String
    var pinCount: Int
    var type: String // "Weather-pack", "Metripack", etc.
    var pins: [ConnectorPin]
    var knownIssues: [String]? // "2020 GT500 TSB: pushed-out terminals"
    var testPoints: [String]?
}

struct ConnectorPin: Codable {
    var number: Int
    var color: String?
    var function: String
    var expectedVoltage: String?
    var currentDraw: String?
}

struct TestPoint: Codable {
    var name: String
    var location: String
    var tools: [String]
    var expectedResult: String
    var failureInterpretation: String
    var relatedDTC: String?
}

struct CircuitIssue: Codable {
    var problem: String
    var symptoms: [String]
    var diagnosis: String
    var remedy: String
    var source: TechnicalSource?
}

struct WiringDiagramReference: Codable {
    var manual: String // "2020 Mustang Wiring Diagram Manual"
    var section: String
    var diagram: String
    var publisher: String
    var partNumber: String?
}

// MARK: - 3. SENSOR/PID DATABASE

struct SensorRecord: Identifiable, Codable {
    let id: UUID

    var name: String // "Fuel rail pressure sensor"
    var pidName: String? // "FRP_ACTUAL"
    var pidId: String? // Hexadecimal PID ID

    // Measurement specs
    var units: String // "psi", "°C", "lambda", "RPM"
    var minValue: Double
    var maxValue: Double
    var resolution: Double? // 0.1 psi
    var dataType: String // "Analog", "Digital", "Enum", "PWM"

    // Typical operating values
    var typicalValues: [SensorTypicalValue]

    // Physical component
    var physicalComponent: UUID? // Link to ComponentRecord (injector, sensor, etc.)
    var physicalLocation: String?
    var connectorRef: String?

    // Circuit & electrical
    var relatedCircuit: UUID? // Link to CircuitRecord
    var voltage: String? // "5V signal", "12V power"
    var impedance: String?

    // Data acquisition
    var scannerChannels: [String] // Multiple names it might appear under in different scanners
    var updateFrequency: String? // "Continuous", "10 Hz", "Per cylinder event"
    var responseLag: String? // "Minimal", "~100 ms"

    // Diagnostic use
    var diagnosticPurpose: String
    var relatedDTCs: [String]
    var relatedProcedures: [UUID]
    var relatedCalibration: [UUID]

    // Cross-dependencies
    var upstreamInputs: [String] // What affects this reading
    var downstreamOutputs: [String] // What this reading affects

    // Evidence
    var sources: [TechnicalSource]
}

struct SensorTypicalValue: Codable {
    var condition: String // "KOEO (key-on, engine off)", "Idle 600 rpm, cold", "WOT 6500 rpm, heat-soak"
    var expectedValue: Double
    var tolerance: ValueRange
    var notes: String?
}

// MARK: - 4. DTC/PINPOINT TEST DATABASE

struct DTCRecord: Identifiable, Codable {
    let id: UUID

    var code: String // "P0604", "U3000:62"
    var title: String
    var description: String
    var severity: String // "Info", "Warning", "Critical"

    // What this DTC relates to
    var relatedComponent: UUID?
    var relatedCircuits: [UUID]
    var relatedSensors: [UUID]

    // Diagnostic logic
    var monitorLogic: MonitorLogic
    var failureThreshold: String
    var rationalityTests: [String]

    // Known issues (TSBs, common causes)
    var knownIssues: [KnownIssue]

    // Pinpoint diagnostic procedure
    var pinpointTest: PinpointProcedure

    // Evidence
    var sources: [TechnicalSource]
    var relatedTSBs: [String]? // "GT500 TSB 20-1234"
    var relatedSSMs: [String]?
}

struct MonitorLogic: Codable {
    var name: String // "Fuel pressure monitor"
    var enableConditions: [String] // When monitor is active
    var testMethod: String // How it's tested
    var failureCondition: String // What constitutes failure
    var rationality: String // Plausibility check description
    var enableMask: String? // Technical: which monitors enabled in mode
}

struct KnownIssue: Codable {
    var issue: String
    var symptoms: [String]
    var commonCauses: [String]
    var diagnosis: String
    var remedy: String
    var relevance: String? // "2020 GT500 specific", "All years"
    var source: TechnicalSource
}

struct PinpointProcedure: Codable {
    var title: String
    var overview: String
    var steps: [PinpointStep]
    var testEquipment: [TestEquipment]
    var safetyWarnings: [String]
    var expectedResults: [String]
    var failureInterpretation: String
    var nextSteps: String // "If DTC confirmed, replace component X"
}

struct PinpointStep: Codable {
    var order: Int
    var instruction: String
    var expectedResult: String
    var ifPass: String // "Continue to step X"
    var ifFail: String // "Component is faulty, replace"
    var tools: [String]?
    var warnings: [String]?
}

struct TestEquipment: Codable {
    var name: String
    var purpose: String
    var critical: Bool // Required vs optional
}

// MARK: - 5. CALIBRATION DATABASE

struct CalibrationRecord: Identifiable, Codable {
    let id: UUID

    var name: String // "Fuel rail pressure target table"
    var section: String // Engine, Supercharger, Transmission, etc.
    var tableType: String // "Lookup table", "Transfer function", "Scalar"

    // VCM Editor reference
    var vcmPath: String? // "303-14D → Fuel control → Pressure tables"
    var vcmDisplayName: String?
    var parameterID: String? // Exact parameter name in VCM

    // Table structure
    var axes: CalibrationAxes
    var stockValues: [[Double]] // 2D array for lookup tables
    var units: String
    var resolution: Double?
    var displayFormat: String? // "0.0", "0.00"

    // Meaning & usage
    var function: String // "Determines base fuel rail pressure based on RPM and load"
    var role: String // "Input", "Intermediate", "Output"
    var controlStrategy: String // What control system uses this

    // Related systems
    var relatedSensors: [UUID] // PIDs that feed into this calculation
    var relatedDTCs: [UUID] // DTCs that indicate fault in this table
    var relatedComponents: [UUID]

    // Dependencies
    var upstream: [CalibrationLink] // "Boost estimate table" must be valid first
    var downstream: [CalibrationLink] // "Injector PW calculation depends on this"

    // Modification guidance
    var modificationPrerequisites: [String] // "Must upgrade fuel pump first"
    var modificationGuidance: String?
    var knownCrosslinks: [CrosslinkWarning]

    // Evidence
    var sources: [TechnicalSource]
    var historicalData: [CalibrationHistory]?
}

struct CalibrationAxes: Codable {
    var xAxis: String // "Engine RPM"
    var xMin: Double
    var xMax: Double
    var xStep: Double?
    var yAxis: String // "Calculated load"
    var yMin: Double
    var yMax: Double
    var yStep: Double?
    var zAxis: String? // For 3D tables
    var zMin: Double?
    var zMax: Double?
}

struct CalibrationLink: Codable {
    var relatedTable: String
    var relationship: String // "Blocks this table from changing", "Feeds input to", "Validates against"
    var consequence: String // "Increasing pressure requires fuel injector re-validation"
    var evidence: String
}

struct CrosslinkWarning: Codable {
    var warning: String
    var relatedTables: [String]
    var consequence: String
    var validation: String // How to ensure correctness
}

struct CalibrationHistory: Codable {
    var date: Date
    var change: String
    var reason: String
    var tuner: String?
    var evidence: String?
}

// MARK: - 6. PROCEDURE DATABASE

struct ProcedureRecord: Identifiable, Codable {
    let id: UUID

    var name: String // "R2650 Pulley Replacement"
    var system: ComponentSection
    var subsystem: String? // "Supercharger drive"
    var purpose: String

    // Applicability
    var applicability: ProcedureApplicability
    var difficulty: DifficultyLevel
    var estimatedTime: TimeInterval // in seconds
    var skillRequired: String
    var lifting: Bool // Requires lift?

    // Resources
    var tools: [Tool]
    var parts: [Part]
    var consumables: [Consumable]
    var safetyWarnings: [String]

    // Step-by-step procedure
    var steps: [ProcedureStep]

    // Cross-system linkage
    var relatedComponents: [UUID]
    var relatedCircuits: [UUID]
    var relatedSensors: [UUID]
    var relatedDTCs: [UUID]
    var relatedCalibration: [UUID] // "This procedure requires calibration change"
    var relatedProcedures: [UUID] // Prerequisites or follow-ups

    // Service history tracking
    var serviceInterval: String? // "Every 100k miles"
    var maintenanceIntensity: [String] // "Street", "Performance", "Track"

    // Diagnostics & "while you're in there"
    var inspectionPoints: [InspectionPoint]
    var whileYoureInThere: [WhileYoureInThereTip]

    // Source material
    var workshopManual: WorkshopReference?
    var youtubeSources: [YouTubeSourceDetail]
    var sources: [TechnicalSource]
}

struct ProcedureApplicability: Codable {
    var modelYears: [Int] // [2020, 2021, 2022]
    var variants: [String] // "Base", "CFTP", "Track Pack"
    var buildStates: [String]? // Hardware configuration specific applicability
    var notes: String?
}

// NOTE: DifficultyLevel is defined in MaintenanceAndLearning.swift (Identifiable variant, used by both files).

struct Tool: Codable {
    var name: String
    var description: String?
    var partNumber: String?
    var critical: Bool // Required vs "nice to have"
    var rental: Bool // Can be rented?
    var alternativeMethods: [String]?
    var cost: Double?
}

struct Part: Codable {
    var name: String
    var motorcraft: String? // Motorcraft part number
    var oem: String? // OEM part number
    var quantity: Int
    var critical: Bool
    var onceOnly: Bool // One-time-use hardware?
    var cost: Double?
    var vendor: String?
    var notes: String?
}

struct Consumable: Codable {
    var name: String
    var specification: String // "5W-50 synthetic", "Loctite 243"
    var quantity: Double
    var units: String // "quarts", "grams", "ml"
    var cost: Double?
    var vendor: String?
}

struct ProcedureStep: Codable {
    var order: Int
    var instruction: String
    var duration: TimeInterval? // in seconds
    var tools: [String]
    var parts: [String]?
    var consumables: [String]?
    var warnings: [String]?
    var inspectionPoints: [String]?
    var torqueSpec: TorqueSpec?
    var youTubeChapter: YouTubeChapter?
    var diagramReference: String?
    var notes: String?
}

struct TorqueSpec: Codable {
    var component: String
    var value: Double
    var units: String // "lb-ft", "Nm"
    var pattern: String? // "X-pattern", "alternating sequence", "one-time-only spec"
    var preload: String? // "Hand-tight plus 90°"
    var notes: String?
    var source: TechnicalSource?
}

struct YouTubeChapter: Codable {
    var videoId: String
    var startSeconds: Int
    var endSeconds: Int?
    var description: String?
}

struct InspectionPoint: Codable {
    var step: Int // Which procedure step
    var inspection: String // "Inspect injector seals"
    var condition: String // "Should show minimal wear"
    var photographic: Bool
    var notes: String?
}

struct WhileYoureInThereTip: Codable {
    var step: Int
    var tip: String // "Check throttle body gasket while fuel rail is off"
    var reason: String
    var toolsNeeded: [String]?
    var estimatedTime: TimeInterval?
}

struct WorkshopReference: Codable {
    var manual: String // "2020 Ford Mustang Workshop Manual"
    var section: String // "303-03A Accessory Drive"
    var partNumber: String?
    var publisher: String
    var url: String?
}

struct YouTubeSourceDetail: Codable {
    var title: String
    var channelName: String
    var videoId: String
    var publishDate: Date
    var chapters: [YouTubeChapter]
    var grade: SourceGrade
    var relevance: String // "Exact procedure", "Similar vehicle"
    var knownDifferences: [String]?
    var accuracy: String? // "Verified against Ford WSM", "Professional tuner"
}

// MARK: - Query Types (Support for cross-domain searches)

struct TechnicalQuery: Codable {
    var queryType: QueryType
    var keywords: [String]
    var filters: QueryFilters?
    var sourceGradeMin: SourceGrade? // Minimum acceptable evidence grade
    var sortBy: String? // "relevance", "grade", "date"
}

enum QueryType: String, Codable {
    case component = "Find component"
    case circuit = "Trace circuit"
    case sensor = "Find PID"
    case diagnostic = "Diagnose DTC"
    case procedure = "Find procedure"
    case crossDomain = "Integrated query"
}

struct QueryFilters: Codable {
    var modelYears: [Int]?
    var section: ComponentSection?
    var sourceGrades: [SourceGrade]?
    var difficulty: DifficultyLevel?
}

struct CrossDomainResult: Codable {
    var components: [ComponentRecord]
    var circuits: [CircuitRecord]
    var sensors: [SensorRecord]
    var dtcs: [DTCRecord]
    var procedures: [ProcedureRecord]
    var calibration: [CalibrationRecord]
}

// MARK: - Normalization Support Structs

struct NormalizationMetadata: Codable {
    var source: TechnicalSource
    var extractedAt: Date
    var extractionMethod: String // "Ford WSM section 303-14D", "YouTube chapter VMP 6:40-21:00", etc.
    var normalizedTo: String // Which database tables
    var confidence: ConfidenceLevel
    var reviewStatus: String // "Raw extract", "Normalized", "Verified", "Cross-validated"
    var reviewedBy: String?
    var notes: String?
}

// MARK: - Data Integrity & Consistency

struct ArchitectureValidation: Codable {
    var recordType: String // Component, Circuit, etc.
    var recordId: UUID
    var crossReferences: [CrossReferenceCheck]
    var integrityScore: Double // 0.0-1.0
    var issues: [ValidationIssue]?
}

struct CrossReferenceCheck: Codable {
    var linkedRecord: UUID
    var linkedType: String
    var linkType: String // "upstream", "downstream", "related"
    var verified: Bool
}

struct ValidationIssue: Codable {
    var issue: String
    var severity: String // "Info", "Warning", "Error"
    var suggestion: String
}
