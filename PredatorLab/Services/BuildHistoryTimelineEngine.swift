import Foundation

struct BuildHistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID { buildID }
    let buildID: UUID
    let date: Date
    let name: String
    let revisionIndex: Int
    let changeCountFromPrevious: Int
    let changedCategories: [BuildChangeCategory]
    let isCurrent: Bool
}
enum BuildHistoryTimelineEngine {
    static func timeline(vehicle: GT500Vehicle) -> [BuildHistoryEntry] {
        let ordered = vehicle.buildStates.sorted { $0.date < $1.date }
        return ordered.enumerated().map { index, build in
            let ledger = index > 0 ? BuildChangeLedgerEngine.compare(ordered[index-1], build) : nil
            let categories = Array(Set(ledger?.changes.map(\.category) ?? [])).sorted { $0.rawValue < $1.rawValue }
            return .init(buildID:build.id,date:build.date,name:build.name,revisionIndex:index+1,changeCountFromPrevious:ledger?.changes.count ?? 0,changedCategories:categories,isCurrent:vehicle.currentBuildStateID == build.id)
        }
    }
}
