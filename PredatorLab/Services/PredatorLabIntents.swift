import AppIntents
import Foundation

/// Gives App Intents access to the running app's state. Set once at launch.
@MainActor
final class IntentRouter {
    static let shared = IntentRouter()
    weak var appState: AppState?
    weak var dataRepository: DataRepository?
}

struct StartLoggingSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Logging Session"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let appState = IntentRouter.shared.appState else { return .result(dialog: "Open PredatorLab first.") }
        guard appState.currentVehicle != nil else { return .result(dialog: "Add your vehicle in Garage before logging.") }
        guard !appState.isLogging else { return .result(dialog: "A session is already recording.") }
        appState.startSession(mode: .streetCruise, location: nil, notes: "Started from Shortcuts")
        appState.open(.garage)
        return .result(dialog: "Logging session started.")
    }
}

struct StopLoggingSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Logging Session"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let appState = IntentRouter.shared.appState, appState.isLogging else { return .result(dialog: "No session is recording.") }
        appState.stopSession()
        if let session = appState.currentSession, let repository = IntentRouter.shared.dataRepository {
            try await repository.save(session: session)
        }
        appState.open(.garage)
        return .result(dialog: "Session stopped and saved. Import the HP Tuners export to attach it.")
    }
}

struct ImportLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Import HP Tuners Log"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentRouter.shared.appState?.requestImportPicker = true
        IntentRouter.shared.appState?.openAnalyze(.logs)
        return .result()
    }
}

struct PredatorLabShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartLoggingSessionIntent(), phrases: [
            "Start a \(.applicationName) session",
            "Start logging with \(.applicationName)",
        ])
        AppShortcut(intent: StopLoggingSessionIntent(), phrases: [
            "Stop the \(.applicationName) session",
            "Stop logging with \(.applicationName)",
        ])
        AppShortcut(intent: ImportLogIntent(), phrases: [
            "Import a log into \(.applicationName)",
        ])
    }
}
