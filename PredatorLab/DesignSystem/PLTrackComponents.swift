// PredatorLab/DesignSystem/PLTrackComponents.swift
// Screen headers, hub rows and section containers shared by every tab root and
// workspace. Hubs compose PLHubSection + PLHubRow instead of defining their own
// row styling.

import SwiftUI

/// Compact screen header: eyebrow, title, one-line purpose. Sized to leave the
/// working content above the fold on an iPhone.
struct PLTrackHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(.plScaled(10, weight: .black))
                        .tracking(1.6)
                        .foregroundStyle(accent)
                    Rectangle().fill(accent.opacity(0.6)).frame(width: 28, height: 1)
                }
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(.plTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.plCaption)
                    .foregroundStyle(.plTextSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            PLIconTile(icon: icon, accent: accent, size: 52)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [accent.opacity(0.18), Color.plSurface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(accent.opacity(0.45)))
        .accessibilityElement(children: .combine)
    }
}

/// Rounded tinted square holding an SF Symbol. Used by headers, hub rows and tiles.
struct PLIconTile: View {
    let icon: String
    var accent: Color = .plBoost
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous).fill(accent.opacity(0.16))
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The one row style for navigation lists across hubs. Use as a NavigationLink or
/// Button label; the label text doubles as the accessibility label UI tests tap.
struct PLHubRow: View {
    @Environment(\.plGloveMode) private var gloveMode
    let title: String
    var subtitle: String? = nil
    let icon: String
    var accent: Color = .plBoost
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            PLIconTile(icon: icon, accent: accent, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.plHeadline).foregroundStyle(.plTextPrimary)
                if let subtitle {
                    Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            if let badge { PLBadge(text: badge, color: accent, filled: false) }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.plTextSecondary)
        }
        .padding(.vertical, gloveMode ? 14 : 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
        .accessibilityValue(badge ?? "")
    }
}

/// Titled card grouping related hub rows, separated by hairlines.
struct PLHubSection<Content: View>: View {
    let title: String
    var icon: String = "flag.checkered"
    var accent: Color = .plBoost
    var footnote: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        PLCard(padding: 14) {
            VStack(alignment: .leading, spacing: 2) {
                PLSectionHeader(title: title, systemImage: icon, accent: accent)
                    .padding(.bottom, 4)
                content
                if let footnote {
                    Text(footnote).font(.plCaption).foregroundStyle(.plTextSecondary).padding(.top, 6)
                }
            }
        }
    }
}

/// Grid tile for primary routes (Home quick routes, system shortcuts).
struct PLRouteTile: View {
    let title: String
    let subtitle: String
    let icon: String
    var accent: Color = .plBoost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PLIconTile(icon: icon, accent: accent, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.plScaled(16, weight: .black, design: .rounded)).italic().foregroundStyle(.plTextPrimary)
                Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary).lineLimit(2).multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(
            LinearGradient(colors: [accent.opacity(0.16), Color.plSurface], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accent.opacity(0.4)))
        .contentShape(Rectangle())
    }
}

/// Standalone navigation card: a PLHubRow on its own surface. Kept for workspaces
/// that list routes outside a PLHubSection.
struct PLPitRoute<Destination: View>: View {
    let title: String; let subtitle: String; let icon: String; let accent: Color; @ViewBuilder let destination: Destination
    var body: some View {
        NavigationLink { destination } label: {
            PLHubRow(title: title, subtitle: subtitle, icon: icon, accent: accent)
                .padding(.horizontal, 12).padding(.vertical, 2)
                .background(Color.plSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.plStroke))
        }
        .buttonStyle(.plain)
    }
}

/// A titled card for dense technical screens. Does not imply that any displayed
/// category is measured or vehicle-validated.
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
                    PLIconTile(icon: icon, accent: accent, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased()).font(.plScaled(13, weight: .black, design: .rounded)).italic().foregroundStyle(.plTextPrimary)
                        Text(subtitle).font(.plCaption).foregroundStyle(.plTextSecondary)
                    }
                    Spacer()
                }
                content
            }
        }
    }
}

/// Compact authority legend used anywhere a visual could otherwise be mistaken for
/// live vehicle truth.
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
        Text(text).font(.plScaled(8, weight: .black, design: .monospaced)).foregroundStyle(color)
            .padding(.horizontal, 7).padding(.vertical, 5)
            .background(color.opacity(0.10)).clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.30)))
    }
}
