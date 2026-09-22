import Foundation

/// A period during which the monitored apps are shielded (SPEC F3).
public struct LockSession: Codable, Sendable, Hashable, Identifiable {
    /// How a lock session finished.
    public enum Outcome: String, Codable, Sendable, Hashable {
        /// Ran to the end of its cooldown.
        case expired
        /// The user declined the lock (F3.6).
        case rejected
        /// Ended early by an emergency unlock (F5.5).
        case overridden
    }

    public let id: UUID
    public let startedAt: Date
    /// Fixed at creation and independent of task completion (F3.3, F3.4).
    public let duration: TimeInterval
    public var outcome: Outcome?

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        duration: TimeInterval,
        outcome: Outcome? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.duration = duration
        self.outcome = outcome
    }

    public var endsAt: Date { startedAt.addingTimeInterval(duration) }

    public func isActive(at moment: Date) -> Bool {
        outcome == nil && moment < endsAt
    }

    public func remaining(at moment: Date) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(moment))
    }

    /// Total cooldown derived from the nominal tier durations (SPEC §5).
    public static var defaultDuration: TimeInterval {
        TaskTier.allCases.reduce(0) { $0 + $1.nominalDuration }
    }
}

/// One step of an escape protocol: a task drawn from a tier, and what became of it.
public struct ProtocolStep: Codable, Sendable, Hashable {
    public enum Outcome: String, Codable, Sendable, Hashable {
        case pending
        case completed
        /// Skipped, so this tier is not completed and the day cannot be `earned` (F4.6).
        case skipped
    }

    public let tier: TaskTier
    public var taskID: UUID
    public var outcome: Outcome

    public init(tier: TaskTier, taskID: UUID, outcome: Outcome = .pending) {
        self.tier = tier
        self.taskID = taskID
        self.outcome = outcome
    }
}

/// How the user felt at the end of a protocol (SPEC F4.7). One tap, not a journal.
public enum Reflection: String, Codable, Sendable, CaseIterable, Hashable {
    case muchBetter
    case better
    case same
    case worse
}

/// A run through the escape protocol, tied to the lock session that prompted it.
public struct ProtocolSession: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let lockSessionID: UUID
    public let startedAt: Date
    public var steps: [ProtocolStep]
    public var reflection: Reflection?

    public init(
        id: UUID = UUID(),
        lockSessionID: UUID,
        startedAt: Date,
        steps: [ProtocolStep] = [],
        reflection: Reflection? = nil
    ) {
        self.id = id
        self.lockSessionID = lockSessionID
        self.startedAt = startedAt
        self.steps = steps
        self.reflection = reflection
    }

    /// Complete only when one task from every tier has been completed (F4.5).
    public var isComplete: Bool {
        TaskTier.allCases.allSatisfy { tier in
            steps.contains { $0.tier == tier && $0.outcome == .completed }
        }
    }
}
