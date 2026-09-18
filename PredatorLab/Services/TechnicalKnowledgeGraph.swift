import Foundation

enum KnowledgeNodeKind: String, Codable, CaseIterable { case component, circuit, sensor, dtc, calibration, procedure, signal }
struct KnowledgeNode: Identifiable, Codable, Hashable { let id: String; var kind: KnowledgeNodeKind; var title: String }
struct KnowledgeEdge: Identifiable, Codable, Hashable { let id: String; var from: String; var to: String; var relationship: String }
struct TechnicalKnowledgeGraph { var nodes: [KnowledgeNode]; var edges: [KnowledgeEdge] }

struct KnowledgeNodeDetail: Identifiable {
    let id:String; let title:String; let kind:KnowledgeNodeKind
    var summary:String; var path:[String]=[]; var connectors:[String]=[]; var pins:[String]=[]; var testPoints:[String]=[]; var evidence:[TechnicalSource]=[]
}

enum TechnicalKnowledgeGraphBuilder {
    static func build(from engine: TechnicalQueryEngine) -> TechnicalKnowledgeGraph {
        var nodes:[KnowledgeNode]=[]; var edges:[KnowledgeEdge]=[]
        func key(_ kind: KnowledgeNodeKind,_ id: UUID)->String { "\(kind.rawValue):\(id)" }
        func edge(_ a:String,_ b:String,_ r:String){ guard a != b else{return}; edges.append(.init(id:"\(a)>\(r)>\(b)",from:a,to:b,relationship:r)) }
        for x in engine.components { let k=key(.component,x.id); nodes.append(.init(id:k,kind:.component,title:x.name)); for id in x.relatedCircuits { edge(k,key(.circuit,id),"uses circuit") }; for id in x.relatedSensors { edge(k,key(.sensor,id),"observed by") }; for id in x.relatedCalibration { edge(k,key(.calibration,id),"influenced by") } }
        for x in engine.circuits { let k=key(.circuit,x.id); nodes.append(.init(id:k,kind:.circuit,title:x.name)); for code in x.relatedDTCs { if let d=engine.dtcs.first(where:{$0.code==code}) { edge(k,key(.dtc,d.id),"related DTC") } } }
        for x in engine.sensors { let k=key(.sensor,x.id); nodes.append(.init(id:k,kind:.sensor,title:x.name)); if let id=x.relatedCircuit { edge(k,key(.circuit,id),"wired through") }; for id in x.relatedProcedures { edge(k,key(.procedure,id),"tested by") }; for id in x.relatedCalibration { edge(k,key(.calibration,id),"feeds") } }
        for x in engine.dtcs { let k=key(.dtc,x.id); nodes.append(.init(id:k,kind:.dtc,title:"\(x.code) — \(x.title)")); if let id=x.relatedComponent { edge(k,key(.component,id),"related component") }; for id in x.relatedCircuits { edge(k,key(.circuit,id),"related circuit") }; for id in x.relatedSensors { edge(k,key(.sensor,id),"related sensor") } }
        for x in engine.calibration { let k=key(.calibration,x.id); nodes.append(.init(id:k,kind:.calibration,title:x.name)); for id in x.relatedSensors { edge(k,key(.sensor,id),"uses signal") }; for id in x.relatedComponents { edge(k,key(.component,id),"controls") } }
        for x in engine.procedures { let k=key(.procedure,x.id); nodes.append(.init(id:k,kind:.procedure,title:x.name)); for id in x.relatedComponents { edge(k,key(.component,id),"services") }; for id in x.relatedCircuits { edge(k,key(.circuit,id),"tests") }; for id in x.relatedSensors { edge(k,key(.sensor,id),"measures") } }
        for x in MeasurementAtlas.entries { nodes.append(.init(id:"signal:\(x.id.rawValue)",kind:.signal,title:x.title)) }
        return .init(nodes:Array(Dictionary(grouping:nodes,by:\.id).compactMap{$0.value.first}), edges:Array(Dictionary(grouping:edges,by:\.id).compactMap{$0.value.first}))
    }
    static func neighbors(of id:String, graph:TechnicalKnowledgeGraph)->[(KnowledgeNode,String)] {
        graph.edges.compactMap { e in
            if e.from==id, let n=graph.nodes.first(where:{$0.id==e.to}) { return (n,e.relationship) }
            if e.to==id, let n=graph.nodes.first(where:{$0.id==e.from}) { return (n,e.relationship) }
            return nil
        }
    }
    static func detail(for node:KnowledgeNode, engine:TechnicalQueryEngine)->KnowledgeNodeDetail {
        let uuid = node.id.split(separator:":",maxSplits:1).last.flatMap{UUID(uuidString:String($0))}
        switch node.kind {
        case .circuit:
            guard let uuid, let x=engine.circuits.first(where:{$0.id==uuid}) else { return .init(id:node.id,title:node.title,kind:node.kind,summary:"No authored detail available.") }
            return .init(id:node.id,title:x.name,kind:.circuit,summary:x.function,path:x.path.sorted{$0.sequence<$1.sequence}.map{"\($0.sequence). \($0.type): \($0.designation)\($0.expectedReading.map{" — \($0)"} ?? "")"},connectors:x.connectors.map{"\($0.name) — \($0.location)"},pins:x.connectors.flatMap{$0.pins.map{"pin \($0.number): \($0.function)\($0.expectedVoltage.map{" — \($0)"} ?? "")"}},testPoints:x.testPoints.map{"\($0.name): \($0.expectedResult) — if not: \($0.failureInterpretation)"},evidence:x.sources)
        case .component:
            guard let uuid, let x=engine.components.first(where:{$0.id==uuid}) else { return .init(id:node.id,title:node.title,kind:node.kind,summary:"No authored detail available.") }
            return .init(id:node.id,title:x.name,kind:.component,summary:"\(x.section.rawValue) • \(x.manufacturer ?? x.oem ?? "manufacturer not recorded")",evidence:x.sources)
        case .sensor:
            guard let uuid, let x=engine.sensors.first(where:{$0.id==uuid}) else { return .init(id:node.id,title:node.title,kind:node.kind,summary:"No authored detail available.") }
            return .init(id:node.id,title:x.name,kind:.sensor,summary:x.diagnosticPurpose,evidence:x.sources)
        default: return .init(id:node.id,title:node.title,kind:node.kind,summary:"Use the linked record and neighboring nodes for authored context.")
        }
    }
}
