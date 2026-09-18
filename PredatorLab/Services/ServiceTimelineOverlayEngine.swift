import Foundation

struct ServiceTimelineMarker: Identifiable, Equatable {
    let id: UUID
    var serviceRecordID: UUID
    var relativeDays: Double
    var title: String
    var detail: String
    var boundary: String
}

enum ServiceTimelineOverlayEngine {
    static func markers(serviceRecords: [ServiceRecord], log: ImportedLog, withinDays: Double = 90) -> [ServiceTimelineMarker] {
        guard withinDays >= 0 else { return [] }
        return serviceRecords.compactMap { service in
            guard service.vehicleID == log.vehicleID else { return nil }
            let days = log.importDate.timeIntervalSince(service.date) / 86_400
            guard abs(days) <= withinDays else { return nil }
            let title = service.procedure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Service" : service.procedure
            return .init(id: service.id, serviceRecordID: service.id, relativeDays: days, title: title, detail: "\(service.mileage) mi", boundary: "Service marker shows chronology only. Timing does not prove that service caused, prevented, or resolved the diagnostic event.")
        }.sorted { abs($0.relativeDays) < abs($1.relativeDays) }
    }
}
