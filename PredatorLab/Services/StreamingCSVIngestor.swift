import Foundation

struct CSVIngestionDiagnostics: Codable, Equatable, Sendable {
    var totalRows = 0
    var acceptedRows = 0
    var blankRows = 0
    var malformedRows = 0
    var invalidTimestampRows = 0
    var duplicateTimestampRows = 0
    var nonMonotonicTimestampRows = 0
    var preambleLines = 0
    var unitsRowFound = false
    var latin1Fallback = false
}

struct CSVIngestionResult: Sendable {
    var dataset: ParsedLogData
    var diagnostics: CSVIngestionDiagnostics
}

/// Streaming ingestion for scanner CSVs. It does not alter the original file.
/// Records are RFC-4180 aware, so quoted fields may contain commas and embedded newlines.
///
/// Accepts both a plain CSV whose first record is the header, and the HP Tuners export
/// layout:
///
///     HP Tuners CSV Log File / Version / [Log Information] … / [Channel Information]
///     <channel id row> / <channel name row> / <units row> / [Channel Data] / <data rows>
enum StreamingCSVIngestor {
    /// Lines scanned for a header before giving up, so a non-log file fails fast.
    private static let maximumPreambleLines = 64
    private static let timestampNames: Set<String> = ["offset", "time", "timestamp", "time (s)", "elapsed time"]

    private enum Stage { case seekingHeader, expectingUnits, data }

