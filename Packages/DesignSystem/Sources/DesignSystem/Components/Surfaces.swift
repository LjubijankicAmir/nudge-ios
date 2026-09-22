import SwiftUI

// MARK: - Tone (shared fill/text/depth triplet)

public extension Theme {
    /// A fill with its guaranteed-contrast text colour and block-shadow tint.
    /// Components take a `Tone`, never raw colours.
    enum Tone: Sendable, CaseIterable, Hashable {
        case surface, accent, accentSecondary, reward, success, warning, danger, info

        public var fill: SwiftUI.Color {
            switch self {
            case .surface: Theme.Color.surface
            case .accent: Theme.Color.accentPrimary
            case .accentSecondary: Theme.Color.accentSecondary
            case .reward: Theme.Color.reward
            case .success: Theme.Color.success
            case .warning: Theme.Color.warning
            case .danger: Theme.Color.danger
            case .info: Theme.Color.info
            }
        }
        public var foreground: SwiftUI.Color {
            switch self {
            case .surface: Theme.Color.textPrimary
            case .accent: Theme.Color.onAccentPrimary
            case .accentSecondary: Theme.Color.onAccentSecondary
            case .reward: Theme.Color.onReward
            case .success: Theme.Color.onSuccess
            case .warning: Theme.Color.onWarning
            case .danger: Theme.Color.onDanger
            case .info: Theme.Color.onInfo
            }
        }
        public var depth: SwiftUI.Color {
            switch self {
            case .surface: Theme.Color.surfaceDepth
            case .accent: Theme.Color.accentPrimaryDepth
            case .accentSecondary: Theme.Color.accentSecondaryDepth
            case .reward: Theme.Color.rewardDepth
            case .success: Theme.Color.successDepth
            case .warning: Theme.Color.warningDepth
            case .danger: Theme.Color.dangerDepth
            case .info: Theme.Color.infoDepth
            }
        }
    }
}

// MARK: - Card

/// The surface container. Rounded 28, block shadow, tone-driven colours.
public struct NudgeCard<Content: View>: View {
    private let tone: Theme.Tone
    private let elevation: CGFloat
    private let content: Content

    public init(
        tone: Theme.Tone = .surface, elevation: CGFloat = Theme.Elevation.card, @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.elevation = elevation
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        content
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(tone.foreground)
            .background(shape.fill(tone.fill))
            .blockShadow(shape, color: tone.depth, depth: elevation)
    }
}

// MARK: - Pill / badge

public struct NudgePill: View {
    private let text: String
    private let systemImage: String?
    private let tone: Theme.Tone
    private let elevated: Bool

    public init(_ text: String, systemImage: String? = nil, tone: Theme.Tone = .surface, elevated: Bool = false) {
        self.text = text
        self.systemImage = systemImage
        self.tone = tone
        self.elevated = elevated
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage).symbolVariant(.fill).fontWeight(.bold)
            }
            Text(text)
        }
        .textStyle(Theme.Typography.caption)
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Capsule().fill(tone.fill))
        .blockShadow(Capsule(), color: tone.depth, depth: elevated ? Theme.Elevation.chip : Theme.Elevation.none)
    }
}

// MARK: - Icon circle

/// SF Symbol inside a coloured circle. Icons never float bare on the background.
public struct IconCircle: View {
    private let systemImage: String
    private let tone: Theme.Tone
    private let size: CGFloat

    public init(_ systemImage: String, tone: Theme.Tone = .accent, size: CGFloat = Theme.Size.iconCircle) {
        self.systemImage = systemImage
        self.tone = tone
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .symbolVariant(.fill)
            .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
            .foregroundStyle(tone.foreground)
            .frame(width: size, height: size)
            .background(Circle().fill(tone.fill))
            .accessibilityHidden(true)
    }
}
