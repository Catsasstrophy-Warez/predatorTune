import SwiftUI

/// Stylized vehicle map for navigation only. It never represents live vehicle state.
struct PLVehicleSystemMap: View {
    let selected: String?
    var onSelect: ((String) -> Void)? = nil
    private let systems = [
        ("ENGINE", "engine.combustion.fill", CGPoint(x: 0.50, y: 0.24)),
        ("FUEL", "fuelpump.fill", CGPoint(x: 0.28, y: 0.37)),
        ("PCM", "cpu", CGPoint(x: 0.72, y: 0.37)),
        ("DCT", "gearshape.2.fill", CGPoint(x: 0.50, y: 0.53)),
        ("VDM", "waveform.path.ecg", CGPoint(x: 0.27, y: 0.70)),
        ("ABS", "steeringwheel", CGPoint(x: 0.73, y: 0.70))
    ]
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 38).fill(Color.plBoost.opacity(0.025))
                    .frame(width: proxy.size.width * 0.52, height: proxy.size.height * 0.86)
                    .overlay(RoundedRectangle(cornerRadius: 38).stroke(Color.plStroke, lineWidth: 2))
                Capsule().fill(Color.plBoost.opacity(0.025)).frame(width: proxy.size.width * 0.30, height: proxy.size.height * 0.70)
                    .overlay(Capsule().stroke(Color.plBoost.opacity(0.38), lineWidth: 1))
                ForEach([0.22, 0.78], id: \.self) { x in
                    ForEach([0.25, 0.74], id: \.self) { y in
                        RoundedRectangle(cornerRadius: 5).fill(Color.plSurfaceRaised).frame(width: 18, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.plStroke))
                            .position(x: proxy.size.width * x, y: proxy.size.height * y)
                    }
                }
                Path { p in
                    p.move(to: CGPoint(x: proxy.size.width * 0.5, y: 8))
                    p.addLine(to: CGPoint(x: proxy.size.width * 0.5, y: proxy.size.height - 8))
                }.stroke(Color.plBoost.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [5,5]))
                ForEach(systems, id: \.0) { system in
                    Button { onSelect?(system.0) } label: {
                        VStack(spacing: 3) {
                            Image(systemName: system.1).font(.caption)
                            Text(system.0).font(.system(size: 8, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(selected == system.0 ? Color.plBackground : Color.plTextPrimary)
                        .frame(width: 58, height: 42)
                        .background(selected == system.0 ? Color.plBoost : Color.plSurfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.plBoost.opacity(0.55)))
                    }.buttonStyle(.plain)
                    .position(x: proxy.size.width * system.2.x, y: proxy.size.height * system.2.y)
                }
            }
        }
        .frame(minHeight: 250)
        .accessibilityLabel("Vehicle systems map")
    }
}

struct PLTrackBreadcrumb: View {
    let items: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Image(systemName: "flag.checkered").foregroundStyle(.plIgnition)
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 { Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.plTextSecondary) }
                    Text(item.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(index == items.count - 1 ? .plBoost : .plTextSecondary)
                }
            }.padding(.vertical, 6)
        }
    }
}

struct PLSessionSummaryCard: View {
    let title: String
    let subtitle: String
    let metric: String
    let status: String
    var body: some View {
        PLCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Color.plStroke, lineWidth: 5)
                    Circle().trim(from: 0, to: 0.72).stroke(Color.plBoost, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: "waveform.path.ecg").foregroundStyle(.plBoost)
                }.frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.plHeadline).foregroundStyle(.plTextPrimary)
                    Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2)
                    Text(status.uppercased()).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.plSuccess)
                }
                Spacer()
                Text(metric).font(.plMono(14)).foregroundStyle(.plIgnition)
            }
        }
    }
}

struct PLCommandRail: View {
    let title: String
    let items: [(String, String)]
    var body: some View {
        PLCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(.plBoost)
                ForEach(items, id: \.0) { item in
                    HStack { Image(systemName: item.1).foregroundStyle(.plIgnition).frame(width: 22); Text(item.0).font(.plCaption).foregroundStyle(.plTextPrimary); Spacer() }
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
