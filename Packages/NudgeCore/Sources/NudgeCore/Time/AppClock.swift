import Foundation

/// Source of "now" and of the calendar used for day arithmetic.
///
/// Named `AppClock` rather than `Clock` to avoid colliding with the standard
/// library's `Clock` protocol.
///
/// Everything that needs the current time takes one of these, so midnight
/// rollover and streak rules can be tested without waiting.
public protocol AppClock: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}

public extension AppClock {
    var today: CalendarDay { CalendarDay(date: now, calendar: calendar) }
}

/// The real clock. Used everywhere outside tests.
public struct SystemClock: AppClock {
    public var calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    public var now: Date { Date() }
}

/// A clock frozen at a chosen instant. Tests only.
public struct FixedClock: AppClock {
    public var now: Date
    public var calendar: Calendar

    public init(now: Date, calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.now = now
        self.calendar = calendar
    }

    /// Convenience for building a clock from a calendar day at midnight UTC.
    public init(day: CalendarDay, timeZone: TimeZone = TimeZone(identifier: "UTC")!) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.now = day.date(in: calendar) ?? Date(timeIntervalSince1970: 0)
    }

    public mutating func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}
