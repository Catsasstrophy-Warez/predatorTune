import SwiftUI

struct ForensicTimelineSampleRev85: Identifiable, Hashable, Sendable {
    let id = UUID()
    let time: TimeInterval
    let value: Double
}

/// Semantic-neutral, cursor-synchronized recorder strip. Presentation never upgrades source authority.
struct ForensicTimelineRev85: View {
    let title: String
    let unit: String?
    let samples: [ForensicTimelineSampleRev85]
    @Binding var cursor: ForensicCursorRev85
    var bands: [TimelineEvidenceBand] = []

    private var nearest: ForensicTimelineSampleRev85? {
        guard let t = cursor.time else { return samples.last }
        return samples.min { abs($0.time - t) < abs($1.time - t) }
    }

    var body: some View {
        PLVisualPanel(accent: .plBoost, padding: 12) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(.plTextSecondary)
                        Text(nearest.map { formatted($0.value) } ?? "NO DATA")
                            .font(.system(size: 22, weight: .bold, design: .monospaced)).foregroundStyle(.plTextPrimary)
                        + Text(unit.map { "  \($0)" } ?? "").font(.caption.monospaced()).foregroundStyle(.plTextSecondary)
                    }
                    Spacer()
                    if let t = cursor.time { PLStatusChip(title: String(format: "T+%.3F S", t), icon: "scope", accent: .plBoost) }
                    PLStatusChip(title: "OBSERVED", icon: "waveform", accent: .plSuccess)
                }

                GeometryReader { geo in
                    Canvas { context, size in
                        guard samples.count > 1,
                              let minT = samples.map(\.time).min(), let maxT = samples.map(\.time).max(), maxT > minT,
                              let minV = samples.map(\.value).min(), let maxV = samples.map(\.value).max() else { return }
                        let rangeV = max(maxV - minV, 0.000001)

                        for band in bands where band.range.upperBound >= minT && band.range.lowerBound <= maxT {
                            let lo = max(band.range.lowerBound, minT), hi = min(band.range.upperBound, maxT)
                            let x0 = (lo-minT)/(maxT-minT)*size.width, x1 = (hi-minT)/(maxT-minT)*size.width
                            context.fill(Path(CGRect(x:x0,y:0,width:max(0,x1-x0),height:size.height)), with:.color(.plBoost.opacity(0.10)))
                        }

                        for i in 1..<4 {
                            let y = size.height * CGFloat(i) / 4
                            var grid=Path(); grid.move(to:CGPoint(x:0,y:y)); grid.addLine(to:CGPoint(x:size.width,y:y))
                            context.stroke(grid, with:.color(.plStroke.opacity(0.45)), lineWidth:0.6)
                        }

                        var path = Path()
                        for (index, sample) in samples.enumerated() {
                            let x = (sample.time-minT)/(maxT-minT)*size.width
                            let y = size.height-((sample.value-minV)/rangeV*size.height)
                            if index == 0 { path.move(to:CGPoint(x:x,y:y)) } else { path.addLine(to:CGPoint(x:x,y:y)) }
                        }
                        context.stroke(path, with:.color(.plBoost), style:StrokeStyle(lineWidth:1.8,lineJoin:.round))

                        if let t=cursor.time, t>=minT, t<=maxT {
                            let x=(t-minT)/(maxT-minT)*size.width
                            var marker=Path(); marker.move(to:CGPoint(x:x,y:0)); marker.addLine(to:CGPoint(x:x,y:size.height))
                            context.stroke(marker, with:.color(.white.opacity(0.92)), style:StrokeStyle(lineWidth:1,dash:[3,2]))
                            if let n=nearest {
                                let y=size.height-((n.value-minV)/rangeV*size.height)
                                context.fill(Path(ellipseIn:CGRect(x:x-4,y:y-4,width:8,height:8)),with:.color(.plBoost))
                                context.stroke(Path(ellipseIn:CGRect(x:x-4,y:y-4,width:8,height:8)),with:.color(.white),lineWidth:1)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance:0).onChanged { value in
                        guard let minT=samples.map(\.time).min(), let maxT=samples.map(\.time).max(), maxT>minT else{return}
                        let f=min(max(value.location.x/max(geo.size.width,1),0),1)
                        cursor.time=minT+f*(maxT-minT)
                    })
                }.frame(minHeight: 170)

                HStack {
                    Text(samples.first.map { String(format:"T+%.3f",$0.time) } ?? "—")
                    Spacer(); Text("DRAG TO SCRUB").fontWeight(.black); Spacer()
                    Text(samples.last.map { String(format:"T+%.3f",$0.time) } ?? "—")
                }.font(.system(size:8,design:.monospaced)).foregroundStyle(.plTextSecondary)
            }
        }
        .accessibilityElement(children:.contain)
        .accessibilityLabel("\(title) synchronized telemetry")
    }

    private func formatted(_ value: Double) -> String { abs(value) >= 100 ? String(format:"%.0f",value) : String(format:"%.2f",value) }
}
