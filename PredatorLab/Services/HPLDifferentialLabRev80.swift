import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

enum HPLFieldAuthorityRev80: String, Codable { case observedBytes, crossArtifactVerified, officialDocumentation, reverseEngineeringHypothesis, unknown }
struct HPLDescriptorObservationRev80: Identifiable, Codable, Equatable { let id:String; let offset:Int; let text:String; let authority:HPLFieldAuthorityRev80 }
struct HPLFormatFingerprintRev80: Codable, Equatable { let sha256:String?; let size:Int; let prefixHex:String; let descriptorCount:Int; let sharedDescriptorCount:Int?; let notes:[String] }
struct HPLCandidateMatchRev80: Identifiable, Codable, Equatable { let id:String; let hplLabel:String; let xmlParameterID:String?; let csvLabel:String?; let labelMatched:Bool; let intervalMatched:Bool?; let valueCorrelation:Double?; let timingCorrelation:Double?; let unitsMatched:Bool?; let admitted:Bool; let blockers:[String] }

enum HPLDescriptorScannerRev80 {
    static func printableDescriptors(_ data:Data, limit:Int = 32_768) -> [HPLDescriptorObservationRev80] {
        let bytes=[UInt8](data.prefix(limit)); var out:[HPLDescriptorObservationRev80]=[]; var i=0
        while i < bytes.count {
            if bytes[i] >= 32 && bytes[i] <= 126 {
                let start=i; var j=i
                while j < bytes.count && bytes[j] >= 32 && bytes[j] <= 126 { j += 1 }
                if j-start >= 8, let s=String(bytes:bytes[start..<j],encoding:.ascii) {
                    out.append(.init(id:"\(start)-\(out.count)",offset:start,text:s,authority:.observedBytes))
                }
                i=j
            } else { i += 1 }
        }
        return out
    }
    static func sharedLabels(_ a:[HPLDescriptorObservationRev80], _ b:[HPLDescriptorObservationRev80]) -> [String] {
        let sb=Set(b.map{$0.text}); return a.map{$0.text}.filter{sb.contains($0)}
    }
}

enum HPLCrossArtifactAdmissionRev80 {
    static func assess(label:String, xmlParameterID:String?, csvLabel:String?, intervalMatched:Bool?, valueCorrelation:Double?, timingCorrelation:Double?, unitsMatched:Bool?) -> HPLCandidateMatchRev80 {
        var blockers:[String]=[]
        let lm = csvLabel?.localizedCaseInsensitiveContains(label) == true || label.localizedCaseInsensitiveContains(csvLabel ?? "")
        if !lm { blockers.append("Human-readable label is not cross-artifact matched") }
        if xmlParameterID == nil { blockers.append("Scanner XML Parameter ID is unresolved") }
        if intervalMatched != true { blockers.append("Polling/observation interval is not matched") }
        if (valueCorrelation ?? 0) < 0.995 { blockers.append("Value chronology is not strongly correlated") }
        if (timingCorrelation ?? 0) < 0.995 { blockers.append("Timestamp chronology is not strongly correlated") }
        if unitsMatched != true { blockers.append("Engineering units are unresolved") }
        return .init(id:UUID().uuidString,hplLabel:label,xmlParameterID:xmlParameterID,csvLabel:csvLabel,labelMatched:lm,intervalMatched:intervalMatched,valueCorrelation:valueCorrelation,timingCorrelation:timingCorrelation,unitsMatched:unitsMatched,admitted:blockers.isEmpty,blockers:blockers)
    }
}

struct HPLTimestampHypothesisRev80: Identifiable, Codable, Equatable { enum Kind:String,Codable,CaseIterable { case sessionRelativeTicks, unixSeconds, unixMilliseconds, unixMicroseconds, windowsFileTime, dotNetTicks, unknown }; let id:String; let kind:Kind; let scale:Double?; let offset:Double?; let verified:Bool; let evidence:String }

enum HPLTimestampLabRev80 {
    static let candidates:[HPLTimestampHypothesisRev80] = HPLTimestampHypothesisRev80.Kind.allCases.map { .init(id:$0.rawValue,kind:$0,scale:nil,offset:nil,verified:false,evidence:"Must reproduce known CSV Offset chronology and event ordering before promotion.") }
}

