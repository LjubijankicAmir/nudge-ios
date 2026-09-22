import Foundation

/// Small scalar settings. Lives in the App Group `UserDefaults` suite so the
/// extensions can read the threshold without opening a JSON document.
public protocol SettingsStore: Sendable {
    var dailyThreshold: TimeInterval { get }
    var hasCompletedOnboarding: Bool { get }
    var emergencyUnlocksPerWeek: Int { get }

    func setDailyThreshold(_ value: TimeInterval)
    func setHasCompletedOnboarding(_ value: Bool)
    func setEmergencyUnlocksPerWeek(_ value: Int)
}

public enum SettingsDefaults {
    /// SPEC §5: presets are 30 min / 1 h / 2 h.
    public static let dailyThreshold: TimeInterval = 30 * 60
    public static let emergencyUnlocksPerWeek = 2
}

public struct UserDefaultsSettingsStore: SettingsStore {
    private enum Key {
        static let dailyThreshold = "settings.dailyThreshold"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let emergencyUnlocksPerWeek = "settings.emergencyUnlocksPerWeek"
    }

    /// The suite *name* is stored rather than the `UserDefaults` instance, which
    /// is not `Sendable`. Resolving per access is cheap — `UserDefaults` caches
    /// suite instances internally and is documented as thread-safe.
    private let suiteName: String

    public init(suiteName: String) {
        self.suiteName = suiteName
    }

    /// The suite shared with the extensions.
    public static func appGroup() throws -> UserDefaultsSettingsStore {
        guard UserDefaults(suiteName: AppGroup.identifier) != nil else {
            throw NudgeError.appGroupUnavailable(identifier: AppGroup.identifier)
        }
        return UserDefaultsSettingsStore(suiteName: AppGroup.identifier)
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public var dailyThreshold: TimeInterval {
        defaults.object(forKey: Key.dailyThreshold) as? TimeInterval
            ?? SettingsDefaults.dailyThreshold
    }

    public var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: Key.hasCompletedOnboarding)
    }

    public var emergencyUnlocksPerWeek: Int {
        defaults.object(forKey: Key.emergencyUnlocksPerWeek) as? Int
            ?? SettingsDefaults.emergencyUnlocksPerWeek
    }

    public func setDailyThreshold(_ value: TimeInterval) {
        defaults.set(value, forKey: Key.dailyThreshold)
    }

    public func setHasCompletedOnboarding(_ value: Bool) {
        defaults.set(value, forKey: Key.hasCompletedOnboarding)
    }

    public func setEmergencyUnlocksPerWeek(_ value: Int) {
        defaults.set(value, forKey: Key.emergencyUnlocksPerWeek)
    }
}
