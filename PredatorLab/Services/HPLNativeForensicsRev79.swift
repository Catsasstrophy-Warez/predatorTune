import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

enum HPLFieldAuthorityRev79: String, Codable { case observedBytes, crossArtifactVerified, officialDocumentation, reverseEngineeringHypothesis, unknown }

struct HPLNativeHeaderFindingRev79: Identifiable, Codable, Hashable {
    let id: String; let offset: Int; let rawHex: String; let interpretation: String; let authority: HPLFieldAuthorityRev79
}

struct HPLChannelDescriptorCandidateRev79: Identifiable, Codable, Hashable {
    let id: String; let byteOffset: Int; let label: String; let unitToken: String?; let xmlParameterID: Int?; let xmlInterval: String?; let csvColumn: Int?; let status: String
}

struct HPLNativeForensicReportRev79: Codable, Hashable {
    let fileName: String; let byteCount: Int; let headerFindings: [HPLNativeHeaderFindingRev79]; let descriptors: [HPLChannelDescriptorCandidateRev79]; let warnings: [String]
}

enum HPLNativeProbeRev79 {
    static func probe(fileName: String, bytes: Data, xmlBindings: [String:(Int,String)] = [:], csvHeaders: [String] = []) -> HPLNativeForensicReportRev79 {
        let a = [UInt8](bytes)
        func hex(_ r: Range<Int>) -> String { r.compactMap { $0 < a.count ? String(format:"%02X", a[$0]) : nil }.joined(separator:" ") }
        var findings:[HPLNativeHeaderFindingRev79] = []
        if a.count >= 8 {
            let prefix = String(bytes:a[0..<min(8,a.count)], encoding:.ascii) ?? "non-ASCII"
            findings.append(.init(id:"prefix", offset:0, rawHex:hex(0..<min(16,a.count)), interpretation:"Observed native prefix: \(prefix.debugDescription). This does not satisfy the supplied legacy parser's HPT gate.", authority:.observedBytes))
        }
        var descriptors:[HPLChannelDescriptorCandidateRev79] = []
        var i = 0
        while i < min(a.count, 16_384) {
            if a[i] >= 0x20 && a[i] <= 0x7E {
                let start=i; var j=i
                while j<a.count && j<16_384 && a[j]>=0x20 && a[j]<=0x7E { j += 1 }
                if j-start >= 8, let s=String(bytes:a[start..<j],encoding:.ascii), s.contains(" ") {
                    let xml=xmlBindings[s]; let csv=csvHeaders.firstIndex(of:s)
                    descriptors.append(.init(id:"\(start)-\(s)", byteOffset:start, label:s, unitToken:nil, xmlParameterID:xml?.0, xmlInterval:xml?.1, csvColumn:csv, status:(xml != nil || csv != nil) ? "cross-artifact candidate" : "native plaintext candidate"))
                }
                i=j
            } else { i += 1 }
        }
        return .init(fileName:fileName, byteCount:a.count, headerFindings:findings, descriptors:descriptors, warnings:[
            "Do not apply the supplied legacy HPT/AES/DEFLATE offsets to this generation until independently validated.",
            "Plaintext channel labels are observed structure, not proof of the remaining binary schema.",
            "Do not decrypt or expose VIN/identity material; it is unnecessary for diagnostic evidence admission.",
            "All inferred type/unit/timestamp mappings require XML/CSV or other independent validation."
        ])
    }
}

struct HPLTimestampHypothesisRev79: Codable, Hashable { let name:String; let unit:String; let epoch:String?; let status:String }
enum HPLTimestampLabRev79 {
    static let candidates:[HPLTimestampHypothesisRev79] = [
        .init(name:"Session-relative",unit:"unknown ticks",epoch:nil,status:"test against CSV Offset"),
        .init(name:"Unix seconds",unit:"s",epoch:"1970-01-01",status:"candidate"),
        .init(name:"Unix milliseconds",unit:"ms",epoch:"1970-01-01",status:"candidate"),
        .init(name:"Unix microseconds",unit:"µs",epoch:"1970-01-01",status:"candidate"),
        .init(name:"Windows FILETIME",unit:"100 ns",epoch:"1601-01-01",status:"candidate"),
        .init(name:".NET ticks",unit:"100 ns",epoch:"0001-01-01",status:"candidate")]
}

struct HPLCrossArtifactScoreRev79: Codable, Hashable {
    let labelMatch:Double; let intervalMatch:Double; let timingCorrelation:Double; let valueCorrelation:Double; let unitAgreement:Double; let missingnessAgreement:Double
    var admissible: Bool { min(labelMatch, intervalMatch, timingCorrelation, valueCorrelation, unitAgreement) >= 0.95 }
}

struct VCMSuiteEvidenceRuleRev79: Identifiable, Codable, Hashable { let id:String; let area:String; let documentedFact:String; let predatorRule:String }
enum VCMSuiteEvidenceAtlasRev79 {
    static let rules:[VCMSuiteEvidenceRuleRev79] = [
        .init(id:"format52",area:"VCM Scanner 5.2",documentedFact:"HP Tuners documents a new log file format with improved performance/reduced size and MPVI4 support.",predatorRule:"Version decoder assumptions; never assume a legacy HPL layout applies to current logs."),
        .init(id:"xml",area:"Channel Config",documentedFact:"Saved XML includes Parameter ID, Parameter Source, Polling Interval and applied Transform.",predatorRule:"Use XML as one leg of HPL↔XML↔CSV certification, not as physical-semantic authority by itself."),
        .init(id:"poll",area:"Acquisition",documentedFact:"Polled channels add processing load; broadcast channels and external inputs do not impose the same vehicle polling cost.",predatorRule:"Benchmark exact contracts; never promise universal Hz improvements."),
        .init(id:"defs",area:"Definitions",documentedFact:"Fallback/Override properties influence definition loading and overrides can reduce portability/capability.",predatorRule:"Persist definition override state with every certified acquisition contract."),
        .init(id:"transform",area:"External Inputs",documentedFact:"User transforms persist with channel configs and can map 0–5 V inputs using source-backed calibration points.",predatorRule:"Retain raw voltage plus device, ground/reference, points, equation and transformed value."),
        .init(id:"standalone",area:"MPVI4 Standalone",documentedFact:"MPVI4 supports uploaded vehicle-specific/default channel lists plus start/stop triggers and internal logging.",predatorRule:"Fingerprint deployment config and trigger state; abrupt unplug may lose data."),
        .init(id:"telemetry",area:"VCM Telemetry",documentedFact:"Completed standalone sessions can upload over Wi-Fi/hotspot for browser review/compare/share.",predatorRule:"Cloud transport lineage never upgrades semantic authority."),
        .init(id:"navigator",area:"VCM Editor",documentedFact:"Parameter Navigator filters by name, type, group and Basic/Advanced.",predatorRule:"Capture controller/OS/VCM-version-specific inventories rather than assuming parameter universality."),
        .init(id:"templates",area:"Tune Templates",documentedFact:"Templates can import selected parameters, unsaved changes and compare-file differences.",predatorRule:"Bind template/diff artifacts to controlled experiments and calibration ancestry."),
        .init(id:"udp",area:"User Defined Parameters",documentedFact:"XDF-defined switches/scalars/tables can specify addresses, storage, byte order, units, equations and axes where supported by controller OS.",predatorRule:"Label XDF/UDP separately from HP Tuners-native and OEM-authoritative definitions.")]
}
