import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

// Rev78: evidence-first HPL format laboratory + current VCM Suite/Telemetry research atlas.
// Reverse-engineered structures are hypotheses until corroborated against the user's HPL/XML/CSV artifact set.

enum HPLFormatConfidenceRev78: String, Codable, CaseIterable { case observedBytes="Observed bytes", crossArtifactVerified="Cross-artifact verified", reverseEngineeringHypothesis="Reverse-engineering hypothesis", officialDocumented="Official HP Tuners documented", unknown="Unknown" }

struct HPLFormatObservationRev78: Identifiable, Codable, Hashable {
    let id: String; let field: String; let value: String; let confidence: HPLFormatConfidenceRev78; let boundary: String
}

struct HPLArtifactProbeRev78: Codable, Hashable {
    let fileName: String; let byteCount: Int; let leadingHex: String; let legacyPythonHPTHeaderMatches: Bool; let observedTokens: [String]; let verdict: String
}

enum HPLFormatProbeRev78 {
    static func probe(fileName: String, data: Data) -> HPLArtifactProbeRev78 {
        let prefix = data.prefix(64)
        let hex = prefix.map { String(format:"%02X", $0) }.joined(separator:" ")
        let ascii = String(bytes: prefix.filter { $0 >= 0x20 && $0 <= 0x7E }, encoding:.ascii) ?? ""
        var tokens:[String] = []
        for token in ["HPT","SYNC","SC","SS"] where ascii.contains(token) { tokens.append(token) }
        let hpt = data.count >= 3 && Array(data.prefix(3)) == Array("HPT".utf8)
        return .init(fileName:fileName, byteCount:data.count, leadingHex:hex, legacyPythonHPTHeaderMatches:hpt, observedTokens:tokens, verdict:hpt ? "Legacy parser signature is compatible at the first gate only; remaining fields still require differential validation." : "Legacy parser signature does not match this artifact. Do not apply its offsets/decompression/unit assumptions to this HPL without format/version discovery.")
    }
}

struct HPLReverseEngineeringClaimRev78: Identifiable, Codable, Hashable {
    let id:String; let claim:String; let status:HPLFormatConfidenceRev78; let validation:String
}

enum HPLReverseEngineeringRegistryRev78 {
    static let claims:[HPLReverseEngineeringClaimRev78] = [
        .init(id:"header-hpt", claim:"A log begins with ASCII HPT.", status:.reverseEngineeringHypothesis, validation:"False for the two supplied 2026 HPL artifacts: both begin with bytes 53 53 00 00 and expose SYNC/SC tokens in the first 64 bytes."),
        .init(id:"raw-deflate", claim:"Per-channel payloads use raw DEFLATE.", status:.reverseEngineeringHypothesis, validation:"Search for defensible block boundaries and validate inflation against both supplied HPLs before implementation."),
        .init(id:"channel-record", claim:"Inflated channel records contain channel ID, string, type byte, interval and sample count.", status:.reverseEngineeringHypothesis, validation:"Require structural consistency across many blocks plus XML/CSV correspondence."),
        .init(id:"unit-enum", claim:"The provided Enum15 byte values identify engineering units such as psi=98 and lambda=238.", status:.reverseEngineeringHypothesis, validation:"Verify each candidate by matching native values/distribution against exported CSV and Scanner XML transforms/units."),
        .init(id:"timestamp-int64", claim:"Each sample carries an Int64 timestamp followed by a Double value.", status:.reverseEngineeringHypothesis, validation:"Test candidate epochs/tick scales against CSV event chronology and sample intervals."),
        .init(id:"aes-vin", claim:"An embedded AES key decrypts vehicle identity such as VIN.", status:.reverseEngineeringHypothesis, validation:"Excluded from PredatorLab Rev78. It is unnecessary for engineering analysis and should not be pursued absent a justified need."),
        .init(id:"int32", claim:"The helper named readInt32 represents a true 32-bit integer.", status:.unknown, validation:"The supplied implementation consumes two value bytes plus two unexplained bytes; model as unknown padded/structured field until proven.")
    ]
}

struct HPLCrossArtifactMatchRev78: Identifiable, Codable, Hashable {
    let id:UUID; let hplChannelCandidate:String; let xmlParameterID:String?; let csvColumn:String?; let sampleCountAgreement:Double?; let timingAgreement:Double?; let valueAgreement:Double?; let unitAgreement:Bool?; let status:HPLFormatConfidenceRev78; let notes:String
}

struct HPLSemanticPromotionRev78: Codable, Hashable {
    let eligible:Bool; let reasons:[String]
    static func evaluate(_ match:HPLCrossArtifactMatchRev78) -> HPLSemanticPromotionRev78 {
        var reasons:[String] = []
        if match.xmlParameterID == nil { reasons.append("No Scanner XML identity match") }
        if match.csvColumn == nil { reasons.append("No exported CSV correspondence") }
        if (match.timingAgreement ?? 0) < 0.99 { reasons.append("Timing agreement below artifact-certification target") }
        if (match.valueAgreement ?? 0) < 0.99 { reasons.append("Value agreement below artifact-certification target") }
        if match.unitAgreement != true { reasons.append("Unit/transform semantics unresolved") }
        return .init(eligible:reasons.isEmpty, reasons:reasons)
    }
}

struct VCMSuiteFactRev78: Identifiable, Codable, Hashable {
    let id:String; let area:String; let fact:String; let implication:String; let sourceLocator:String
}

