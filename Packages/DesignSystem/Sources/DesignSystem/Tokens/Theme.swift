import SwiftUI

/// Root namespace for every design token in Nudge.
/// Direction: "Arcade" — saturated fills, toy-block depth, SF Pro Rounded.
public enum Theme {}

// MARK: - Color

public extension Theme {
    /// Semantic colors. Every value is an Asset Catalog color set with explicit
    /// Light and Dark variants; nothing here is hard-coded.
    enum Color {
        private static func asset(_ name: String) -> SwiftUI.Color {
            SwiftUI.Color(name, bundle: .module)
        }

        // Backgrounds
        public static let backgroundPrimary = asset("backgroundPrimary")
        public static let backgroundSecondary = asset("backgroundSecondary")
        public static let surface = asset("surface")
        public static let surfaceDepth = asset("surfaceDepth")
        public static let divider = asset("divider")

        // Accents (each fill has an "on" text color and a "depth" block-shadow tint)
        public static let accentPrimary = asset("accentPrimary")
        public static let accentPrimaryDepth = asset("accentPrimaryDepth")
        public static let onAccentPrimary = asset("onAccentPrimary")

        public static let accentSecondary = asset("accentSecondary")
        public static let accentSecondaryDepth = asset("accentSecondaryDepth")
        public static let onAccentSecondary = asset("onAccentSecondary")

        // Feedback
        public static let reward = asset("reward")
        public static let rewardDepth = asset("rewardDepth")
        public static let onReward = asset("onReward")

        public static let success = asset("success")
        public static let successDepth = asset("successDepth")
        public static let onSuccess = asset("onSuccess")

        public static let warning = asset("warning")
        public static let warningDepth = asset("warningDepth")
        public static let onWarning = asset("onWarning")

        public static let danger = asset("danger")
        public static let dangerDepth = asset("dangerDepth")
        public static let onDanger = asset("onDanger")

        public static let info = asset("info")
        public static let infoDepth = asset("infoDepth")
        public static let onInfo = asset("onInfo")

        // Text tiers
        public static let textPrimary = asset("textPrimary")
        public static let textSecondary = asset("textSecondary")
        public static let textTertiary = asset("textTertiary")

        // Day states. Positive states alias feedback colors so the calendar
        // and the rest of the app always agree on what "good" looks like.
        public static let dayClean = reward
        public static let onDayClean = onReward
        public static let dayEarned = success
        public static let onDayEarned = onSuccess
        public static let dayIncomplete = info
        public static let onDayIncomplete = onInfo
        public static let dayRejected = asset("dayRejected")
        public static let onDayRejected = asset("onDayRejected")
        public static let dayOverridden = asset("dayOverridden")
        public static let onDayOverridden = asset("onDayOverridden")
        public static let dayNoData = asset("dayNoData")
        public static let onDayNoData = asset("onDayNoData")
        public static let dayTodayRing = accentPrimary

        /// Names of every color set in the catalog (used by the asset test).
        static let allAssetNames: [String] = [
            "backgroundPrimary", "backgroundSecondary", "surface", "surfaceDepth", "divider",
            "accentPrimary", "accentPrimaryDepth", "onAccentPrimary",
            "accentSecondary", "accentSecondaryDepth", "onAccentSecondary",
            "reward", "rewardDepth", "onReward", "success", "successDepth", "onSuccess",
            "warning", "warningDepth", "onWarning", "danger", "dangerDepth", "onDanger",
            "info", "infoDepth", "onInfo", "textPrimary", "textSecondary", "textTertiary",
            "dayRejected", "onDayRejected", "dayOverridden", "onDayOverridden", "dayNoData", "onDayNoData",
        ]
    }
}

// MARK: - Spacing

public extension Theme {
    /// 4pt base unit.
    enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 40
    }
}

// MARK: - Radius

public extension Theme {
    /// Shape language: everything rounded, nothing square, controls are full pills.
    enum Radius {
        public static let chip: CGFloat = 12
        public static let tile: CGFloat = 14
        public static let cardSmall: CGFloat = 22
        public static let card: CGFloat = 28
        public static let pill: CGFloat = 999
    }
}

// MARK: - Elevation

public extension Theme {
    /// Depth is a hard, offset "block" under the shape, not a blurred shadow.
    /// The value is the block's height in points; pressing collapses it to zero.
    enum Elevation {
        public static let none: CGFloat = 0
        public static let chip: CGFloat = 4
        public static let control: CGFloat = 6
        public static let card: CGFloat = 6
        public static let hero: CGFloat = 8
    }
}

// MARK: - Size & stroke

public extension Theme {
    enum Size {
        public static let controlHeight: CGFloat = 56
        public static let controlHeightCompact: CGFloat = 44
        public static let minimumTapTarget: CGFloat = 44
        public static let iconCircle: CGFloat = 44
        public static let iconCircleLarge: CGFloat = 52
        public static let dayCell: CGFloat = 40
        public static let progressBarHeight: CGFloat = 12
        public static let progressSegmentHeight: CGFloat = 8
        public static let cooldownRing: CGFloat = 132
    }

    enum Stroke {
        public static let ring: CGFloat = 2.5
        public static let cooldownRing: CGFloat = 10
    }

    enum Opacity {
        public static let disabled: Double = 0.4
        public static let pressedText: Double = 0.6
        public static let subtleOnAccent: Double = 0.18
    }
}

// MARK: - Motion

public extension Theme {
    /// Springs only. No bounce beyond a single overshoot, no elastic easing.
    enum Motion {
        /// Button press / release.
        public static let press: Animation = .spring(response: 0.2, dampingFraction: 0.7)
        /// Elements appearing or changing value.
        public static let pop: Animation = .spring(response: 0.35, dampingFraction: 0.7)
        /// Stagger between calendar tiles when the grid appears.
        public static let staggerDelay: Double = 0.03
        /// Number count-up duration.
        public static let countUpDuration: Double = 0.6
    }
}
