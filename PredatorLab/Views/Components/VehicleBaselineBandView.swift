import SwiftUI
import Charts

private struct BaselineBandMark: Identifiable { let id: String; let x: Double; let series: String }

struct VehicleBaselineBandView: View {
    let points: [BaselineVisualizationPoint]
    var warning: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let warning { Label(warning, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.secondary) }
            ForEach(points) { point in
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Text(point.label).font(.subheadline.bold()); Spacer(); Text(point.grade.rawValue).font(.caption) }
                    if let q1 = point.q1, let median = point.median, let q3 = point.q3 {
                        Chart {
                            BarMark(xStart: .value("Q1", q1), xEnd: .value("Q3", q3), y: .value("Band", "Historical IQR"))
                            RuleMark(x: .value("Median", median)).lineStyle(.init(lineWidth: 2))
                            if let current = point.current { PointMark(x: .value("Current", current), y: .value("Band", "Historical IQR")).symbolSize(80) }
                        }.frame(height: 58).accessibilityLabel("\(point.label) historical interquartile band and current observation")
                        Text("Q1 \(fmt(q1)) · median \(fmt(median)) · Q3 \(fmt(q3)) · current \(point.current.map(fmt) ?? "—") \(point.unit)").font(.caption.monospaced())
                    } else { Text("Insufficient historical observations for a learned band.").font(.caption).foregroundStyle(.secondary) }
                    Text(point.boundary).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }.accessibilityIdentifier("baseline.learnedBands")
    }
    private func fmt(_ value: Double) -> String { String(format: "%.3f", value) }
}
