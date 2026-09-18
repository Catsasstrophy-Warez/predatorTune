import Foundation

enum TuneArtifactKind: String, Codable, CaseIterable {
    case hptCalibration = "HPT calibration/read"
    case hplLog = "HPL vehicle log"
    case scannerXML = "VCM Scanner XML"
    case trackCSV = "TrackAddict CSV"
    case trackVideo = "TrackAddict video"
    case trackTAD = "TrackAddict TAD"
    case trackNotes = "TrackAddict notes"
    case dynoExport = "Dyno export"
    case unknown = "Unknown"
}

struct TuneArtifactDescriptor: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: TuneArtifactKind
    let fileName: String
    let byteCount: Int64?
    let sha256: String?
    let nativeSessionID: String?
    let observedAt: Date?
    let immutableOriginal: Bool
}

struct ReconstructedTuneExperiment: Identifiable, Codable, Equatable {
    let id: UUID
    let artifacts: [TuneArtifactDescriptor]
    let trackSessionID: String?
    let hasCoreTriangle: Bool
    let warnings: [String]
    let confidence: Double
    let boundary: String
}

enum TuneArtifactClassifier {
    static func classify(fileName: String) -> TuneArtifactKind {
        let lower = fileName.lowercased()
        if lower.hasSuffix(".hpt") { return .hptCalibration }
        if lower.hasSuffix(".hpl") { return .hplLog }
        if lower.hasSuffix(".xml") { return .scannerXML }
        if lower.hasSuffix(".tad") { return .trackTAD }
        if lower.hasSuffix(".txt"), trackSessionID(fileName: fileName) != nil { return .trackNotes }
        if lower.hasSuffix(".mov") || lower.hasSuffix(".mp4") { return .trackVideo }
        if lower.hasSuffix(".csv"), trackSessionID(fileName: fileName) != nil { return .trackCSV }
        if lower.hasSuffix(".csv") { return .dynoExport }
        return .unknown
    }

    static func trackSessionID(fileName: String) -> String? {
        let base = (fileName as NSString).deletingPathExtension
        guard base.range(of: #"^Log-\d{8}-\d{6}$"#, options: .regularExpression) != nil else { return nil }
        return base
    }
}

enum TuneExperimentReconstructionEngine {
    static let boundary = "Filename pairing can establish a native TrackAddict session family, but filenames alone never establish calibration ancestry, vehicle identity, controller identity, or causal effect."

    static func reconstruct(_ artifacts: [TuneArtifactDescriptor]) -> ReconstructedTuneExperiment {
        let kinds = Set(artifacts.map(\.kind))
        let sessions = Set(artifacts.compactMap(\.nativeSessionID))
        var warnings: [String] = []
        if !kinds.contains(.hptCalibration) { warnings.append("No HPT calibration/read artifact is attached.") }
        if !kinds.contains(.hplLog) { warnings.append("No HPL vehicle log is attached.") }
        if !kinds.contains(.scannerXML) { warnings.append("No VCM Scanner XML configuration is attached.") }
        if sessions.count > 1 { warnings.append("Multiple TrackAddict native session IDs are present; do not merge them automatically.") }
        if kinds.contains(.trackVideo) != kinds.contains(.trackCSV) { warnings.append("TrackAddict video/data pair is incomplete.") }
        let core = kinds.contains(.hptCalibration) && kinds.contains(.hplLog) && kinds.contains(.scannerXML)
        let trackID = sessions.count == 1 ? sessions.first : nil
        var confidence = core ? 0.72 : 0.35
        if trackID != nil && kinds.contains(.trackCSV) && kinds.contains(.trackVideo) { confidence += 0.12 }
        if artifacts.allSatisfy(\.immutableOriginal) { confidence += 0.06 }
        confidence = min(confidence, 0.90) // identity/flash/build evidence is intentionally required for stronger confidence.
        return .init(id: UUID(), artifacts: artifacts, trackSessionID: trackID, hasCoreTriangle: core, warnings: warnings, confidence: confidence, boundary: boundary)
    }
}

struct ScannerChannelDefinition: Identifiable, Codable, Equatable {
    let id: String
    let source: String?
    let pollingInterval: Double?
    let transform: String?
    let rawAttributes: [String:String]
}

struct ScannerConfigurationFingerprint: Codable, Equatable {
    let channels: [ScannerChannelDefinition]
    let fallbackDefinitionPresent: Bool
    let overrideDefinitionPresent: Bool
    let warnings: [String]
}

final class ScannerXMLParser: NSObject, XMLParserDelegate {
    private var channels: [ScannerChannelDefinition] = []
    private var warnings: [String] = []
    private var fallback = false
    private var override = false

