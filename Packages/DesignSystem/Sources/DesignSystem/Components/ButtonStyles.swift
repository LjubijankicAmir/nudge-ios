import SwiftUI

// MARK: - Block shadow (the Arcade depth treatment)

/// Draws a hard, solid block of `color` under the view, offset down by `depth`.
/// When `pressed`, the content drops onto the block and the block disappears,
/// which reads as a physical button being pushed in.
struct BlockShadow<S: InsettableShape>: ViewModifier {
    let shape: S
    let color: Color
    let depth: CGFloat
    let pressed: Bool

    func body(content: Content) -> some View {
        content
            .background(shape.fill(color).offset(y: pressed ? 0 : depth))
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)
            .animation(Theme.Motion.press, value: pressed)
    }
}

public extension View {
    /// Toy-block depth under any shape. `depth` is a `Theme.Elevation` token.
    func blockShadow<S: InsettableShape>(_ shape: S, color: Color, depth: CGFloat, pressed: Bool = false) -> some View {
        modifier(BlockShadow(shape: shape, color: color, depth: depth, pressed: pressed))
    }
}

// MARK: - Button styles

/// Filled Grape pill. One per screen: the thing you most want the user to do.
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Theme.Typography.label)
            .foregroundStyle(Theme.Color.onAccentPrimary)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.controlHeight)
            .padding(.horizontal, Theme.Spacing.xl)
            .background(Capsule().fill(Theme.Color.accentPrimary))
            .blockShadow(Capsule(), color: Theme.Color.accentPrimaryDepth, depth: Theme.Elevation.control, pressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : Theme.Opacity.disabled)
    }
}

/// Surface-coloured pill. Swap / Skip / "Not right now" inside the app.
public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Theme.Typography.labelCompact)
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.controlHeight)
            .padding(.horizontal, Theme.Spacing.lg)
            .background(Capsule().fill(Theme.Color.surface))
            .blockShadow(Capsule(), color: Theme.Color.surfaceDepth, depth: Theme.Elevation.control, pressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : Theme.Opacity.disabled)
    }
}

/// Danger fill. Only for irreversible actions (remove an app, reset data).
/// Never for "Emergency override"; that is a text button by design.
public struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Theme.Typography.labelCompact)
            .foregroundStyle(Theme.Color.onDanger)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.controlHeight)
            .padding(.horizontal, Theme.Spacing.lg)
            .background(Capsule().fill(Theme.Color.danger))
            .blockShadow(Capsule(), color: Theme.Color.dangerDepth, depth: Theme.Elevation.control, pressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : Theme.Opacity.disabled)
    }
}

/// Low-emphasis underlined text. Escape hatches and footnote actions.
public struct TextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Theme.Typography.bodyS)
            .underline()
            .foregroundStyle(Theme.Color.textSecondary)
            .frame(minHeight: Theme.Size.minimumTapTarget)
            .padding(.horizontal, Theme.Spacing.xs)
            .contentShape(Rectangle())
            .opacity(!isEnabled ? Theme.Opacity.disabled : (configuration.isPressed ? Theme.Opacity.pressedText : 1))
            .animation(Theme.Motion.press, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var nudgePrimary: PrimaryButtonStyle { .init() }
}
public extension ButtonStyle where Self == SecondaryButtonStyle {
    static var nudgeSecondary: SecondaryButtonStyle { .init() }
}
public extension ButtonStyle where Self == DestructiveButtonStyle {
    static var nudgeDestructive: DestructiveButtonStyle { .init() }
}
public extension ButtonStyle where Self == TextButtonStyle {
    static var nudgeText: TextButtonStyle { .init() }
}
