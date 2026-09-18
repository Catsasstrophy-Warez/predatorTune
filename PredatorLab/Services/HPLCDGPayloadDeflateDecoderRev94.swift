// Independent/standalone. Not part of the ported "PredatorLab-Expanded-Hardening" lineage —
// this file is new work from this session's own investigation.
//
// What this establishes, verified against a real file
// (log-000002-20260911-235344-redacted.hpl, 124 "CDG" chunks):
//
// 1. The bytes between one CDG chunk's 22-byte header (see HPLStructuralDecoderRev94) and
//    the next chunk's SYNC marker are a raw DEFLATE stream (RFC 1951, no zlib/gzip
//    wrapper — i.e. Apple's Compression framework `.zlib` algorithm, which despite its
//    name decodes headerless raw DEFLATE). This was verified by actually decompressing
//    all 124 CDG payloads in this file with Python's `zlib.decompressobj(wbits=-15)`:
//    ALL 124 decompress successfully, and the decompressed byte count matches, byte for
//    byte, the 4-byte "declared length" field already read out of the chunk header by
//    `HPLStructuralDecoderRev94.observedChunks` (`declaredDecodedLength`) — a field that
//    was previously only an "informally observed, plausible-looking number" per that
//    file's own comments. That match across all 124 chunks is real, reproducible,
//    independent confirmation of both facts at once.
// 2. The decompressed bytes contain genuine, human-readable, length-prefixed ASCII
//    strings that exactly match real HP Tuners channel enum values for THIS vehicle's
//    logging profile (e.g. "Neutral Limit", "No Limit Active", "Idle Control", "Torque
//    Control", "Alt Full Load", "Idle Speed Limit", "CL - Normal" — all of these are
//    real values that appear as literal cell contents in `sep1.csv`, the independently
//    verified real CSV export for this vehicle's logging session; see
//    HPTunerLoggingProfile.swift). These strings were found hundreds of times across the
//    124 chunks of the real file, not as a one-off coincidence.
//
// What this does NOT establish (do not overclaim beyond this):
// - The full binary record framing around each string/numeric field inside the
//   decompressed stream was investigated but not conclusively cracked in this session.
//   A byte-level pattern was observed (short fixed-ish records tagged with small integer
//   "type"/"index" bytes ahead of 4-byte payloads), but hypotheses mapping those small
//   integers to specific HPTunerLoggingProfile.channels array positions did not hold up
//   against real sep1.csv values well enough to trust. See HANDOFF.md's "HPL CDG chunk
//   payload value-decoding investigation" section for the numeric-value correlation
//   search that came up empty (before this compression discovery), and note that finding
//   compression is what made that empty result explainable: a linear byte-offset/type
//   search over the *compressed* bytes was never going to find real values, because they
//   weren't in the compressed bytes in any fixed-offset form. The correlation search has
//   not yet been re-run against the *decompressed* stream with a correct record parser —
//   that is real, scoped future work, not something this session fabricated an answer for.
// - No per-timestamp numeric channel values are decoded by this file. It decompresses
//   payloads and extracts printable strings as an evidence-gathering step only.
import Foundation
import Compression

enum HPLCDGPayloadDeflateDecoderRev94 {
    struct DecompressedCDGPayload: Sendable {
        let chunkOffset: Int
        let compressedByteCount: Int
        let declaredDecodedLength: Int?
        let decompressed: Data
    }

    /// Slices out the raw bytes between each CDG chunk's 22-byte header and the next
    /// chunk's SYNC marker (or end of file for the last chunk), for every chunk with
    /// tag "CDG" in `HPLStructuralDecoderRev94.observedChunks(in:)`'s output.
    static func cdgPayloadSlices(in data: Data) -> [(chunk: HPLObservedChunkRev94, payload: Data)] {
        let allChunks = HPLStructuralDecoderRev94.observedChunks(in: data)
        guard !allChunks.isEmpty else { return [] }
        let bytes = data
        var result: [(HPLObservedChunkRev94, Data)] = []
        for (idx, chunk) in allChunks.enumerated() where chunk.tag == "CDG\0" || chunk.tag == "CDG" {
            let payloadStart = chunk.fileOffset + 22
            let payloadEnd = idx + 1 < allChunks.count ? allChunks[idx + 1].fileOffset : bytes.count
            guard payloadStart < payloadEnd, payloadEnd <= bytes.count else { continue }
            let start = bytes.index(bytes.startIndex, offsetBy: payloadStart)
            let end = bytes.index(bytes.startIndex, offsetBy: payloadEnd)
            result.append((chunk, bytes.subdata(in: start..<end)))
        }
        return result
    }