    static func parse(data: Data) -> ScannerConfigurationFingerprint {
        let delegate = ScannerXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        if !parser.parse() { delegate.warnings.append("XML could not be fully parsed; retain the original file and do not infer missing channel semantics.") }
        if delegate.channels.isEmpty { delegate.warnings.append("No channel identities were recognized. HP Tuners XML schema can vary; this parser intentionally refuses positional guesses.") }
        return .init(channels: delegate.channels, fallbackDefinitionPresent: delegate.fallback, overrideDefinitionPresent: delegate.override, warnings: delegate.warnings)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let normalized = elementName.lowercased()
        if normalized.contains("fallback") { fallback = true }
        if normalized.contains("override") { override = true }
        let lowered = Dictionary(uniqueKeysWithValues: attributeDict.map { ($0.key.lowercased(), $0.value) })
        let pid = lowered["parameterid"] ?? lowered["parameter_id"] ?? lowered["id"]
        let source = lowered["parametersource"] ?? lowered["source"]
        let intervalText = lowered["pollinginterval"] ?? lowered["pollinterval"] ?? lowered["interval"]
        let transform = lowered["transform"] ?? lowered["transformname"]
        if let pid, !pid.isEmpty, (normalized.contains("channel") || lowered["parametersource"] != nil || lowered["pollinginterval"] != nil) {
            channels.append(.init(id: pid, source: source, pollingInterval: intervalText.flatMap(Double.init), transform: transform, rawAttributes: attributeDict))
        }
    }
}

enum ScannerAcquisitionType: String, Codable { case polled, broadcast, external, unknown }
struct LoggingBudgetChannel: Identifiable, Codable, Equatable {
    let id: String
    let acquisitionType: ScannerAcquisitionType
    let pollingInterval: Double?
    let experimentPriority: Int
}
struct LoggingBudgetAssessment: Codable, Equatable {
    let polledCount: Int
    let broadcastCount: Int
    let externalCount: Int
    let lowPriorityPolledIDs: [String]
    let warnings: [String]
}

enum LoggingBudgetOptimizer {
    static func assess(_ channels: [LoggingBudgetChannel]) -> LoggingBudgetAssessment {
        let polled = channels.filter { $0.acquisitionType == .polled }
        let low = polled.filter { $0.experimentPriority <= 2 }.map(\.id)
        var warnings: [String] = []
        if !low.isEmpty { warnings.append("Low-priority polled channels are candidates for removal or slower polling; validate the experiment before changing acquisition settings.") }
        return .init(polledCount: polled.count, broadcastCount: channels.filter{$0.acquisitionType == .broadcast}.count, externalCount: channels.filter{$0.acquisitionType == .external}.count, lowPriorityPolledIDs: low, warnings: warnings)
    }
}

struct TrackAddictSessionDescriptor: Identifiable, Codable, Equatable {
    let id: String
    let dataFiles: [String]
    let videoFiles: [String]
    let noteFiles: [String]
    let tadFiles: [String]
    let preSynchronizedPairPresent: Bool
    let warnings: [String]
}

enum TrackAddictSessionIngestor {
    static func group(fileNames: [String]) -> [TrackAddictSessionDescriptor] {
        let grouped = Dictionary(grouping: fileNames.compactMap { name -> (String,String)? in
            guard let session = TuneArtifactClassifier.trackSessionID(fileName: name) else { return nil }
            return (session,name)
        }, by: { $0.0 })
        return grouped.keys.sorted().map { session in
            let names = grouped[session, default: []].map(\.1)
            let data = names.filter { $0.lowercased().hasSuffix(".csv") }
            let video = names.filter { $0.lowercased().hasSuffix(".mov") || $0.lowercased().hasSuffix(".mp4") }
            let notes = names.filter { $0.lowercased().hasSuffix(".txt") }
            let tad = names.filter { $0.lowercased().hasSuffix(".tad") }
            var warnings:[String] = []
            if data.isEmpty { warnings.append("No TrackAddict CSV is present.") }
            if video.isEmpty { warnings.append("No TrackAddict video is present.") }
            return .init(id: session, dataFiles: data, videoFiles: video, noteFiles: notes, tadFiles: tad, preSynchronizedPairPresent: !data.isEmpty && !video.isEmpty, warnings: warnings)
        }
    }
}

struct TimebaseAnchor: Codable, Equatable { let sourceTime: Double; let referenceTime: Double }
struct TimebaseAlignment: Codable, Equatable { let offset: Double; let drift: Double; let residualRMS: Double; let quality: Double }
enum TimebaseAlignmentEngine {
    static func align(anchors: [TimebaseAnchor]) -> TimebaseAlignment? {
        guard anchors.count >= 2 else { return nil }
        let n = Double(anchors.count)
        let sx = anchors.reduce(0) {$0 + $1.sourceTime}; let sy = anchors.reduce(0) {$0 + $1.referenceTime}
        let sxx = anchors.reduce(0) {$0 + $1.sourceTime*$1.sourceTime}; let sxy = anchors.reduce(0) {$0 + $1.sourceTime*$1.referenceTime}
        let denom = n*sxx - sx*sx; guard abs(denom) > 1e-12 else { return nil }
        let slope = (n*sxy - sx*sy)/denom; let intercept = (sy - slope*sx)/n
        let residuals = anchors.map { $0.referenceTime - (intercept + slope*$0.sourceTime) }
        let rms = sqrt(residuals.reduce(0){$0+$1*$1}/n)
        let quality = max(0, min(1, 1 - rms/0.250))
        return .init(offset: intercept, drift: slope - 1, residualRMS: rms, quality: quality)
    }
}

// MARK: - Rev59 real artifact ingestion and experiment compliance
struct TuneImportedArtifact: Identifiable, Codable, Equatable {
    let id: UUID
    let descriptor: TuneArtifactDescriptor
    let originalURLBookmarkHint: String?
    let importedAt: Date
}

enum TuneArtifactImportError: Error { case unreadableFile }

enum TuneArtifactImportService {
    static func inspect(url: URL) throws -> TuneImportedArtifact {
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = (attrs[.size] as? NSNumber)?.int64Value
        let modified = attrs[.modificationDate] as? Date
        let descriptor = TuneArtifactDescriptor(id: UUID(), kind: TuneArtifactClassifier.classify(fileName: url.lastPathComponent), fileName: url.lastPathComponent, byteCount: bytes, sha256: try EvidenceIntegrity.sha256(of: url), nativeSessionID: TuneArtifactClassifier.trackSessionID(fileName: url.lastPathComponent), observedAt: modified, immutableOriginal: true)
        return .init(id: descriptor.id, descriptor: descriptor, originalURLBookmarkHint: url.lastPathComponent, importedAt: .now)
    }
}

struct TuneExperimentContractCompliance: Codable, Equatable {
    let scannerConfigurationMatched: Bool
    let calibrationMatched: Bool
    let buildMatched: Bool
    let presentRequiredParameterIDs: [String]
    let missingRequiredParameterIDs: [String]
    let acquisitionQualityPassed: Bool
    let operatingEnvelopeEvidenceComplete: Bool
    let warnings: [String]
    var passed: Bool { scannerConfigurationMatched && calibrationMatched && buildMatched && missingRequiredParameterIDs.isEmpty && acquisitionQualityPassed && operatingEnvelopeEvidenceComplete }
}

enum TuneExperimentContractComplianceEngine {
    static func evaluate(contract: TuneLogContract, actualScannerName: String?, actualCalibrationID: UUID?, actualBuildID: UUID?, observedParameterIDs: Set<String>, acquisitionQuality: Double?, operatingEnvelopeEvidenceComplete: Bool) -> TuneExperimentContractCompliance {
        let required = Set(contract.requiredParameterIDs)
        let present = required.intersection(observedParameterIDs).sorted()
        let missing = required.subtracting(observedParameterIDs).sorted()
        let scannerMatch = actualScannerName == contract.scannerConfigurationName
        let calibrationMatch = contract.calibrationFingerprintID == nil || contract.calibrationFingerprintID == actualCalibrationID
        let buildMatch = contract.buildRevisionID == nil || contract.buildRevisionID == actualBuildID
        let qualityPass = (acquisitionQuality ?? 0) >= contract.minimumQuality
        var warnings:[String] = []
        if !scannerMatch { warnings.append("The returned log does not identify the Scanner configuration required by the contract.") }
        if !calibrationMatch { warnings.append("Calibration fingerprint does not match the experiment contract.") }
        if !buildMatch { warnings.append("Vehicle build revision does not match the experiment contract.") }
        if !missing.isEmpty { warnings.append("Required channels are missing; do not treat this experiment as contract-complete.") }
        if !qualityPass { warnings.append("Acquisition quality is below the contract threshold.") }
        if !operatingEnvelopeEvidenceComplete { warnings.append("The required operating envelope was not demonstrated by the available evidence.") }
        return .init(scannerConfigurationMatched: scannerMatch, calibrationMatched: calibrationMatch, buildMatched: buildMatch, presentRequiredParameterIDs: present, missingRequiredParameterIDs: missing, acquisitionQualityPassed: qualityPass, operatingEnvelopeEvidenceComplete: operatingEnvelopeEvidenceComplete, warnings: warnings)
    }
}

struct TrackAddictColumnMap: Codable, Equatable {
    let timestamp: String?
    let latitude: String?
    let longitude: String?
    let speed: String?
    let rpm: String?
    let throttle: String?
    let lateralG: String?
    let longitudinalG: String?
    let unknownHeaders: [String]
}

enum TrackAddictCSVSemanticDiscovery {
    static func discover(headers: [String]) -> TrackAddictColumnMap {
        func pick(_ tokens:[String]) -> String? { headers.first { h in tokens.contains { h.lowercased().contains($0) } } }
        let known = [pick(["time","timestamp"]),pick(["latitude","lat"]),pick(["longitude","lon","lng"]),pick(["speed","mph","kph"]),pick(["rpm"]),pick(["throttle","tps"]),pick(["lateral","lat g"]),pick(["longitudinal","long g"])].compactMap{$0}
        return .init(timestamp:pick(["time","timestamp"]), latitude:pick(["latitude","lat"]), longitude:pick(["longitude","lon","lng"]), speed:pick(["speed","mph","kph"]), rpm:pick(["rpm"]), throttle:pick(["throttle","tps"]), lateralG:pick(["lateral","lat g"]), longitudinalG:pick(["longitudinal","long g"]), unknownHeaders:headers.filter{!known.contains($0)})
    }
}
