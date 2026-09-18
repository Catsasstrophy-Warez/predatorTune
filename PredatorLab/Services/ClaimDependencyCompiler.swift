import Foundation

struct ClaimDependencyIssue: Identifiable, Codable, Equatable { let id:String; var severity:String; var message:String; var claimID:String?; var downstreamUse:String? }
enum ClaimDependencyCompiler {
    static func compile(_ claims:[TechnicalClaim]) -> [ClaimDependencyIssue] {
        var issues:[ClaimDependencyIssue]=[]
        let ids=Set(claims.map(\.id))
        if ids.count != claims.count { issues.append(.init(id:"duplicate-claim-id",severity:"error",message:"Duplicate technical claim IDs exist.",claimID:nil,downstreamUse:nil)) }
        for c in claims {
            if [.oemVerified,.manufacturerVerified,.professionalCorroboration,.empiricallyVerified].contains(c.state) && c.source == nil { issues.append(.init(id:"verified-no-source-\(c.id)",severity:"error",message:"Verified claim lacks an attached source.",claimID:c.id,downstreamUse:nil)) }
            if c.criticality >= .diagnostic && c.applicability.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { issues.append(.init(id:"no-applicability-\(c.id)",severity:"error",message:"Diagnostic-critical claim lacks applicability.",claimID:c.id,downstreamUse:nil)) }
            if c.state == .disputed { for use in c.downstreamUses { issues.append(.init(id:"disputed-\(c.id)-\(use)",severity:"warning",message:"Disputed claim feeds downstream use.",claimID:c.id,downstreamUse:use)) } }
        }
        return issues
    }
}
