import Foundation

struct CSVIngestionDiagnostics: Codable, Equatable {
    var totalRows = 0
    var acceptedRows = 0
    var blankRows = 0
    var malformedRows = 0
    var invalidTimestampRows = 0
    var duplicateTimestampRows = 0
    var nonMonotonicTimestampRows = 0
}

struct CSVIngestionResult {
    var dataset: ParsedLogData
    var diagnostics: CSVIngestionDiagnostics
}

/// Bounded-memory record ingestion for scanner CSVs. It does not alter the original file.
/// Records are RFC-4180 aware, so quoted fields may contain commas and embedded newlines.
enum StreamingCSVIngestor {
    static func parse(fileURL: URL, chunkSize: Int = 256 * 1024,
                      isCancelled: () -> Bool = { false },
                      progress: ((Double) -> Void)? = nil) throws -> CSVIngestionResult {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.doubleValue ?? 0
        var buffer = Data(); var bytesRead: Double = 0; var header: [String]?; var timestampIndex: Int?
        var timestamps: [TimeInterval] = []; var samples: [[String: Any]] = []; var channels = Set<String>()
        var diagnostics = CSVIngestionDiagnostics(); var previousTimestamp: TimeInterval?

        func consume(_ raw: Data) throws {
            guard !raw.isEmpty else { return }
            guard var line = String(data: raw, encoding: .utf8) else { throw CSVLogParser.ParseError.invalidFormat }
            if line.hasSuffix("\r") { line.removeLast() }
            if header == nil {
                line = line.replacingOccurrences(of: "\u{feff}", with: "")
                let parsed = CSVLogParser.parseCSVRow(line).map { $0.trimmingCharacters(in: .whitespaces) }
                guard let ti = parsed.firstIndex(where: { $0.lowercased().contains("time") || $0.lowercased().contains("offset") }) else { throw CSVLogParser.ParseError.noTimestampChannel }
                header = parsed; timestampIndex = ti; channels.formUnion(parsed); return
            }
            diagnostics.totalRows += 1
            if line.trimmingCharacters(in: .whitespaces).isEmpty { diagnostics.blankRows += 1; return }
            guard let names = header, let ti = timestampIndex else { return }
            let values = CSVLogParser.parseCSVRow(line).map { $0.trimmingCharacters(in: .whitespaces) }
            guard values.count == names.count else { diagnostics.malformedRows += 1; return }
            guard let timestamp = TimeInterval(values[ti]) else { diagnostics.invalidTimestampRows += 1; return }
            if let previousTimestamp {
                if timestamp == previousTimestamp { diagnostics.duplicateTimestampRows += 1 }
                if timestamp < previousTimestamp { diagnostics.nonMonotonicTimestampRows += 1 }
            }
            previousTimestamp = timestamp
            var sample: [String: Any] = [:]
            for (index, name) in names.enumerated() {
                if let value = Double(values[index]) { sample[name] = value } else { sample[name] = values[index] }
            }
            timestamps.append(timestamp); samples.append(sample); diagnostics.acceptedRows += 1
        }

        func nextRecordEnd(in data: Data) -> Data.Index? {
            var insideQuotes = false
            var index = data.startIndex
            while index < data.endIndex {
                let byte = data[index]
                if byte == 0x22 { // quote
                    let next = data.index(after: index)
                    if insideQuotes, next < data.endIndex, data[next] == 0x22 {
                        index = data.index(after: next)
                        continue
                    }
                    insideQuotes.toggle()
                } else if byte == 0x0A, !insideQuotes {
                    return index
                }
                index = data.index(after: index)
            }
            return nil
        }

        while true {
            if isCancelled() { throw CancellationError() }
            let chunk = try handle.read(upToCount: chunkSize) ?? Data()
            if chunk.isEmpty { break }
            bytesRead += Double(chunk.count); buffer.append(chunk)
            while let newline = nextRecordEnd(in: buffer) {
                let line = buffer[..<newline]; try consume(Data(line)); buffer.removeSubrange(...newline)
            }
            if fileSize > 0 { progress?(min(1, bytesRead / fileSize)) }
        }
        try consume(buffer)
        guard header != nil else { throw CSVLogParser.ParseError.emptyFile }
        let dataset = ParsedLogData(filename: fileURL.lastPathComponent, fileURL: fileURL,
                                    channels: Array(channels).sorted(), timestamps: timestamps,
                                    samples: samples, duration: timestamps.last ?? 0, sampleCount: samples.count)
        progress?(1)
        return .init(dataset: dataset, diagnostics: diagnostics)
    }
}
