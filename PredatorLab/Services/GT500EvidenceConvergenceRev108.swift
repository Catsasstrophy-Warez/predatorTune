// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

enum GT500EvidenceMatchState:String,Sendable { case profileVerified, csvAndHPLVerified, candidate, missing }
struct GT500EvidenceChannelMatch:Identifiable,Equatable,Sendable {
    let id:String;let parameterID:Int;let name:String;let unit:String?;let interval:String?
    let conceptualID:String?;let state:GT500EvidenceMatchState;let rationale:String
}

enum GT500EvidenceConvergenceRev108 {
    static func matches() -> [GT500EvidenceChannelMatch] {
        let catalog=ValuableLoggingChannelCatalog.gt500Testing
        return HPTunerLoggingProfile.channels.compactMap { ch in
            guard let name=ch.name else{return nil}
            let concept=catalog.first { item in item.searchTerms.contains { term in
                name.localizedCaseInsensitiveContains(term) || term.localizedCaseInsensitiveContains(name)
            }}
            let state:GT500EvidenceMatchState = ch.authority == .verifiedViaCSVAndHPLBinary ? .csvAndHPLVerified : .profileVerified
            return .init(id:"pid-\(ch.parameterID)",parameterID:ch.parameterID,name:name,unit:ch.unit,interval:ch.interval,
                         conceptualID:concept?.id,state:state,
                         rationale: ch.authority == .verifiedViaCSVAndHPLBinary
                         ? "Name/unit verified in matching CSV and independently observed HPL channel-definition text."
                         : "Name/unit verified in matching vehicle-specific CSV export.")
        }
    }

    static func loggingDesign(for preset:LoggingPreset)->LoggingDesignResult {
        let configured=HPTunerLoggingProfile.channels.compactMap { ch -> ScannerConfiguredChannel? in
            guard let name=ch.name else{return nil}
            return .init(id:"pid-\(ch.parameterID)",displayName:name,parameterID:String(ch.parameterID),
                         source:"vehicle-specific supplied profile evidence",pollingInterval:ch.interval,transform:nil)
        }
        let aliases=matches().compactMap { m -> VerifiedChannelAlias? in
            guard let concept=m.conceptualID else{return nil}
            return .init(scannerName:m.name,technicalObjectID:concept,
                         provenance:m.rationale,authority:m.state == .csvAndHPLVerified ? .sourceVerified:.verifiedAlias)
        }
        return IntelligentLoggingDesigner.design(preset:preset,configured:configured,aliases:aliases)
    }
}

struct MissingDiscriminatorFinding:Identifiable,Equatable,Sendable {
    let id:String;let hypothesis:String;let missingConcepts:[String];let evidence:String
}
enum GT500MissingDiscriminatorEngineRev108 {
    static func findings(hypotheses:[(String,[String])],availableConcepts:Set<String>)->[MissingDiscriminatorFinding] {
        hypotheses.compactMap { h in
            let missing=h.1.filter{!availableConcepts.contains($0)}
            return missing.isEmpty ? nil:.init(id:h.0,hypothesis:h.0,missingConcepts:missing,
                                               evidence:"Required observation is absent from the admitted logging profile; hypothesis remains unresolved.")
        }
    }
}
