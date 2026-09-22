import Foundation

/// One task offered during an escape protocol.
///
/// Named `ResetTask` rather than `Task` to avoid colliding with Swift
/// concurrency's `Task`.
public struct ResetTask: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var title: String
    public var tier: TaskTier
    /// Disabled tasks are never served (SPEC F8.3).
    public var isEnabled: Bool
    /// User-authored tasks can be edited and deleted; defaults cannot (F8.5).
    public let isCustom: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        tier: TaskTier,
        isEnabled: Bool = true,
        isCustom: Bool = false
    ) {
        self.id = id
        self.title = title
        self.tier = tier
        self.isEnabled = isEnabled
        self.isCustom = isCustom
    }
}
