import Foundation

enum ContentIntegritySeverity: String, Codable { case warning, error }
struct ContentIntegrityIssue: Identifiable, Codable, Equatable { let id:String; var severity:ContentIntegritySeverity; var message:String }
struct ContentIntegrityReport: Codable, Equatable { var issues:[ContentIntegrityIssue]; var isValid:Bool { !issues.contains{$0.severity == .error} } }

enum ContentIntegrityCompiler {
    static func validate(claims:[TechnicalClaim]) -> ContentIntegrityReport {
        var issues:[ContentIntegrityIssue]=[]
        let groups=Dictionary(grouping:claims,by:\.id)
        for (id, values) in groups where values.count > 1 { issues.append(.init(id:"duplicate.\(id)",severity:.error,message:"Duplicate technical claim ID: \(id)")) }
        for c in claims {
            if [.oemVerified,.manufacturerVerified,.professionalCorroboration].contains(c.state), c.source == nil { issues.append(.init(id:"source.\(c.id)",severity:.error,message:"Verified claim \(c.id) has no attached source.")) }
            if c.criticality >= .diagnostic && c.applicability.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { issues.append(.init(id:"applicability.\(c.id)",severity:.error,message:"Diagnostic-critical claim \(c.id) has no applicability boundary.")) }
            if c.state == .disputed { issues.append(.init(id:"disputed.\(c.id)",severity:.warning,message:"Disputed claim \(c.id) must not silently drive strong diagnostic conclusions.")) }
        }
        return .init(issues:issues.sorted{$0.id<$1.id})
    }

    static func conflicts(_ claims:[TechnicalClaim]) -> [[TechnicalClaim]] {
        Dictionary(grouping:claims.filter{$0.state != .superseded}) { "\($0.statement.lowercased())|\($0.applicability.lowercased())" }
            .values.filter { group in Set(group.compactMap(\.value)).count > 1 }
    }
}
