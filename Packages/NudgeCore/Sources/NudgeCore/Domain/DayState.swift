import Foundation

/// The single state a calendar day can end up in. See `docs/SPEC.md` §3.
public enum DayState: String, Codable, Sendable, CaseIterable, Hashable {
    /// Threshold never reached.
    case clean
    /// Threshold reached, lock accepted, every protocol task completed.
    case earned
    /// Threshold reached, lock accepted, protocol not finished.
    case incomplete
    /// Threshold reached, the user rejected the lock.
    case rejected
    /// An emergency unlock was used.
    case overridden
    /// Before first use, or monitoring unavailable.
    case noData

    /// Ordering used to resolve a day with several outcomes.
    /// SPEC §3: the worst outcome wins.
    var severity: Int {
        switch self {
        case .noData: 0
        case .clean: 1
        case .earned: 2
        case .incomplete: 3
        case .rejected: 4
        case .overridden: 5
        }
    }

    /// Resolves a day that saw more than one outcome.
    public static func worst(_ lhs: DayState, _ rhs: DayState) -> DayState {
        lhs.severity >= rhs.severity ? lhs : rhs
    }

    /// The streak measures whether the user stayed inside the lock, not whether
    /// they worked through the whole protocol. Task completion is self-reported
    /// and unverifiable — a user can tap through every step in seconds — so
    /// rewarding it would be rewarding a number the app cannot trust.
    /// Accepting the lock is the behaviour that is actually observable, and the
    /// behaviour worth reinforcing. (SPEC Q1, resolved.)
    public var streakEffect: StreakEffect {
        switch self {
        case .clean, .earned, .incomplete: .extends
        case .rejected, .overridden: .breaks
        case .noData: .ignored
        }
    }

    /// True only for days the hero metric counts (SPEC F6.4).
    public var isCleanDay: Bool { self == .clean }
}

/// What a day does to the running streak.
public enum StreakEffect: Sendable, Hashable {
    /// Adds one to the streak.
    case extends
    /// Resets the streak to zero.
    case breaks
    /// Not counted at all.
    case ignored
}
