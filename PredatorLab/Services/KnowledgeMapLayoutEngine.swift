import Foundation

struct KnowledgeMapPoint: Identifiable, Equatable {
    let id: String
    let node: KnowledgeNode
    let x: Double
    let y: Double
}

enum KnowledgeMapLayoutEngine {
    static func layout(_ graph: TechnicalKnowledgeGraph) -> [KnowledgeMapPoint] {
        let kinds = KnowledgeNodeKind.allCases
        var output: [KnowledgeMapPoint] = []
        for (column, kind) in kinds.enumerated() {
            let nodes = graph.nodes.filter { $0.kind == kind }.sorted { $0.title < $1.title }
            let denominator = Double(max(1, nodes.count + 1))
            for (row, node) in nodes.enumerated() {
                output.append(.init(id: node.id, node: node, x: Double(column + 1) / Double(kinds.count + 1), y: Double(row + 1) / denominator))
            }
        }
        return output
    }

    static func visibleEdges(for selectedID: String?, graph: TechnicalKnowledgeGraph) -> [KnowledgeEdge] {
        guard let selectedID else { return Array(graph.edges.prefix(80)) }
        return graph.edges.filter { $0.from == selectedID || $0.to == selectedID }
    }
}
