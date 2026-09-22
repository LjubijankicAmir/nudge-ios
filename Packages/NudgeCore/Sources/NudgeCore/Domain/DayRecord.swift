import Foundation

/// Everything recorded for one calendar day. The unit the calendar renders and
/// the streak is computed from.
public struct DayRecord: Codable, Sendable, Hashable, Identifiable {
    public let day: CalendarDay
    public var state: DayState
    public var lockSessionIDs: [UUID]
    public var emergencyUnlocksUsed: Int
    public var reflections: [Reflection]

    public var id: CalendarDay { day }

    public init(
        day: CalendarDay,
        state: DayState = .noData,
        lockSessionIDs: [UUID] = [],
        emergencyUnlocksUsed: Int = 0,
        reflections: [Reflection] = []
    ) {
        self.day = day
        self.state = state
        self.lockSessionIDs = lockSessionIDs
        self.emergencyUnlocksUsed = emergencyUnlocksUsed
        self.reflections = reflections
    }

    /// Folds a new outcome into the day, keeping the worst (SPEC §3 precedence).
    public mutating func record(_ outcome: DayState) {
        state = DayState.worst(state, outcome)
    }
}
