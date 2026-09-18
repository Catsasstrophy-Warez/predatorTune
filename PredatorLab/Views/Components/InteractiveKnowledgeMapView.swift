import SwiftUI

struct InteractiveKnowledgeMapView: View {
    @ObservedObject var engine: TechnicalQueryEngine
    var onSelect: ((String) -> Void)? = nil
    @State private var selectedID: String?
    private var graph: TechnicalKnowledgeGraph { TechnicalKnowledgeGraphBuilder.build(from: engine) }
    private var points: [KnowledgeMapPoint] { KnowledgeMapLayoutEngine.layout(graph) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Canvas { context, size in
                    let lookup = Dictionary(uniqueKeysWithValues: points.map { ($0.id, CGPoint(x: $0.x * size.width, y: $0.y * size.height)) })
                    for edge in KnowledgeMapLayoutEngine.visibleEdges(for: selectedID, graph: graph) {
                        if let a = lookup[edge.from], let b = lookup[edge.to] {
                            var path = Path(); path.move(to: a); path.addLine(to: b)
                            context.stroke(path, with: .foreground, lineWidth: selectedID == nil ? 0.5 : 1.5)
                        }
                    }
                }.foregroundStyle(.secondary.opacity(0.45))
                ForEach(points) { point in
                    Button {
                        selectedID = selectedID == point.id ? nil : point.id
                        onSelect?(point.id)
                    } label: {
                        Circle().fill(selectedID == point.id ? Color.plIgnition : Color.plBoost)
                            .frame(width: selectedID == point.id ? 18 : 12, height: selectedID == point.id ? 18 : 12)
                            .overlay(Circle().stroke(Color.primary.opacity(0.4)))
                    }
                    .position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                    .accessibilityLabel(point.node.title)
                    .accessibilityHint("Select to isolate directly linked technical records")
                }
            }
        }
        .frame(minHeight: 380)
        .overlay(alignment: .bottomLeading) {
            if let id = selectedID, let node = graph.nodes.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title).font(.headline)
                    Text("\(node.kind.rawValue.capitalized) • \(TechnicalKnowledgeGraphBuilder.neighbors(of: id, graph: graph).count) linked record(s)").font(.caption)
                    Text("Only authored links are drawn. Missing topology is not inferred.").font(.caption2).foregroundStyle(.secondary)
                }.padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityIdentifier("reference.interactiveKnowledgeMap")
    }
}
