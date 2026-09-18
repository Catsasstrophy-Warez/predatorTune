import SwiftUI
import Charts

struct AcquisitionQualityVisualizationView: View {
    let report: AcquisitionQualityReport
    private var summary: DataQualitySummary { DataQualityVisualizationEngine.summarize(report) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Evidence Readiness").font(.headline)
                    Text(summary.label).font(.title2.bold())
                }
                Spacer()
                Text("\(Int(summary.overallScore * 100))%")
                    .font(.plMono(22))
                    .accessibilityLabel("Acquisition quality score \(Int(summary.overallScore * 100)) percent")
            }
            ProgressView(value: summary.overallScore)
            Chart(report.channels) { channel in
                BarMark(x: .value("Channel", channel.canonical.rawValue), y: .value("Coverage", channel.coverage))
            }
            .chartYScale(domain: 0...1)
            .chartYAxis { AxisMarks(values: [0, 0.5, 1]) { value in AxisGridLine(); AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v * 100))%") } } } }
            .frame(height: 150)
            .accessibilityIdentifier("forensic.acquisition.coverageChart")
            HStack {
                Label("\(summary.presentChannels)/\(summary.requestedChannels) present", systemImage: "waveform")
                Spacer()
                if summary.missingChannels > 0 { Label("\(summary.missingChannels) missing", systemImage: "questionmark.circle") }
                if summary.limitedChannels > 0 { Label("\(summary.limitedChannels) limited", systemImage: "exclamationmark.triangle") }
            }.font(.caption)
            Text(summary.boundary).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
