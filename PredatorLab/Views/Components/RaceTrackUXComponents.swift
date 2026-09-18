import SwiftUI

struct PLTrackHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [accent.opacity(0.24), Color.plSurfaceRaised, Color.plBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: icon).font(.system(size: 78, weight: .black)).foregroundStyle(accent.opacity(0.15)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(eyebrow.uppercased()).font(.system(size: 10, weight: .black)).tracking(1.8).foregroundStyle(accent)
                    Rectangle().fill(accent.opacity(0.65)).frame(width: 34, height: 1)
                    Text("PREDATORLAB").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.plTextSecondary)
                }
                Text(title).font(.system(size: 28, weight: .black, design: .rounded)).italic().foregroundStyle(.plTextPrimary)
                Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(3)
                HStack(spacing: 6) {
                    PLStatusChip(title: "Evidence aware", icon: "checkmark.shield", accent: .plSuccess)
                    PLStatusChip(title: "Swift native", icon: "apple.logo", accent: .plBoost)
                }.padding(.top, 3)
            }.padding(18)
        }.frame(minHeight: 156).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.55)))
    }
}

struct PLPitRoute<Destination: View>: View {
    let title: String; let subtitle: String; let icon: String; let accent: Color; @ViewBuilder let destination: Destination
    var body: some View {
        NavigationLink { destination } label: {
            HStack(spacing: 12) {
                ZStack { RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.16)); Image(systemName: icon).foregroundStyle(accent) }.frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) { Text(title).font(.plHeadline).foregroundStyle(.plTextPrimary); Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.plTextSecondary)
            }.padding(10).background(Color.plSurface).clipShape(RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.plStroke))
        }.buttonStyle(.plain)
    }
}

/// A reusable pit-wall section that makes dense technical screens easier to scan without
/// implying that any displayed category is measured or vehicle-validated.
struct PLTrackSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(accent.opacity(0.14))
                        Image(systemName: icon).foregroundStyle(accent)
                    }.frame(width: 38, height: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased()).font(.system(size: 13, weight: .black, design: .rounded)).italic().foregroundStyle(.plTextPrimary)
                        Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                    Spacer()
                }
                content
            }
        }
    }
}

/// Compact authority legend used anywhere a racetrack visual could otherwise be mistaken
/// for live vehicle truth.
struct PLEvidenceLaneLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            lane("MEASURED", .plSuccess)
            lane("DERIVED", .plBoost)
            lane("CANDIDATE", .plWarning)
            lane("UNKNOWN", .plTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evidence authority: measured, derived, candidate, unknown")
    }

    private func lane(_ text: String, _ color: Color) -> some View {
        Text(text).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 5)
            .background(color.opacity(0.10)).clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.30)))
    }
}
