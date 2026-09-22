import Foundation

/// Every failure the app can actually hit. v1 is entirely on-device, so there
/// are no networking or authentication cases here.
public enum NudgeError: Error, Sendable, Hashable {
    /// The user declined Screen Time authorization, or it was revoked.
    case screenTimeAuthorizationDenied
    /// The Family Controls entitlement is missing from the build.
    case screenTimeUnavailable
    /// The App Group container could not be resolved — almost always a missing
    /// or mismatched App Group capability on the target.
    case appGroupUnavailable(identifier: String)
    case storageReadFailed(file: String)
    case storageWriteFailed(file: String)
}

extension NudgeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .screenTimeAuthorizationDenied:
            "Nudge needs Screen Time access to watch your app usage."
        case .screenTimeUnavailable:
            "Screen Time features aren't available in this build."
        case .appGroupUnavailable(let identifier):
            "Couldn't open shared storage (\(identifier))."
        case .storageReadFailed(let file):
            "Couldn't read saved data (\(file))."
        case .storageWriteFailed(let file):
            "Couldn't save your data (\(file))."
        }
    }
}
