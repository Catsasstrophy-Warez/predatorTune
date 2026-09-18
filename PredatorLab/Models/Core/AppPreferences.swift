import Foundation

struct AppPreferences: Codable, Equatable {
    var lastVehicleID: UUID?
    var lastBuildStateID: UUID?
    var selectedTab: Int = 5
    var currentPhase: TuningPhase = .r00StockTruth
    var darkMode: Bool?
    var textScale: Double = 1.0
    var colorblindMode = false
    var highContrastMode = false
    var gloveFriendlyMode = true
    var hapticFeedback = true
    var screenLockWhileLogging = true
}
