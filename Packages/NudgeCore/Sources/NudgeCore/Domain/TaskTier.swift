import Foundation

/// The escalating scale of an escape-protocol task (SPEC F8.1).
///
/// The protocol serves one task per tier, in ascending order.
public enum TaskTier: String, Codable, Sendable, CaseIterable, Comparable {
    /// Instant physical reset — cold water, a stretch, stepping outside.
    case instantReset
    /// A small, finishable win — brush teeth, fold clothes, tidy a surface.
    case smallWin
    /// A longer activity — a walk, a workout, a study block.
    case longerActivity

    public var order: Int {
        switch self {
        case .instantReset: 0
        case .smallWin: 1
        case .longerActivity: 2
        }
    }

    /// Nominal time this tier represents. Used only to derive the lock duration
    /// (SPEC §5) — it never gates task completion, which is immediate (F4.4).
    public var nominalDuration: TimeInterval {
        switch self {
        case .instantReset: 2 * 60
        case .smallWin: 10 * 60
        case .longerActivity: 20 * 60
        }
    }

    /// Tiers in the order the protocol serves them.
    public static var ascending: [TaskTier] {
        allCases.sorted()
    }

    public static func < (lhs: TaskTier, rhs: TaskTier) -> Bool {
        lhs.order < rhs.order
    }
}