enum VCMSuiteResearchAtlasRev78 {
    static let facts:[VCMSuiteFactRev78] = [
        .init(id:"scanner52",area:"VCM Scanner",fact:"VCM Scanner 5.2 documentation identifies improved performance, a new smaller/faster log format, and MPVI4 support.",implication:"HPL format/version must be fingerprinted. A decoder derived from another generation cannot be assumed compatible.",sourceLocator:"HP Tuners Docs > VCM Scanner > Introduction"),
        .init(id:"channels",area:"Channels",fact:"Scanner inputs can originate from the vehicle/OBD port, HP Tuners interface/external inputs, or third-party serial devices.",implication:"Every observation needs source provenance; display-name equality is insufficient.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels"),
        .init(id:"polling",area:"Acquisition",fact:"HP Tuners documents that adding polled vehicle parameters generally slows collection; broadcast parameters avoid polling overhead and external inputs do not reduce vehicle parameter collection rate.",implication:"Config B optimization must classify source type and benchmark the exact GT500 contract rather than promise a universal rate.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels > Scanner Performance and Polling Interval"),
        .init(id:"fallback",area:"Definitions",fact:"Scanner supports Fallback and Override advanced properties to influence parameter-definition loading; overrides reduce config transportability and may limit Scanner capabilities.",implication:"Persist fallback/override state with semantic certification and treat forced definitions as a provenance warning.",sourceLocator:"HP Tuners Docs > VCM Scanner > Channels > Advanced Properties"),
        .init(id:"transform",area:"External inputs",fact:"External values can be transformed into lambda/AFR/temperature/pressure and user transforms persist with the channel config; HP Tuners instructs using known input/output points from device documentation.",implication:"Wideband commissioning must retain raw voltage, device documentation, calibration points, transform, units and transformed output.",sourceLocator:"HP Tuners Docs > VCM Scanner > Transforming a Channel"),
        .init(id:"filters",area:"Analysis",fact:"Expression filters use Math Parameter-style expressions and add processing overhead.",implication:"PredatorLab should separate acquisition from post-processing filters and preserve unfiltered evidence.",sourceLocator:"HP Tuners Docs > VCM Scanner > Layouts > Filters"),
        .init(id:"standalone",area:"MPVI4",fact:"Standalone logging can deploy channel configurations and start/stop triggers; MPVI4 setup uses MPVI4 Features and can upload default or vehicle-specific channel lists.",implication:"Persist trigger/config deployment fingerprints alongside the resulting session.",sourceLocator:"HP Tuners standalone data logging documentation"),
        .init(id:"telemetry",area:"VCM Telemetry",fact:"Current VCM Telemetry workflow is Configure, Connect/Record, Upload, Review/Share; completed sessions upload over Wi-Fi/hotspot and are browser reviewable.",implication:"Model transport lineage separately from semantic/evidence authority.",sourceLocator:"HP Tuners > VCM Telemetry"),
        .init(id:"navigator",area:"VCM Editor",fact:"Parameter Navigator can filter available parameters by name, data type, group, and Basic/Advanced classification.",implication:"Capture Navigator evidence with controller/OS/VCM version to build strategy-specific calibration inventories.",sourceLocator:"HP Tuners Docs > VCM Editor > Parameter Navigator"),
        .init(id:"templates",area:"VCM Editor",fact:"Tune Template Editor can add selected parameters, unsaved changes, and parameters that differ in a compare file.",implication:"PredatorLab can model template/diff artifacts as controlled experiment manifests, not as proof of parameter semantics.",sourceLocator:"HP Tuners Docs > VCM Editor > Templates"),
        .init(id:"udp",area:"VCM Editor",fact:"User Defined Parameters can import TunerPro XDF switches, scalars and tables; definitions include addresses, storage characteristics, units, equations and axes, but controller OS must actually support the parameter.",implication:"UDP/XDF definitions require a separate provenance class and must never be labeled HP Tuners-native or Ford-authoritative by default.",sourceLocator:"HP Tuners Docs > VCM Editor User Defined Parameters"),
        .init(id:"workflow",area:"Tuning workflow",fact:"HP Tuners recommends resolving DTCs, logging a baseline, preserving the original read, editing/writing, then using Scanner to verify the result.",implication:"This directly supports PredatorLab's Diagnose → Baseline → Experiment → Validate gate sequence.",sourceLocator:"HP Tuners Docs > VCM Editor > Getting Started"),
        .init(id:"license",area:"Licensing",fact:"Vehicle licensing is tied to VIN, VCM serial and OS; some ECM/TCM may be licensed separately; reading/viewing/modifying is distinct from the first write-license event.",implication:"Keep interface identity, controller identity, credits, PCM license and TCM license as separate records.",sourceLocator:"HP Tuners Docs > VCM Editor > Licensing Vehicles")
    ]
}

struct HPLDifferentialValidationPlanRev78: Codable, Hashable {
    let phases:[String]
    static let flagship = HPLDifferentialValidationPlanRev78(phases:[
        "Fingerprint immutable HPL, matching CSV and Scanner XML.",
        "Probe container/header/version without assuming legacy HPT offsets.",
        "Discover repeatable structural boundaries across both supplied HPL files.",
        "Test compression hypotheses under strict decompression and allocation limits.",
        "Emit raw channel candidates without assigning physical meaning.",
        "Infer timestamp representation by interval/event alignment against CSV.",
        "Cross-match candidate channels to XML Parameter ID/source/interval/transform and CSV chronology/distribution.",
        "Validate candidate unit enum values empirically; unknown remains unknown.",
        "Promote only artifact-specific matches that pass timing, value and unit/transform review.",
        "Reconstruct the sep2 5.8–6.0 s event from native HPL candidates and compare first-out chronology with CSV.",
        "Keep original HPL immutable and retain all decoder/version provenance.",
        "Do not decrypt VIN/AES identity data or claim a proprietary HPL specification."
    ])
}
