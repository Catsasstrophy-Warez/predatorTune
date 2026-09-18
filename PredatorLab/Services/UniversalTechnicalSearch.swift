import Foundation

enum TechnicalSearchDomain: String, Codable, CaseIterable { case component, circuit, sensor, dtc, procedure, calibration, signal }

struct TechnicalSearchHit: Identifiable, Codable {
    let id: String
    var domain: TechnicalSearchDomain
    var title: String
    var subtitle: String
    var score: Int
}

/// Cross-domain offline search. Results are deliberately factual index matches, not diagnostic conclusions.
enum UniversalTechnicalSearch {
    static func search(_ query: String, engine: TechnicalQueryEngine, limit: Int = 40) -> [TechnicalSearchHit] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        func score(_ title: String, _ body: String = "") -> Int {
            let t = title.lowercased(), b = body.lowercased()
            if t == q { return 100 }
            if t.hasPrefix(q) { return 80 }
            if t.contains(q) { return 60 }
            if b.contains(q) { return 30 }
            return 0
        }
        var hits: [TechnicalSearchHit] = []
        for x in engine.components { let s=score(x.name); if s>0 { hits.append(.init(id:"component:\(x.id)",domain:.component,title:x.name,subtitle:"Component",score:s)) } }
        for x in engine.circuits { let s=score(x.name); if s>0 { hits.append(.init(id:"circuit:\(x.id)",domain:.circuit,title:x.name,subtitle:"Circuit",score:s)) } }
        for x in engine.sensors { let s=score(x.name, x.pidName ?? ""); if s>0 { hits.append(.init(id:"sensor:\(x.id)",domain:.sensor,title:x.name,subtitle:x.pidName ?? "Sensor / PID",score:s)) } }
        for x in engine.dtcs { let s=max(score(x.code),score(x.title)); if s>0 { hits.append(.init(id:"dtc:\(x.id)",domain:.dtc,title:"\(x.code) — \(x.title)",subtitle:"DTC",score:s)) } }
        for x in engine.procedures { let s=score(x.name, x.purpose); if s>0 { hits.append(.init(id:"procedure:\(x.id)",domain:.procedure,title:x.name,subtitle:"Procedure",score:s)) } }
        for x in engine.calibration { let s=score(x.name); if s>0 { hits.append(.init(id:"calibration:\(x.id)",domain:.calibration,title:x.name,subtitle:"Calibration",score:s)) } }
        for x in MeasurementAtlas.entries {
            let semanticAliases = CanonicalChannel.allCases.filter { $0.rawValue == x.id.rawValue || $0.rawValue.lowercased() == x.title.lowercased() }.flatMap { ChannelResolver.aliases(for: $0) }.joined(separator: " ")
            let s=score(x.title, x.diagnosticUse + " " + semanticAliases); if s>0 { hits.append(.init(id:"signal:\(x.id)",domain:.signal,title:x.title,subtitle:"Signal Atlas",score:s)) }
        }
        return hits.sorted { $0.score == $1.score ? $0.title < $1.title : $0.score > $1.score }.prefix(limit).map{$0}
    }
}
