import Foundation

/// Disk-backed cache for parsed scanner datasets. The original CSV remains the immutable evidence.
/// Cache identity must include source identity plus parser/resolver versions so stale derived data is never reused.
struct PersistentDatasetCache {
    struct Envelope: Codable {
        var schemaVersion: Int
        var sourceIdentity: String
        var parserVersion: String
        var channelResolverVersion: String
        var filename: String
        var channels: [String]
        var timestamps: [TimeInterval]
        var rows: [[String: String]]
        var duration: TimeInterval
    }

    private let fileManager = FileManager.default

    func load(key: String, sourceURL: URL) throws -> ParsedLogData? {
        let url = try cacheURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        guard envelope.schemaVersion == 1 else { return nil }
        let samples: [[String: Any]] = envelope.rows.map { row in
            row.reduce(into: [String: Any]()) { result, pair in
                if let number = Double(pair.value) { result[pair.key] = number }
                else { result[pair.key] = pair.value }
            }
        }
        return ParsedLogData(filename: envelope.filename, fileURL: sourceURL, channels: envelope.channels,
                             timestamps: envelope.timestamps, samples: samples,
                             duration: envelope.duration, sampleCount: samples.count)
    }

    func save(_ parsed: ParsedLogData, key: String, sourceIdentity: String) throws {
        let rows: [[String: String]] = parsed.samples.map { sample in
            sample.reduce(into: [String: String]()) { result, pair in
                if let value = pair.value as? Double { result[pair.key] = String(format: "%.17g", value) }
                else if let value = pair.value as? String { result[pair.key] = value }
            }
        }
        let envelope = Envelope(schemaVersion: 1, sourceIdentity: sourceIdentity,
                                parserVersion: AnalysisEngineVersion.current.parser,
                                channelResolverVersion: AnalysisEngineVersion.current.channelResolver,
                                filename: parsed.filename, channels: parsed.channels,
                                timestamps: parsed.timestamps, rows: rows, duration: parsed.duration)
        let encoder = JSONEncoder()
        let data = try encoder.encode(envelope)
        try data.write(to: cacheURL(for: key), options: .atomic)
    }

    func removeAll() throws {
        let directory = try cacheDirectory()
        if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
    }

    private func cacheURL(for key: String) throws -> URL {
        let safe = key.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-") ?? UUID().uuidString
        return try cacheDirectory().appendingPathComponent(safe).appendingPathExtension("plcache")
    }

    private func cacheDirectory() throws -> URL {
        let root = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = root.appendingPathComponent("PredatorLab/DerivedDatasetCache", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