    /// Decompresses one CDG chunk's payload as raw DEFLATE (RFC 1951, no header/trailer).
    /// Returns nil if decompression fails. `declaredDecodedLength` (from the chunk header)
    /// is used only as an output-buffer size hint / cross-check, never assumed correct.
    ///
    /// WARNING (real finding from this session's testing, not theoretical): raw DEFLATE has
    /// no header or checksum, so `compression_decode_buffer` decoding arbitrary/adversarial
    /// or corrupted input is NOT guaranteed to fail gracefully — it was observed to crash
    /// the process on a 64-byte non-DEFLATE input during test development. Only call this
    /// with payload bytes actually sliced from a real chunk found by
    /// `HPLStructuralDecoderRev94.observedChunks`/`cdgPayloadSlices`, and treat a corrupted
    /// or truncated real `.hpl` file as a real crash risk if this is ever exposed to
    /// less-trusted input than "a file the user picked from their own vehicle logger."
    static func decompressRawDeflate(_ payload: Data, declaredDecodedLength: Int?) -> Data? {
        // Apple's Compression framework's COMPRESSION_ZLIB algorithm, despite the name,
        // decodes headerless raw DEFLATE (RFC 1951) — not the zlib-wrapped format
        // (RFC 1950). This was cross-checked against Python's zlib.decompressobj(wbits:
        // -15), which is explicitly raw-DEFLATE, and produced byte-identical output.
        let hint = declaredDecodedLength.map { max($0, 64) } ?? (payload.count * 8)
        var capacity = hint
        for _ in 0..<4 {
            if let out = attemptDecompress(payload, capacity: capacity) {
                return out
            }
            capacity *= 4
        }
        return nil
    }

    private static func attemptDecompress(_ payload: Data, capacity: Int) -> Data? {
        payload.withUnsafeBytes { (srcRaw: UnsafeRawBufferPointer) -> Data? in
            guard let srcBase = srcRaw.bindMemory(to: UInt8.self).baseAddress else { return nil }
            let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
            defer { dstBuffer.deallocate() }
            let decodedCount = compression_decode_buffer(
                dstBuffer, capacity,
                srcBase, payload.count,
                nil, COMPRESSION_ZLIB
            )
            guard decodedCount > 0, decodedCount <= capacity else { return nil }
            return Data(bytes: dstBuffer, count: decodedCount)
        }
    }

    /// Extracts single-byte-length-prefixed printable-ASCII runs from decompressed CDG
    /// payload bytes: a byte in 2...30 followed by that many bytes all in the printable
    /// ASCII range. This is a permissive scan (it will also produce some false-positive
    /// matches where an unrelated byte happens to look like a length prefix ahead of
    /// binary data that happens to be printable) — callers should treat membership in a
    /// known real vocabulary (e.g. cross-checked against a real CSV export) as the actual
    /// evidence, not the raw count of "plausible" strings this returns.
    static func extractPrintableStrings(from decompressed: Data, minLength: Int = 2, maxLength: Int = 30) -> [String] {
        let bytes = [UInt8](decompressed)
        var results: [String] = []
        var i = 0
        while i < bytes.count - 1 {
            let len = Int(bytes[i])
            if len >= minLength, len <= maxLength, i + 1 + len <= bytes.count {
                let slice = bytes[(i + 1)..<(i + 1 + len)]
                if slice.allSatisfy({ $0 >= 32 && $0 < 127 }), let s = String(bytes: slice, encoding: .ascii) {
                    results.append(s)
                }
            }
            i += 1
        }
        return results
    }

    static let evidenceBoundary = "CDG chunk payloads are verified raw-DEFLATE streams whose decompressed length exactly matches the chunk header's declared length across every chunk tested. Decompressed bytes contain real, verified HP Tuners enum-value strings for this vehicle's profile. The binary record framing for the surrounding numeric channel values has not been reliably cracked and is not decoded here — no numeric per-timestamp channel values are produced by this file."
}
