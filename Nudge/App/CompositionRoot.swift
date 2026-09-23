import Foundation
import NudgeCore

/// Builds the object graph once, at launch, and hands dependencies to whoever
/// needs them through initialisers.
///
/// No DI container by design: this is a plain object, checked by the compiler,
/// with no runtime "dependency not registered" failure mode.
@MainActor
final class CompositionRoot {
    let clock: any AppClock
    let settings: any SettingsStore
    let store: any FileStore
    let screenTime: any ScreenTimeService
    let router: AppRouter

    /// - Throws: `NudgeError.appGroupUnavailable` when the App Group capability
    ///   is missing from the target. There is no sensible degraded mode — the
    ///   app cannot talk to its extensions — so this surfaces as a failure screen.
    init() throws {
        clock = SystemClock()
        settings = try UserDefaultsSettingsStore.appGroup()
        store = try JSONFileStore.appGroup()
        screenTime = Self.makeScreenTimeService()
        router = AppRouter()
    }

    /// Screen Time does not work in the Simulator, and the Family Controls
    /// entitlement is not yet approved for distribution, so everything is built
    /// against the fake for now. Swapping in the live implementation is a change
    /// to this one function.
    private static func makeScreenTimeService() -> any ScreenTimeService {
        FakeScreenTimeService(initialStatus: .notDetermined)
    }
}
