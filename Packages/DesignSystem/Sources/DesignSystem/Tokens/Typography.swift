import SwiftUI

// MARK: - Text style tokens

public extension Theme {
    /// A concrete type ramp entry. Sizes are the *default* (Large) Dynamic Type
    /// values; `relativeTo` is the system text style the size scales with.
    struct TextStyle: Sendable, Hashable {
        public let size: CGFloat
        public let weight: Font.Weight
        public let lineHeight: CGFloat
        public let relativeTo: Font.TextStyle
        /// Tracking in points at the default size; scales with the text.
        public let tracking: CGFloat
        public let uppercased: Bool

        public init(
            size: CGFloat, weight: Font.Weight, lineHeight: CGFloat,
            relativeTo: Font.TextStyle, tracking: CGFloat = 0, uppercased: Bool = false
        ) {
            self.size = size
            self.weight = weight
            self.lineHeight = lineHeight
            self.relativeTo = relativeTo
            self.tracking = tracking
            self.uppercased = uppercased
        }
    }

    /// The Arcade ramp. One family: SF Pro Rounded (system, `design: .rounded`).
    /// No custom font is registered, so there is no fallback to manage.
    enum Typography {
        /// Hero metric ("14"). Clamps at xxxLarge via `relativeTo: .largeTitle`.
        public static let displayXL = TextStyle(
            size: 88, weight: .black, lineHeight: 88, relativeTo: .largeTitle, tracking: -3.5)
        /// Completion headline ("You handled it.").
        public static let displayL = TextStyle(
            size: 64, weight: .black, lineHeight: 64, relativeTo: .largeTitle, tracking: -2.5)
        /// Task title on the protocol card.
        public static let displayM = TextStyle(
            size: 40, weight: .black, lineHeight: 42, relativeTo: .title, tracking: -1.2)
        /// Screen title / wordmark.
        public static let titleL = TextStyle(
            size: 26, weight: .black, lineHeight: 32, relativeTo: .title2, tracking: -0.5)
        /// Section title ("September").
        public static let titleM = TextStyle(size: 20, weight: .black, lineHeight: 26, relativeTo: .title3)
        /// Card title.
        public static let titleS = TextStyle(size: 18, weight: .heavy, lineHeight: 24, relativeTo: .headline)
        /// Button labels.
        public static let label = TextStyle(size: 18, weight: .black, lineHeight: 22, relativeTo: .body)
        public static let labelCompact = TextStyle(size: 16, weight: .heavy, lineHeight: 20, relativeTo: .callout)
        public static let bodyL = TextStyle(size: 17, weight: .bold, lineHeight: 24, relativeTo: .body)
        public static let bodyM = TextStyle(size: 15, weight: .bold, lineHeight: 22, relativeTo: .callout)
        public static let bodyS = TextStyle(size: 14, weight: .bold, lineHeight: 20, relativeTo: .subheadline)
        public static let caption = TextStyle(size: 13, weight: .bold, lineHeight: 18, relativeTo: .footnote)
        /// ALL-CAPS kicker ("DAYS YOU DIDN'T NEED IT").
        public static let eyebrow = TextStyle(
            size: 13, weight: .heavy, lineHeight: 16, relativeTo: .caption, tracking: 1.3, uppercased: true)
        /// Countdown digits. Always paired with `.monospacedDigit()` by the modifier.
        public static let numeric = TextStyle(size: 16, weight: .black, lineHeight: 20, relativeTo: .body)

        public static let all: [(String, TextStyle)] = [
            ("displayXL", displayXL), ("displayL", displayL), ("displayM", displayM),
            ("titleL", titleL), ("titleM", titleM), ("titleS", titleS),
            ("label", label), ("labelCompact", labelCompact),
            ("bodyL", bodyL), ("bodyM", bodyM), ("bodyS", bodyS),
            ("caption", caption), ("eyebrow", eyebrow), ("numeric", numeric),
        ]
    }
}

// MARK: - Modifier

/// Applies a `Theme.TextStyle` with Dynamic Type scaling. Size, tracking and
/// line spacing all scale together via `@ScaledMetric(relativeTo:)`.
struct ScaledTextStyle: ViewModifier {
    let style: Theme.TextStyle
    @ScaledMetric private var size: CGFloat

    init(style: Theme.TextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        let scale = size / style.size
        // SF's natural line height is ~1.2× the point size; lineSpacing adds the remainder.
        let extraLeading = max(0, style.lineHeight - style.size * 1.2) * scale
        content
            .font(.system(size: size, weight: style.weight, design: .rounded))
            .monospacedDigit()
            .tracking(style.tracking * scale)
            .lineSpacing(extraLeading)
            .textCase(style.uppercased ? .uppercase : nil)
    }
}

public extension View {
    /// Apply a named type token. Prefer this over `.font(...)` everywhere.
    func textStyle(_ style: Theme.TextStyle) -> some View {
        modifier(ScaledTextStyle(style: style))
    }
}
