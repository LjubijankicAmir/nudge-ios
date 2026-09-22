import Foundation
import Testing

@testable import NudgeCore

@Suite("Calendar day")
struct CalendarDayTests {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test("orders chronologically")
    func ordering() {
        #expect(CalendarDay(year: 2026, month: 1, day: 5) < CalendarDay(year: 2026, month: 2, day: 1))
        #expect(CalendarDay(year: 2025, month: 12, day: 31) < CalendarDay(year: 2026, month: 1, day: 1))
        #expect(CalendarDay(year: 2026, month: 9, day: 9) < CalendarDay(year: 2026, month: 9, day: 10))
    }

    @Test("adding days crosses month and year boundaries")
    func dayArithmetic() throws {
        let endOfMonth = CalendarDay(year: 2026, month: 9, day: 30)
        #expect(endOfMonth.adding(days: 1, in: utc) == CalendarDay(year: 2026, month: 10, day: 1))

        let newYearsEve = CalendarDay(year: 2026, month: 12, day: 31)
        #expect(newYearsEve.adding(days: 1, in: utc) == CalendarDay(year: 2027, month: 1, day: 1))

        #expect(
            CalendarDay(year: 2026, month: 3, day: 1).adding(days: -1, in: utc)
                == CalendarDay(year: 2026, month: 2, day: 28))
    }

    @Test("handles a leap day")
    func leapYear() {
        #expect(
            CalendarDay(year: 2028, month: 2, day: 28).adding(days: 1, in: utc)
                == CalendarDay(year: 2028, month: 2, day: 29))
    }

    @Test("round-trips through Date")
    func dateRoundTrip() throws {
        let day = CalendarDay(year: 2026, month: 9, day: 22)
        let date = try #require(day.date(in: utc))
        #expect(CalendarDay(date: date, calendar: utc) == day)
    }
}

@Suite("App clock")
struct AppClockTests {
    @Test("a fixed clock reports the day it was built from")
    func fixedClockToday() {
        let clock = FixedClock(day: CalendarDay(year: 2026, month: 9, day: 22))
        #expect(clock.today == CalendarDay(year: 2026, month: 9, day: 22))
    }

    @Test("advancing past midnight rolls the day over")
    func midnightRollover() {
        var clock = FixedClock(day: CalendarDay(year: 2026, month: 9, day: 22))
        clock.advance(by: 23 * 3600)
        #expect(clock.today == CalendarDay(year: 2026, month: 9, day: 22))
        clock.advance(by: 2 * 3600)
        #expect(clock.today == CalendarDay(year: 2026, month: 9, day: 23))
    }
}
