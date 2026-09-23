import Foundation
import NudgeCore
import Observation

/// Owns the navigation stack.
///
/// Kept separate from any screen's view model so that navigation can be driven
/// from outside the view hierarchy — specifically by a deep link, or by finding
/// a pending escape protocol in shared storage at launch.
@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []

    func navigate(to route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Replaces the stack with a single destination. Used for deep links, where
    /// pushing onto whatever the user last looked at would be wrong.
    func present(_ route: Route) {
        path = [route]
    }

    /// - Returns: whether the URL was understood.
    @discardableResult
    func handle(deepLink url: URL) -> Bool {
        guard let route = Route(deepLink: url) else { return false }
        present(route)
        return true
    }
}
