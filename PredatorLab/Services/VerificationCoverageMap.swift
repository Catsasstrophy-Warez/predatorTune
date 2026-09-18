import Foundation

enum VerificationCoverageState: String, Codable, CaseIterable { case verified = "Verified", quarantined = "Quarantined", disputed = "Disputed", absent = "Evidence absent" }

struct VerificationCoverageCell: Identifiable, Codable, Equatable {
    let id: String
    let subsystem: String
    let total: Int
    let verified: Int
    let quarantined: Int
    let disputed: Int
    let evidenceAbsent: Int
    let state: VerificationCoverageState
    let debtScore: Int
}

enum VerificationCoverageMapEngine {
    static let boundary = "Coverage is provenance coverage, not a health score and not proof that authored claims are true. A subsystem is only as verified as its individual semantic assertions."
    static func build(entries: [TechnicalTruthLedgerEntry]) -> [VerificationCoverageCell] {
        let debt = Dictionary(uniqueKeysWithValues: TechnicalTruthDebtEngine.rank(entries).map { ($0.truthID, $0.score) })
        return Dictionary(grouping: entries, by: subsystem).map { name, group in
            let verified = group.filter { $0.disposition == .verified }.count
            let disputed = group.filter { $0.disposition == .disputed }.count
            let quarantined = group.filter { $0.disposition == .quarantined }.count
            let absent = group.filter { ($0.sourceTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) && $0.disposition != .verified }.count
            let state: VerificationCoverageState = disputed > 0 ? .disputed : (verified == group.count ? .verified : (absent == group.count ? .absent : .quarantined))
            return .init(id:name,subsystem:name,total:group.count,verified:verified,quarantined:quarantined,disputed:disputed,evidenceAbsent:absent,state:state,debtScore:group.reduce(0){$0 + (debt[$1.id] ?? 0)})
        }.sorted { ($0.debtScore, $0.total, $0.subsystem) > ($1.debtScore, $1.total, $1.subsystem) }
    }
    private static func subsystem(_ entry: TechnicalTruthLedgerEntry) -> String {
        switch entry.domain {
        case .circuit, .topology: return "Electrical / Wiring"
        case .sensor: return "Sensors / Measurements"
        case .dtc: return "Diagnostics / DTC Logic"
        case .procedure: return "Service Procedures"
        case .calibration: return "Calibration"
        }
    }
}
