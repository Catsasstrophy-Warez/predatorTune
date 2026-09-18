// PredatorLab/DesignSystem/PLTheme.swift
// Shared visual language for PredatorLab: "garage/mechanic" dark theme — carbon-black
// surfaces, ignition-orange + boost-blue accents, monospaced gauge readouts for numeric
// data. Every screen should build on these tokens/components rather than defining its
// own ad hoc colors or card styling, so the app reads as one coherent product.
//
// Palette is defined for dark mode first (the app's native mode — a garage/dyno tool is
// used in low light as often as bright), with light-mode equivalents that stay legible.

import SwiftUI

// MARK: - Colors

extension Color {
    /// Deep carbon-black screen background.
    static let plBackground = Color("PLBackground", bundle: nil, fallbackDark: Color(red: 0.043, green: 0.051, blue: 0.063), fallbackLight: Color(red: 0.96, green: 0.965, blue: 0.975))
    /// Card/tile surface, one step lighter than background.
    static let plSurface = Color("PLSurface", bundle: nil, fallbackDark: Color(red: 0.086, green: 0.098, blue: 0.114), fallbackLight: Color.white)
    /// Raised surface (nested cards, pressed states).
    static let plSurfaceRaised = Color("PLSurfaceRaised", bundle: nil, fallbackDark: Color(red: 0.122, green: 0.137, blue: 0.157), fallbackLight: Color(red: 0.93, green: 0.935, blue: 0.945))
    /// Hairline separators/borders.
    static let plStroke = Color("PLStroke", bundle: nil, fallbackDark: Color(red: 0.2, green: 0.22, blue: 0.25), fallbackLight: Color(red: 0.85, green: 0.86, blue: 0.88))

    /// Primary accent — ignition/tach-redline orange. Use for primary actions and emphasis.
    static let plIgnition = Color(red: 1.0, green: 0.42, blue: 0.05)
    /// Secondary accent — supercharger boost blue. Use for data/electronics/info states.
    static let plBoost = Color(red: 0.22, green: 0.68, blue: 0.98)

    static let plSuccess = Color(red: 0.30, green: 0.78, blue: 0.42)
    static let plWarning = Color(red: 1.0, green: 0.68, blue: 0.12)
    static let plCritical = Color(red: 0.96, green: 0.26, blue: 0.30)
    /// Neutral informational accent — provenance/metadata panels, distinct from the
    /// ignition/boost/warning/critical/success semantic colors above.
    static let plInfo = Color(red: 0.58, green: 0.55, blue: 0.92)

    static let plTextPrimary = Color("PLTextPrimary", bundle: nil, fallbackDark: Color(white: 0.96), fallbackLight: Color(white: 0.08))
    static let plTextSecondary = Color("PLTextSecondary", bundle: nil, fallbackDark: Color(white: 0.62), fallbackLight: Color(white: 0.42))

    /// Convenience init that resolves without requiring the color to exist in an asset
    /// catalog — avoids needing a Colors.xcassets set for every token while keeping the
    /// call sites identical to `Color("Name")` if those assets get added later.
    init(_ name: String, bundle: Bundle?, fallbackDark: Color, fallbackLight: Color) {
        self = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(fallbackDark) : UIColor(fallbackLight)
        })
    }
}

/// Lets every PL color be used with leading-dot syntax in `.foregroundStyle(.plX)` /
/// `.tint(.plX)` call sites (Swift only resolves implicit-member dot syntax against
/// static members of the *parameter's* declared type — `ShapeStyle` here — not against
/// unrelated static members on `Color`).
extension ShapeStyle where Self == Color {
    static var plBackground: Color { .plBackground }
    static var plSurface: Color { .plSurface }
    static var plSurfaceRaised: Color { .plSurfaceRaised }
    static var plStroke: Color { .plStroke }
    static var plIgnition: Color { .plIgnition }
    static var plBoost: Color { .plBoost }
    static var plSuccess: Color { .plSuccess }
    static var plInfo: Color { .plInfo }
    static var plWarning: Color { .plWarning }
    static var plCritical: Color { .plCritical }
    static var plTextPrimary: Color { .plTextPrimary }
    static var plTextSecondary: Color { .plTextSecondary }
}

// MARK: - Typography

extension Font {
    /// Large screen/section titles — bold rounded, garage-signage feel.
    static let plTitle = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let plHeadline = Font.system(size: 17, weight: .bold, design: .rounded)
    static let plBody = Font.system(size: 15, weight: .medium, design: .rounded)
    static let plCaption = Font.system(size: 12, weight: .semibold, design: .rounded)
    /// Numeric gauge/dyno-readout style — monospaced digits for live data, specs, torque values.
    static func plGauge(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .bold, design: .monospaced) }
    static func plMono(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}

// MARK: - Screen background

/// Applies the app's standard dark-carbon screen background with a subtle top glow,
/// consistent across every tab root.
struct PLScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.plBackground.ignoresSafeArea()
                    LinearGradient(colors: [Color.plBackground, Color(red: 0.025, green: 0.045, blue: 0.065), Color.plBackground], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                    RadialGradient(
                        colors: [Color.plBoost.opacity(0.11), Color.plIgnition.opacity(0.035), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 520
                    )
                    .ignoresSafeArea()
                    // Abstract pit-lane/grid texture. It suggests a circuit without using
                    // decorative photography behind dense forensic data.
                    VStack(spacing: 34) {
                        ForEach(0..<18, id: \.self) { _ in
                            Rectangle().fill(Color.plStroke.opacity(0.11)).frame(height: 1)
                        }
                    }
                    .rotationEffect(.degrees(-7))
                    .scaleEffect(1.25)
                    .ignoresSafeArea()
                }
            )
    }
}

