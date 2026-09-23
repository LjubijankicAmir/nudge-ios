import Foundation
import NudgeCore

/// Every destination the app can push.
///
/// `nonisolated` because the app target defaults to main-actor isolation
/// (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), and a route is a plain value:
/// parsing one has nothing to do with the main actor, and a notification handler
/// may well want to do it off it. Navigation is value-driven: a screen
/// appends a `Route` rather than constructing the next view itself.
nonisolated enum Route: Hashable {
    case escapeProtocol
    case settings
    case taskLibrary
    case dayDetail(CalendarDay)
    /// Reachable only from the debug menu; harmless in release.
    case designSystemGallery
}

nonisolated extension Route {
    /// Parses a `nudge://` deep link.
    ///
    /// The entry point exists because the interception flow starts *outside* the
    /// app: the user is on a shield screen, not in Nudge. See `AppRouter`.
    init?(deepLink url: URL) {
        guard url.scheme == Route.urlScheme else { return nil }
        switch url.host() {
        case "protocol": self = .escapeProtocol
        case "settings": self = .settings
        default: return nil
        }
    }

    /// Must match `CFBundleURLSchemes` in Info.plist.
    static let urlScheme = "nudge"
}
