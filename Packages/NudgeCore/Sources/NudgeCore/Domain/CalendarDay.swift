import Foundation

/// A calendar date with no time component, used as the key for day records.
///
/// Storing year/month/day rather than a `Date` keeps persisted history stable
/// across time zone changes and makes streak logic testable without wall-clock
/// arithmetic.
public struct CalendarDay: Codable, Sendable, Hashable, Comparable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    public func date(in calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// The day `offset` days away, or `nil` if the calendar cannot represent it.
    public func adding(days offset: Int, in calendar: Calendar) -> CalendarDay? {
        guard let start = date(in: calendar),
              let shifted = calendar.date(byAdding: .day, value: offset, to: start)
        else { return nil }
        return CalendarDay(date: shifted, calendar: calendar)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
