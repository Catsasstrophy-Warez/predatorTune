// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

enum TelemetryEvidenceClass: String, Codable, CaseIterable, Sendable {
    case unknown, observed, derived, experimentallyMapped, sourceVerified
}

struct TelemetryArtifactProbe: Equatable, Sendable {
    let format: String
    let confidence: Double
    let evidenceClass: TelemetryEvidenceClass
    let notes: [String]
}

struct DecodedTelemetryChannel: Identifiable, Sendable {
    let id: String
    let name: String
    let unit: String?
    let evidenceClass: TelemetryEvidenceClass
    let samples: [ForensicTimelineSampleRev85]
    let provenance: [String]
}

struct DecodedTelemetryArtifact: Sendable {
    let format: String
    let channels: [DecodedTelemetryChannel]
    let unknownRecordCount: Int
    let evidenceBoundary: String
}

protocol TelemetryArtifactDecoder {
    var formatName: String { get }
    func probe(_ data: Data) -> TelemetryArtifactProbe
    func decode(_ data: Data) throws -> DecodedTelemetryArtifact
}

/// Production-safe structural HPL adapter. It deliberately exposes structure, not invented channel semantics.
struct HPLStructuralArtifactDecoder: TelemetryArtifactDecoder {
    let formatName = "HPL structural"
    func probe(_ data: Data) -> TelemetryArtifactProbe {
        let chunks = HPLStructuralDecoderRev94.observedChunks(in: data)
        return .init(format: formatName,
                     confidence: chunks.isEmpty ? 0 : 0.8,
                     evidenceClass: chunks.isEmpty ? .unknown : .observed,
                     notes: chunks.isEmpty ? ["No observed SYNC/CDG structure found."] :
                        ["Observed \(chunks.count) structural chunks.", HPLStructuralDecoderRev94.evidenceBoundary])
    }
    func decode(_ data: Data) throws -> DecodedTelemetryArtifact {
        let chunks = HPLStructuralDecoderRev94.observedChunks(in: data)

        // Best-effort, evidence-only enrichment: attempt raw-DEFLATE decompression of each
        // CDG chunk's payload (see HPLCDGPayloadDeflateDecoderRev94's file-level comment for
        // what this is and is not verified evidence of). This intentionally still produces
        // ZERO DecodedTelemetryChannel values — no numeric channel framing has been reliably
        // cracked — it only strengthens/weakens the structural evidence notes with real,
        // freshly-computed numbers from this specific artifact.
        let slices = HPLCDGPayloadDeflateDecoderRev94.cdgPayloadSlices(in: data)
        var decompressedOK = 0
        var lengthMatches = 0
        for (chunk, payload) in slices {
            guard let out = HPLCDGPayloadDeflateDecoderRev94.decompressRawDeflate(
                payload, declaredDecodedLength: chunk.declaredDecodedLength
            ) else { continue }
            decompressedOK += 1
            if let declared = chunk.declaredDecodedLength, declared == out.count {
                lengthMatches += 1
            }
        }

        var boundary = HPLStructuralDecoderRev94.evidenceBoundary
        if !slices.isEmpty {
            boundary += " " + HPLCDGPayloadDeflateDecoderRev94.evidenceBoundary
            boundary += " In this artifact: \(decompressedOK)/\(slices.count) CDG chunk payloads decompressed as raw DEFLATE, of which \(lengthMatches) had decompressed length exactly matching the chunk header's declared length."
        }

        return .init(format: formatName, channels: [], unknownRecordCount: chunks.count,
                     evidenceBoundary: boundary)
    }
}