    static func parse(fileURL: URL, chunkSize: Int = 256 * 1024,
                      isCancelled: () -> Bool = { false },
                      progress: ((Double) -> Void)? = nil) throws -> CSVIngestionResult {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.doubleValue ?? 0
        var buffer = Data(); var bytesRead: Double = 0
        var stage = Stage.seekingHeader
        var header: [String] = []; var timestampIndex = 0; var units: [String: String] = [:]
        var sawChannelInformation = false
        var timestamps: [TimeInterval] = []; var samples: [[String: Any]] = []
        var diagnostics = CSVIngestionDiagnostics(); var previousTimestamp: TimeInterval?

        func decode(_ raw: Data) -> String? {
            if let utf8 = String(data: raw, encoding: .utf8) { return utf8 }
            diagnostics.latin1Fallback = true
            return String(data: raw, encoding: .isoLatin1)
        }

        func isSectionMarker(_ line: String) -> Bool {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("[") && trimmed.hasSuffix("]")
        }

        func appendSample(_ values: [String]) {
            guard let timestamp = TimeInterval(values[timestampIndex]) else { diagnostics.invalidTimestampRows += 1; return }
            if let previousTimestamp {
                if timestamp == previousTimestamp { diagnostics.duplicateTimestampRows += 1 }
                if timestamp < previousTimestamp { diagnostics.nonMonotonicTimestampRows += 1 }
            }
            previousTimestamp = timestamp
            var sample: [String: Any] = [:]
            sample.reserveCapacity(header.count)
            for (index, name) in header.enumerated() {
                if let value = Double(values[index]) { sample[name] = value } else { sample[name] = values[index] }
            }
            timestamps.append(timestamp); samples.append(sample); diagnostics.acceptedRows += 1
        }

        func consumeData(_ line: String, fields: [String]) throws {
            diagnostics.totalRows += 1
            if line.trimmingCharacters(in: .whitespaces).isEmpty { diagnostics.blankRows += 1; return }
            guard fields.count == header.count else { diagnostics.malformedRows += 1; return }
            appendSample(fields)
        }

        func consume(_ raw: Data) throws {
            guard !raw.isEmpty else { return }
            guard var line = decode(raw) else { throw CSVLogParser.ParseError.invalidFormat }
            if line.hasSuffix("\r") { line.removeLast() }

            switch stage {
            case .seekingHeader:
                line = line.replacingOccurrences(of: "\u{feff}", with: "")
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                diagnostics.preambleLines += 1
                guard diagnostics.preambleLines <= maximumPreambleLines else { throw CSVLogParser.ParseError.noTimestampChannel }
                if trimmed.isEmpty { return }
                if isSectionMarker(trimmed) {
                    if trimmed.lowercased() == "[channel information]" { sawChannelInformation = true }
                    return
                }
                let fields = CSVLogParser.parseCSVRow(line).map { $0.trimmingCharacters(in: .whitespaces) }
                // Preamble lines ("Version: 1.0", "Creation Time: …") are single fields; HP Tuners'
                // channel-ID row is all integers. Neither is a header.
                guard fields.count >= 2 else { return }
                if sawChannelInformation, fields.allSatisfy({ Int($0) != nil }) { return }
                guard let index = timestampColumn(in: fields) else {
                    if sawChannelInformation { throw CSVLogParser.ParseError.noTimestampChannel }
                    return
                }
                header = uniqued(fields)
                timestampIndex = index
                stage = .expectingUnits
                diagnostics.preambleLines -= 1

            case .expectingUnits:
                if isSectionMarker(line) { stage = .data; return }
                if line.trimmingCharacters(in: .whitespaces).isEmpty { return }
                let fields = CSVLogParser.parseCSVRow(line).map { $0.trimmingCharacters(in: .whitespaces) }
                stage = .data
                if fields.count == header.count, TimeInterval(fields[timestampIndex]) == nil {
                    // Units row: the timestamp column holds a unit such as "s", not a number.
                    diagnostics.unitsRowFound = true
                    for (name, unit) in zip(header, fields) where !unit.isEmpty { units[name] = unit }
                    return
                }
                try consumeData(line, fields: fields)

            case .data:
                if isSectionMarker(line) { return }
                let fields = CSVLogParser.parseCSVRow(line).map { $0.trimmingCharacters(in: .whitespaces) }
                try consumeData(line, fields: fields)
            }
        }

        func nextRecordEnd(in data: Data, from start: Data.Index) -> Data.Index? {
            var insideQuotes = false
            var index = start
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
            // Walk records with a cursor and trim the consumed prefix once per chunk,
            // instead of copying the remaining buffer after every line.
            var cursor = buffer.startIndex
            while let newline = nextRecordEnd(in: buffer, from: cursor) {
                try consume(Data(buffer[cursor..<newline]))
                cursor = buffer.index(after: newline)
            }
            buffer.removeSubrange(buffer.startIndex..<cursor)
            if fileSize > 0 { progress?(min(1, bytesRead / fileSize)) }
        }
        try consume(buffer)
        guard !header.isEmpty else {
            throw diagnostics.preambleLines == 0 ? CSVLogParser.ParseError.emptyFile : CSVLogParser.ParseError.noTimestampChannel
        }
        let duration = max(0, (timestamps.last ?? 0) - (timestamps.first ?? 0))
        let dataset = ParsedLogData(filename: fileURL.lastPathComponent, fileURL: fileURL,
                                    channels: header.sorted(), timestamps: timestamps,
                                    samples: samples, duration: duration, sampleCount: samples.count,
                                    units: units)
        progress?(1)
        return .init(dataset: dataset, diagnostics: diagnostics)
    }

    /// Prefers an exact timestamp column name, then a column starting with "time".
    private static func timestampColumn(in fields: [String]) -> Int? {
        let lowered = fields.map { $0.lowercased() }
        if let exact = lowered.firstIndex(where: { timestampNames.contains($0) }) { return exact }
        if let prefixed = lowered.firstIndex(where: { $0.hasPrefix("time") || $0.hasPrefix("offset") }) { return prefixed }
        return nil
    }

    /// Keeps duplicate column names distinct ("Intake Air Temp", "Intake Air Temp #2").
    private static func uniqued(_ fields: [String]) -> [String] {
        var seen: [String: Int] = [:]
        return fields.map { name in
            let count = (seen[name] ?? 0) + 1
            seen[name] = count
            return count == 1 ? name : "\(name) #\(count)"
        }
    }
}
