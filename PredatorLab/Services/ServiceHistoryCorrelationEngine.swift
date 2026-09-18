import Foundation

struct ServiceEventAssociation: Identifiable, Codable, Equatable {
    let id: UUID
    var serviceRecordID: UUID
    var logID: UUID
    var daysBetween: Double
    var summary: String
    var boundary: String
    init(serviceRecordID:UUID,logID:UUID,daysBetween:Double,summary:String,boundary:String) { self.id=UUID(); self.serviceRecordID=serviceRecordID; self.logID=logID; self.daysBetween=daysBetween; self.summary=summary; self.boundary=boundary }
}

enum ServiceHistoryCorrelationEngine {
    static func associations(serviceRecords:[ServiceRecord], logs:[ImportedLog], withinDays:Double = 30) -> [ServiceEventAssociation] {
        guard withinDays >= 0 else { return [] }
        return serviceRecords.flatMap { service in
            logs.compactMap { log in
                guard service.vehicleID == log.vehicleID, !log.events.isEmpty else { return nil }
                let days = log.importDate.timeIntervalSince(service.date) / 86_400
                guard days >= 0, days <= withinDays else { return nil }
                return ServiceEventAssociation(serviceRecordID:service.id,logID:log.id,daysBetween:days,summary:"Logged diagnostic event(s) were recorded \(String(format:"%.1f",days)) day(s) after \(service.procedure.isEmpty ? "service" : service.procedure).",boundary:"Temporal association only. This does not establish that the service caused or resolved the event.")
            }
        }.sorted { $0.daysBetween < $1.daysBetween }
    }
}
