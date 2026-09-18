import Foundation

struct PerformanceBudget: Identifiable, Codable, Equatable { let id:String; var operation:String; var targetSeconds:Double?; var boundedMemoryRequired:Bool; var notes:String }
enum PerformanceBudgets {
    static let all:[PerformanceBudget] = [
        .init(id:"launch",operation:"Cold launch",targetSeconds:2.0,boundedMemoryRequired:false,notes:"Target pending Instruments/device validation."),
        .init(id:"forensic.cached",operation:"Open cached forensic log",targetSeconds:1.0,boundedMemoryRequired:false,notes:"Target pending device validation."),
        .init(id:"search",operation:"Typical technical search",targetSeconds:0.1,boundedMemoryRequired:false,notes:"Measure against production-size content."),
        .init(id:"csv.large",operation:"Large CSV import",targetSeconds:nil,boundedMemoryRequired:true,notes:"Streaming path must remain bounded-memory."),
        .init(id:"archive.large",operation:"Evidence archive export/import",targetSeconds:nil,boundedMemoryRequired:true,notes:"Streaming path must remain bounded-memory.")
    ]
}
