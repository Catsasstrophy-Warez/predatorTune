// PredatorLab/State/AppState.swift
// Centralized app state management
//
// Merged from two prior drafts: session-logging/UI state (root AppState.swift)
// + phase-gate enforcement (PredatorLab_CoreModels.swift's AppState, gate logic only —
//   that file's own AppState class was dropped to avoid a duplicate-class conflict).

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: Vehicle & Build
    @Published var isOnboarded = false
    @Published var currentVehicle: GT500Vehicle?
    @Published var allVehicles: [GT500Vehicle] = []
    @Published var currentBuildStateID: UUID?

    // MARK: Tuning Phase & Gates
    @Published var currentPhase: TuningPhase = .r00StockTruth
    @Published var tuningGates: [CalibrationGate] = []

    // MARK: Session Logging
    @Published var currentSession: Session?
    @Published var isLogging = false
    @Published var sessionStartTime: Date?
    @Published var sessionEvents: [EventCard] = []
    @Published var sessionFlightRecords: [FlightRecord] = []
    @Published var currentLogData: ParsedLogData?

    // MARK: Investigation State
    @Published var currentInvestigation: Investigation?
    @Published var allInvestigations: [Investigation] = []
    @Published var r04Hypotheses: [DiagnosticHypothesis] = []

    // MARK: Imported Logs
    @Published var allLogs: [ImportedLog] = []
    @Published var activeEvents: [LogEvent] = []

    // MARK: UI State
    @Published var selectedTab: Int = 5
    @Published var showSessionForm = false
    @Published var showImportDialog = false
    @Published var showR04Dialog = false

    // MARK: Storage status (local persistence today; cloud sync is not claimed)
    @Published var syncStatus: SyncStatus = .localSaved

    // MARK: Settings
    @Published var darkMode: Bool?
    @Published var textScale: CGFloat = 1.0
    @Published var colorblindMode = false
    @Published var highContrastMode = false
    @Published var gloveFriendlyMode = true
    @Published var hapticFeedback = true
    @Published var screenLockWhileLogging = true

    enum SyncStatus: Equatable {
        case localSaved
        case saving
        case error(String)
        case unavailable
    }

    init() {
        setupDefaultGates()
    }

    // MARK: - Session Lifecycle

    func startSession(mode: SessionMode, location: String?, notes: String?, experimentContext: SessionExperimentContext? = nil) {
        let session = Session(
            vehicleID: currentVehicle?.id ?? UUID(),
            buildStateID: currentBuildStateID ?? UUID(),
            mode: mode,
            title: "\(mode.rawValue) — \(Date.now.formatted(date: .abbreviated, time: .shortened))",
            location: location,
            experimentContext: experimentContext,
            notes: notes ?? "",
            objectives: [],
            createdBy: "owner"
        )

        self.currentSession = session
        self.sessionStartTime = .now
        self.isLogging = true
        self.sessionEvents = []
        self.sessionFlightRecords = []
    }

    func stopSession() {
        guard let startTime = sessionStartTime, var session = currentSession else { return }

        session.duration = Date.now.timeIntervalSince(startTime)
        session.eventCards = sessionEvents
        session.flightRecords = sessionFlightRecords
        session.lastModified = .now

        self.currentSession = session
        self.isLogging = false
    }

    func addEvent(_ event: EventCard) {
        sessionEvents.append(event)
    }

    func addFlightRecord(_ record: FlightRecord) {
        sessionFlightRecords.append(record)
    }

    func clearCurrentSession() {
        currentSession = nil
        sessionStartTime = nil
        sessionEvents = []
        sessionFlightRecords = []
        isLogging = false
        currentLogData = nil
    }

    // MARK: - Phase Gate Enforcement

    func setupDefaultGates() {
        // R04 is locked until investigation complete
        tuningGates.append(
            CalibrationGate(
                phase: .r04FuelCapability,
                title: "Fuel Capability Investigation",
                requirements: [
                    "Fuel-pressure PID identity validated",
                    "Lambda channels cross-checked",
                    "Injector demand behavior characterized",
                    "Insufficient Fuel Flow event captured and analyzed",
                    "Primary hypothesis identified with supporting evidence"
                ],
                isSatisfied: false,
                blockingReason: "R05–R09 remain locked until fuel-protection root cause is documented."
            )
        )

        // R07 is locked until dyno validation
        tuningGates.append(
            CalibrationGate(
                phase: .r07TorqueModel,
                title: "Torque Model Validation",
                requirements: [
                    "Independent torque-model validation evidence attached",
                    "Requested/observed torque semantics reviewed for the exact controller/strategy",
                    "Throttle semantic and measurement provenance reviewed",
                    "Matched repeated runs demonstrate acceptable experiment repeatability under an explicitly authored acceptance contract"
                ],
                isSatisfied: false,
                blockingReason: "R08–R09 remain locked until torque-model accuracy is confirmed by an explicit, source-backed or user-authored acceptance contract and independent measurement."
            )
        )
    }

    func canEnter(_ phase: TuningPhase) -> Bool { blockingGates(for: phase).isEmpty }

    func blockingGates(for phase: TuningPhase) -> [CalibrationGate] {
        tuningGates.filter { !$0.isSatisfied && $0.phase.rawValue < phase.rawValue }
    }

    /// Compatibility helper for older views: asks whether the immediately following phase is enterable.
    func unlockNextPhase(after phase: TuningPhase) -> Bool {
        guard let next = TuningPhase(rawValue: phase.rawValue + 1) else { return true }
        return canEnter(next)
    }

    func gateFor(_ phase: TuningPhase) -> CalibrationGate? {
        tuningGates.first { $0.phase == phase }
    }

    func satisfyGate(_ phase: TuningPhase) {
        if let index = tuningGates.firstIndex(where: { $0.phase == phase }) {
            tuningGates[index].isSatisfied = true
        }
    }
}

// MARK: - Sync Status Extension

extension AppState.SyncStatus {
    var description: String {
        switch self {
        case .localSaved: return "Saved locally"
        case .saving: return "Saving..."
        case .error(let msg): return "Save error: \(msg)"
        case .unavailable: return "Storage unavailable"
        }
    }
}
