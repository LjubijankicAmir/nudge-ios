import Foundation

/// The App Group shared by the app and all three extensions.
///
/// This container is the only channel between them: they are separate processes
/// and `UserDefaults.standard` is *not* shared across them.
public enum AppGroup {
    public static let identifier = "group.app.nudge"

    /// The shared container directory, or `nil` when the App Group capability is
    /// missing from the calling target.
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    public static func requireContainerURL() throws -> URL {
        guard let url = containerURL else {
            throw NudgeError.appGroupUnavailable(identifier: identifier)
        }
        return url
    }
}
