import Foundation
#if canImport(os)
import os
#endif

enum PLStructuredLog {
    enum Level: String { case debug, info, warning, error }
    static func event(_ name: String, level: Level = .info, fields: [String: String] = [:]) {
        let payload = fields.keys.sorted().map { "\($0)=\(fields[$0] ?? "")" }.joined(separator: " ")
        #if canImport(os)
        let logger = Logger(subsystem: "com.predatorlab.PredatorLab", category: "engineering")
        switch level {
        case .debug: logger.debug("\(name, privacy: .public) \(payload, privacy: .private(mask: .hash))")
        case .info: logger.info("\(name, privacy: .public) \(payload, privacy: .private(mask: .hash))")
        case .warning: logger.warning("\(name, privacy: .public) \(payload, privacy: .private(mask: .hash))")
        case .error: logger.error("\(name, privacy: .public) \(payload, privacy: .private(mask: .hash))")
        }
        #else
        _ = (name, level, payload) // Linux/source-validation fallback; no console leakage of evidence fields.
        #endif
    }
}
