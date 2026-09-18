import Foundation

// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

/// Rev85 compatibility seam: revisions become metadata while routing can converge on capabilities.
/// Existing Rev61–Rev84 implementations remain intact until Apple-runtime gates are green.
enum PredatorLabCapabilityRev85: String, Codable, CaseIterable, Hashable {
    case acquisitionProvenance, nativeHPLProbe, nativeHPLAdmission, semanticCertification
    case configBCompilation, mpvi4Commissioning, acquisitionBenchmark, hypothesisEvidence
    case controlledExperiment, matchedValidation, replay, rootCauseAnalysis
}
struct LabRevisionRev85: Codable, Hashable, Comparable {
    let value:Int
    static func < (lhs:Self,rhs:Self)->Bool { lhs.value < rhs.value }
}
struct LabCapabilityProfileRev85: Codable, Equatable {
    let revision:LabRevisionRev85
    let capabilities:Set<PredatorLabCapabilityRev85>
    let historicalImplementation:String
    func supports(_ capability:PredatorLabCapabilityRev85)->Bool { capabilities.contains(capability) }
}
protocol PredatorLabCapabilityProviderRev85 {
    var profile: LabCapabilityProfileRev85 { get }
}

enum LabCapabilityCatalogRev85 {
    static let rev84 = LabCapabilityProfileRev85(revision:.init(value:84),capabilities:[.acquisitionProvenance,.nativeHPLProbe,.semanticCertification,.hypothesisEvidence,.controlledExperiment,.matchedValidation,.rootCauseAnalysis],historicalImplementation:"Rev84 consolidated evidence workflow")
    static let rev85Target = LabCapabilityProfileRev85(revision:.init(value:85),capabilities:Set(PredatorLabCapabilityRev85.allCases),historicalImplementation:"Execution target; capabilities are not verified merely by inclusion")
}
