import Foundation

public enum ScreenTimeAuthorizationStatus: String, Sendable, Hashable {
    case notDetermined
    case denied
    case approved
}

/// Something the Screen Time machinery reports back to the app.
///
/// In the real implementation these originate in the monitor extension, which
/// writes to the App Group; the app observes. The fake emits them directly.
public enum ScreenTimeEvent: Sendable, Hashable {
    /// Daily usage across the monitored apps crossed the threshold.
    case thresholdReached
    /// The shield was lifted, by expiry or override.
    case shieldRemoved
}

/// The app's whole view of the Screen Time APIs.
///
/// Abstracted for one very practical reason: **Screen Time does not work in the
/// Simulator, and the distribution entitlement takes time to be approved.**
/// Every screen and the whole protocol flow are built against this protocol so
/// development never blocks on a device or on Apple.
public protocol ScreenTimeService: Sendable {
    func authorizationStatus() async -> ScreenTimeAuthorizationStatus
    func requestAuthorization() async throws

    /// Begin watching the selected apps for the given daily total (SPEC F2.1).
    func startMonitoring(dailyThreshold: TimeInterval) async throws
    func stopMonitoring() async throws

    /// Shield every monitored app (F3.1, F2.4 — all of them, not just the one used).
    func applyShield() async throws
    func removeShield() async throws
    func isShielded() async -> Bool

    var events: AsyncStream<ScreenTimeEvent> { get }
}
