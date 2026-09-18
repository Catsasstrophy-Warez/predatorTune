import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Native bounded HPL experiment. This deliberately does NOT claim a universal HPL schema.
/// It ports the Rev81 probe's observable operations so Swift and Python can be differential oracles.
enum HPLNativeScalarEncodingRev85: String, Codable, CaseIterable { case float32LE, float64LE, uint16LE, uint32LE }
struct HPLPrintableDescriptorRev85: Codable, Equatable { let offset: Int; let text: String }
struct HPLDirectValueHitRev85: Codable, Equatable { let sample: Double; let encoding: HPLNativeScalarEncodingRev85; let offset: Int }
struct HPLNativeProbeResultRev85: Codable, Equatable { let byteCount:Int; let prefixHex:String; let descriptors:[HPLPrintableDescriptorRev85]; let directValueHits:[HPLDirectValueHitRev85]; let boundary:String }

enum HPLNativeWaveformDecoderRev85 {
    static func probe(data: Data, referenceValues: [Double], descriptorLimit: Int = 32_768, minimumDescriptorLength: Int = 8) -> HPLNativeProbeResultRev85 {
        let bytes = [UInt8](data)
        let descriptors = printableDescriptors(bytes, limit: descriptorLimit, minimumLength: minimumDescriptorLength)
        var hits: [HPLDirectValueHitRev85] = []
        for value in referenceValues {
            let patterns: [(HPLNativeScalarEncodingRev85, [UInt8])] = [
                (.float32LE, bytesOf(Float(value).bitPattern, count: 4)),
                (.float64LE, bytesOf(value.bitPattern, count: 8)),
                (.uint16LE, bytesOf(UInt16(clamping: Int(value.rounded())), count: 2)),
                (.uint32LE, bytesOf(UInt32(clamping: Int(value.rounded())), count: 4))
            ]
            for (encoding, pattern) in patterns {
                for offset in allOffsets(of: pattern, in: bytes) { hits.append(.init(sample:value, encoding:encoding, offset:offset)) }
            }
        }
        let prefix = bytes.prefix(32).map { String(format:"%02x", $0) }.joined(separator:" ")
        return .init(byteCount:bytes.count,prefixHex:prefix,descriptors:descriptors,directValueHits:hits,boundary:"Direct isolated hits are candidates only. Admission still requires sequence, timing, XML identity and unit agreement for this artifact.")
    }

    static func printableDescriptors(_ bytes:[UInt8], limit:Int, minimumLength:Int) -> [HPLPrintableDescriptorRev85] {
        let end = min(bytes.count, max(0, limit)); var result:[HPLPrintableDescriptorRev85]=[]; var i=0
        while i < end {
            if (32...126).contains(bytes[i]) {
                let start=i; var j=i
                while j < end && (32...126).contains(bytes[j]) { j += 1 }
                if j-start >= minimumLength, let text=String(bytes:bytes[start..<j],encoding:.ascii) { result.append(.init(offset:start,text:text)) }
                i=j
            } else { i += 1 }
        }
        return result
    }

    private static func bytesOf<T: FixedWidthInteger>(_ value:T, count:Int) -> [UInt8] {
        let le=value.littleEndian
        return (0..<count).map { UInt8(truncatingIfNeeded: le >> T($0 * 8)) }
    }
    private static func allOffsets(of pattern:[UInt8], in bytes:[UInt8]) -> [Int] {
        guard !pattern.isEmpty, pattern.count <= bytes.count else { return [] }
        var out:[Int]=[]
        for i in 0...(bytes.count-pattern.count) where Array(bytes[i..<(i+pattern.count)]) == pattern { out.append(i) }
        return out
    }
}
