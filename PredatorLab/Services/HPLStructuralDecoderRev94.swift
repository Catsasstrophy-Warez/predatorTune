// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.
//
// Ported from a Rev96 "Convergence Hardening" bundle and, unlike most of that lineage,
// independently verified against this project's own real HP Tuners .hpl files before being
// merged (the original bundle only ever exercised this against a synthetic fixture — see
// Rev94StructuralDecoderTests.swift). Verification performed outside the Swift test suite,
// with a standalone Python port of `observedChunks`, against
// log-000000-20260911-225621-redacted.hpl (113 chunks found) and
// log-000002-20260911-235344-redacted.hpl (126 chunks found): both real files
// contain a repeating 0x53 0x59 0x4E 0x43 ("SYNC") marker roughly every ~13,000 bytes, each
// followed by a 6-byte little-endian counter and a 4-byte ASCII tag. The counter is
// genuinely monotonic with a near-constant ~100,000-unit delta between consecutive "CDG"
// chunks (jitter within ~100,000-100,123). The unit and semantic meaning of that opaque
// counter are NOT established. Similarity to an acquisition cadence is only a candidate
// relationship until independently verified. The repeatable marker/counter structure itself
// is real artifact-specific evidence.
import Foundation

struct HPLObservedChunkRev94: Equatable, Sendable {
    let fileOffset: Int
    let opaqueCounter: UInt64
    let tag: String
    let declaredDecodedLength: Int?
}

enum HPLStructuralDecoderRev94 {
    static func observedChunks(in data: Data) -> [HPLObservedChunkRev94] {
        let bytes = [UInt8](data)
        guard bytes.count >= 22 else { return [] }
        var result: [HPLObservedChunkRev94] = []
        var i = 0
        while i + 22 <= bytes.count {
            if bytes[i] == 0x53, bytes[i+1] == 0x59, bytes[i+2] == 0x4E, bytes[i+3] == 0x43 {
                var counter: UInt64 = 0
                for n in 0..<6 { counter |= UInt64(bytes[i+4+n]) << UInt64(8*n) }
                let tagBytes = bytes[(i+10)..<(i+14)]
                let tag = String(bytes: tagBytes, encoding: .ascii) ?? "opaque"
                let decoded: Int? = tagBytes.elementsEqual([0x43,0x44,0x47,0x00])
                    ? Int(UInt32(bytes[i+18]) | UInt32(bytes[i+19])<<8 | UInt32(bytes[i+20])<<16 | UInt32(bytes[i+21])<<24)
                    : nil
                result.append(.init(fileOffset: i, opaqueCounter: counter, tag: tag, declaredDecodedLength: decoded))
                i += 4
            } else { i += 1 }
        }
        return result
    }

    /// This is deliberately conservative: a repeating byte-level chunk marker with a
    /// monotonic counter is real structural evidence about THIS artifact, but it is not a
    /// documented HP Tuners format specification. Do not treat `tag`/`declaredDecodedLength`
    /// as verified channel identity or units without further independent cross-referencing
    /// (the way HPTunerLoggingProfile.swift's entries were cross-referenced against a real
    /// CSV export before being treated as verified names).
    static let evidenceBoundary = "Structural observations are artifact-specific. This decoder does not assign universal HPL semantics, channel identity, timestamp units, or MPVI4 protocol meaning."
}
