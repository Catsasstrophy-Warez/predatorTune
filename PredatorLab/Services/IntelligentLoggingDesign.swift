// RevNN here refers to a step in the external "PredatorLab-Expanded-Hardening"
// lineage this project ported from (see HANDOFF.md), NOT this app's own version
// history.
// Status: Independent/standalone.

import Foundation

enum ChannelResolutionStatus:String,Sendable { case exactMatch, verifiedAlias, candidateMatch, missing, unknown }
struct ResolvedLoggingChannel:Identifiable,Equatable,Sendable {
    let id:String;let conceptualID:String;let configuredChannelID:String?;let status:ChannelResolutionStatus
    let rationale:String;let authority:RelationshipAuthority
}
struct LoggingDesignResult:Equatable,Sendable {
    let preset:LoggingPreset;let resolved:[ResolvedLoggingChannel];let budget:ChannelBudgetAssessment
    let missingDiscriminators:[String];let boundary:String
}

enum IntelligentLoggingDesigner {
    static func design(preset:LoggingPreset,configured:[ScannerConfiguredChannel],aliases:[VerifiedChannelAlias]=[])->LoggingDesignResult {
        let catalog=Dictionary(uniqueKeysWithValues:ValuableLoggingChannelCatalog.gt500Testing.map{($0.id,$0)})
        var resolved:[ResolvedLoggingChannel]=[]
        for cid in preset.channelIDs {
            guard let concept=catalog[cid] else{continue}
            let exact=configured.first{c in concept.searchTerms.contains{c.displayName.caseInsensitiveCompare($0) == .orderedSame}}
            if let exact { resolved.append(.init(id:cid,conceptualID:cid,configuredChannelID:exact.id,status:.exactMatch,rationale:"Configured display name exactly matches a catalog search term.",authority:.discoveryCandidate));continue }
            let alias=aliases.first{a in a.technicalObjectID==cid && configured.contains(where:{$0.displayName.caseInsensitiveCompare(a.scannerName) == .orderedSame})}
            if let alias,let c=configured.first(where:{$0.displayName.caseInsensitiveCompare(alias.scannerName) == .orderedSame}) {
                resolved.append(.init(id:cid,conceptualID:cid,configuredChannelID:c.id,status:.verifiedAlias,rationale:alias.provenance,authority:alias.authority));continue
            }
            let candidate=configured.first{c in concept.searchTerms.contains{term in c.displayName.localizedCaseInsensitiveContains(term) || term.localizedCaseInsensitiveContains(c.displayName)}}
            if let candidate { resolved.append(.init(id:cid,conceptualID:cid,configuredChannelID:candidate.id,status:.candidateMatch,rationale:"Lexical discovery only.",authority:.discoveryCandidate)) }
            else { resolved.append(.init(id:cid,conceptualID:cid,configuredChannelID:nil,status:.missing,rationale:concept.rationale,authority:.discoveryCandidate)) }
        }
        let missing=resolved.filter{$0.status == .missing}.map(\.conceptualID)
        return .init(preset:preset,resolved:resolved,budget:ChannelBudgetAnalyzer.assess(configured:configured),missingDiscriminators:missing,
                     boundary:"Resolution status describes evidence quality, not tune safety or vehicle applicability.")
    }
}

struct ChannelIdentityRecord:Identifiable,Equatable,Sendable {
    let id:String;let parameterID:String?;let source:String?;let displayName:String;let unit:String?
    let pollingInterval:String?;let transform:String?;let conceptualID:String?;let provenance:String
}
enum ChannelIdentityRegistryBuilder {
    static func build(configured:[ScannerConfiguredChannel],resolved:[ResolvedLoggingChannel],provenance:String)->[ChannelIdentityRecord] {
        configured.map { c in
            let concept=resolved.first(where:{$0.configuredChannelID==c.id})?.conceptualID
            return .init(id:c.id,parameterID:c.parameterID,source:c.source,displayName:c.displayName,unit:nil,
                         pollingInterval:c.pollingInterval,transform:c.transform,conceptualID:concept,provenance:provenance)
        }
    }
}

enum ChannelSourceKind:String,Sendable { case broadcast, polled, external, unknown }
struct ChannelSourceClassification:Identifiable,Equatable,Sendable { let id:String;let kind:ChannelSourceKind;let evidence:String }
enum ChannelSourceClassifier {
    static func classify(_ c:ScannerConfiguredChannel)->ChannelSourceClassification {
        let s=(c.source ?? "").lowercased()
        if s.contains("broadcast") {
            return .init(id:c.id,kind:.broadcast,evidence:"Artifact source text explicitly contains broadcast.")
        }
        if s.contains("external") || s.contains("device") {
            return .init(id:c.id,kind:.external,evidence:"Artifact source text explicitly identifies external/device source.")
        }
        if c.pollingInterval != nil {
            return .init(id:c.id,kind:.polled,evidence:"Artifact explicitly contains a polling interval.")
        }
        return .init(id:c.id,kind:.unknown,evidence:"Insufficient artifact metadata; source type not inferred from channel name.")
    }
}

struct DerivedSignalDefinition:Identifiable,Equatable,Sendable {
    let id:String;let name:String;let inputConcepts:[String];let formula:String;let requiredAuthority:RelationshipAuthority
}
enum DerivedSignalRegistry {
    static let definitions=[
        DerivedSignalDefinition(id:"boost-relative-baro",name:"Boost relative to BARO",inputConcepts:["map","baro"],formula:"MAP - BARO",requiredAuthority:.verifiedAlias),
        .init(id:"lambda-error",name:"Lambda Error",inputConcepts:["lambda-commanded","lambda-measured"],formula:"measured - commanded",requiredAuthority:.verifiedAlias),
        .init(id:"rail-error",name:"Rail Pressure Error",inputConcepts:["fuel-pressure-rail"],formula:"actual - desired",requiredAuthority:.verifiedAlias),
        .init(id:"rpm-slope",name:"RPM Slope",inputConcepts:["engine-speed"],formula:"dRPM/dt",requiredAuthority:.explicitAuthored)
    ]
}
