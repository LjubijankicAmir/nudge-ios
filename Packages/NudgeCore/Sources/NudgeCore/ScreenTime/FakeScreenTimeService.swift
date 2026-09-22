import Foundation

/// In-memory `ScreenTimeService` for the Simulator, previews and tests.
///
/// `simulateThresholdReached()` stands in for the monitor extension firing, so
/// the full interception flow can be exercised without a device.
public actor FakeScreenTimeService: ScreenTimeService {
    private var status: ScreenTimeAuthorizationStatus
    private var shielded = false
    private var monitoring = false
    private var threshold: TimeInterval?
    private var continuation: AsyncStream<ScreenTimeEvent>.Continuation?
    private let stream: AsyncStream<ScreenTimeEvent>

    /// - Parameter initialStatus: start `.approved` to skip the permission screen
    ///   while working on later flows.
    public init(initialStatus: ScreenTimeAuthorizationStatus = .notDetermined) {
        self.status = initialStatus
        var escapedContinuation: AsyncStream<ScreenTimeEvent>.Continuation?
        self.stream = AsyncStream { escapedContinuation = $0 }
        self.continuation = escapedContinuation
    }

    nonisolated public var events: AsyncStream<ScreenTimeEvent> { stream }

    public func authorizationStatus() async -> ScreenTimeAuthorizationStatus { status }

    public func requestAuthorization() async throws {
        guard status != .denied else { throw NudgeError.screenTimeAuthorizationDenied }
        status = .approved
    }

    public func startMonitoring(dailyThreshold: TimeInterval) async throws {
        guard status == .approved else { throw NudgeError.screenTimeAuthorizationDenied }
        monitoring = true
        threshold = dailyThreshold
    }

    public func stopMonitoring() async throws {
        monitoring = false
        threshold = nil
    }

    public func applyShield() async throws {
        shielded = true
    }

    public func removeShield() async throws {
        shielded = false
        continuation?.yield(.shieldRemoved)
    }

    public func isShielded() async -> Bool { shielded }

    // MARK: - Test and Simulator affordances

    /// Stands in for the monitor extension firing a threshold event.
    public func simulateThresholdReached() {
        guard monitoring else { return }
        continuation?.yield(.thresholdReached)
    }

    public func setAuthorizationStatus(_ newStatus: ScreenTimeAuthorizationStatus) {
        status = newStatus
    }

    public var isMonitoring: Bool { monitoring }
    public var configuredThreshold: TimeInterval? { threshold }
}