extension View {
    func plScreenBackground() -> some View { modifier(PLScreenBackground()) }

    /// Gives scrollable content a hard cutoff at the bottom edge instead of iOS 26's default
    /// soft/blurred "Liquid Glass" edge effect. Without this, content that scrolls to the
    /// bottom of the screen — under the floating translucent tab bar — gets sampled/lensed by
    /// the glass material, which reads as a ghosted double-image of whatever sits there rather
    /// than the intended subtle blur. A hard stop keeps the tab bar cleanly opaque-reading
    /// regardless of what content is behind it. No-op pre-iOS 26.
    @ViewBuilder
    func plHardBottomEdge() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.hard, for: .bottom)
        } else {
            self
        }
    }
}

// MARK: - Card container

/// Standard garage-tool card: dark surface, hairline stroke, soft shadow, consistent
/// corner radius. Use for every grouped block instead of bare `.background()` calls.
struct PLCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.plSurface.opacity(0.97))
                    LinearGradient(colors: [Color.plBoost.opacity(0.035), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.plStroke.opacity(0.92), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 9, y: 5)
    }
}

/// Consistent recoverable failure state for persisted/content-backed workspaces.
struct PLLoadErrorCard: View {
    let title: String
    let message: String
    let retry: () -> Void

    var body: some View {
        PLCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: "exclamationmark.triangle.fill")
                    .font(.plHeadline).foregroundStyle(.plWarning)
                Text(message).font(.plCaption).foregroundStyle(.plTextSecondary)
                Button("Retry", action: retry)
                    .buttonStyle(.plPrimary(accent: .plWarning))
                    .accessibilityIdentifier("state.retry")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("state.loadError")
    }
}

/// Shared loading state for content-backed screens. The message remains useful to
/// VoiceOver users and avoids a visually ambiguous spinner-only screen.
struct PLLoadingCard: View {
    let title: String
    var message: String? = nil

    var body: some View {
        PLCard {
            HStack(spacing: 12) {
                ProgressView().tint(.plIgnition)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.plHeadline)
                    if let message { Text(message).font(.plCaption).foregroundStyle(.plTextSecondary) }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.map { "\(title). \($0)" } ?? title)
        .accessibilityIdentifier("state.loading")
    }
}

/// Shared empty state with an optional next action, used when the absence of data
/// is expected rather than an error.
struct PLEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        PLCard {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 28, weight: .semibold)).foregroundStyle(.plBoost)
                Text(title).font(.plHeadline).multilineTextAlignment(.center)
                Text(message).font(.plCaption).foregroundStyle(.plTextSecondary).multilineTextAlignment(.center)
                if let actionTitle, let action {
                    Button(actionTitle, action: action).buttonStyle(.plPrimary(accent: .plIgnition))
                }
            }.frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("state.empty")
    }
}

// MARK: - Section header

struct PLSectionHeader: View {
    let title: String
    var systemImage: String?
    var accent: Color = .plIgnition

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(accent)
                    .font(.system(size: 13, weight: .bold))
            }
            Text(title.uppercased())
                .font(.plCaption)
                .foregroundStyle(.plTextSecondary)
                .tracking(0.8)
        }
    }
}

// MARK: - Stat tile (gauge-style readout)

/// A single glanceable metric — value in monospaced gauge type, label beneath, optional
/// accent color. Used for Garage Mode's live stats and Reference spec highlights.
struct PLStatTile: View {
    let label: String
    let value: String
    var unit: String? = nil
    var accent: Color = .plIgnition
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.plGauge(24))
                    .foregroundStyle(.plTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(.plMono(11))
                        .foregroundStyle(.plTextSecondary)
                }
            }
            Text(label.uppercased())
                .font(.plCaption)
                .foregroundStyle(.plTextSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Circular gauge ring

/// Circular progress gauge (0...1) — used for phase progress, session/time visualizations,
/// and anywhere a dial reads better than a bar. Sweeps like a tachometer, redlining in
/// ignition-orange as it approaches completion.
struct PLGaugeRing: View {
    var progress: Double // 0...1
    var lineWidth: CGFloat = 10
    var accent: Color = .plIgnition
    var label: String? = nil
    var value: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.plStroke, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [accent.opacity(0.5), accent], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 2) {
                if let value {
                    Text(value)
                        .font(.plGauge(20))
                        .foregroundStyle(.plTextPrimary)
                }
                if let label {
                    Text(label.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.plTextSecondary)
                        .tracking(0.5)
                }
            }
        }
    }
}

// MARK: - Badge (generic pill, e.g. severity/grade/difficulty)

struct PLBadge: View {
    let text: String
    var color: Color = .plIgnition
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundStyle(filled ? Color.black.opacity(0.85) : color)
            .background(filled ? color : color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(color.opacity(filled ? 0 : 0.4), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style (glove-friendly, matches Garage Mode's large-target needs)

struct PLPrimaryButtonStyle: ButtonStyle {
    var accent: Color = .plIgnition
    var minHeight: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.plHeadline)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .foregroundStyle(.white)
            .background(accent.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension ButtonStyle where Self == PLPrimaryButtonStyle {
    static var plPrimary: PLPrimaryButtonStyle { PLPrimaryButtonStyle() }
    static func plPrimary(accent: Color) -> PLPrimaryButtonStyle { PLPrimaryButtonStyle(accent: accent) }
}