struct HPLBinaryExperimentProtocolRev80: Codable, Equatable {
    let phases:[String]; let safetyRules:[String]; let successCriteria:[String]
    static let native = Self(phases:[
        "Fingerprint immutable HPL, XML and CSV artifacts.",
        "Extract only observed printable descriptor strings and offsets; do not infer field widths.",
        "Locate the descriptor-to-observation transition using differential structure across multiple HPL files.",
        "Search bounded regions for candidate RPM numeric sequences in common integer and IEEE-754 encodings.",
        "Test candidate timestamp families against CSV Offset chronology.",
        "Cross-match candidate channels to Scanner XML Parameter ID/source/polling/transform.",
        "Cross-match numeric chronology to CSV and require strong value/timing agreement.",
        "Promote only artifact-set-specific semantics; retain format-version boundaries."
    ], safetyRules:[
        "Never execute data from an HPL as code.","Bound decompression and allocation sizes.","Reject truncated/overflowing structures.","Do not extract VIN/AES-protected identity for diagnostic decoding.","Do not claim proprietary HPL specification ownership or universal decoding."
    ], successCriteria:[
        "Recover Engine RPM with reproducible chronology.","Recover at least one physical quantity such as fuel pressure with XML/CSV agreement.","Reproduce the sep2 first-out event chronology from native evidence or explicitly report why it remains unresolved."
    ])
}

struct VCMSuiteEvidenceRuleRev80: Identifiable, Codable, Equatable { let id:String; let topic:String; let documentedFact:String; let predatorLabRule:String; let sourceLocator:String }
enum VCMSuiteEvidenceAtlasRev80 {
    static let rules:[VCMSuiteEvidenceRuleRev80] = [
        .init(id:"scanner52",topic:"VCM Scanner 5.2",documentedFact:"HP Tuners documents a new log file format with improved performance/reduced size and MPVI4 support.",predatorLabRule:"HPL parsing is format/version aware; a legacy reverse-engineered layout cannot be universalized.",sourceLocator:"HP Tuners Docs > VCM Scanner > Introduction > 5.2"),
        .init(id:"channels",topic:"Channel configuration",documentedFact:"Saved XML includes Parameter ID, Parameter Source, Polling Interval, and applied Transform.",predatorLabRule:"These fields are acquisition provenance, not by themselves proof of physical semantics.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels"),
        .init(id:"polling",topic:"Polling performance",documentedFact:"More polled parameters generally slow vehicle returns; broadcast and external sources do not impose the same vehicle-polling overhead.",predatorLabRule:"Optimize Config B by measured benchmarks; never promise universal Hz.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels > Scanner Performance"),
        .init(id:"override",topic:"Fallback/Override",documentedFact:"Fallback/Override can influence loaded definitions and Override can severely limit transportability/capability.",predatorLabRule:"Definition-loading state is part of Scanner semantic provenance.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels > Advanced Properties"),
        .init(id:"transform",topic:"External transforms",documentedFact:"User transforms convert external inputs to typed quantities and are stored with the channel configuration; two known input/output points can define a linear transform.",predatorLabRule:"Retain raw voltage, device identity, reference wiring, calibration points, equation, output units and XML fingerprint.",sourceLocator:"HP Tuners Docs > VCM Scanner > Transforming a Channel"),
        .init(id:"filters",topic:"Expression filters",documentedFact:"Expression filters add processing overhead and can use past/future windows during playback.",predatorLabRule:"Raw acquisition remains immutable; filtered views are derived evidence and never replace first-out chronology.",sourceLocator:"HP Tuners Docs > VCM Scanner > Layouts > Filters"),
        .init(id:"editor",topic:"VCM Editor workflow",documentedFact:"HP Tuners recommends resolving DTCs, obtaining baseline logs, preserving the original read, editing/writing, then validating with Scanner.",predatorLabRule:"Diagnose → Baseline → Preserve → Experiment → Measure → Validate is the primary Tune workflow.",sourceLocator:"HP Tuners Docs > VCM Editor > Getting Started"),
        .init(id:"udp",topic:"User Defined Parameters",documentedFact:"XDF-defined switches/scalars/tables can be added when supported by the controller OS; definitions include address/storage/endian/unit/conversion information.",predatorLabRule:"XDF/User Defined remains distinct from HP Tuners native, Ford documented, and PredatorLab inferred semantics.",sourceLocator:"HP Tuners Docs > VCM Editor User Defined Parameters")
    ]
}
