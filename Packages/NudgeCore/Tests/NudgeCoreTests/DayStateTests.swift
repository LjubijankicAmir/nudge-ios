import Foundation
import Testing

@testable import NudgeCore

@Suite("Day state")
struct DayStateTests {
    @Test("worst outcome wins when a day sees several (SPEC §3)")
    func precedence() {
        #expect(DayState.worst(.clean, .earned) == .earned)
        #expect(DayState.worst(.earned, .incomplete) == .incomplete)
        #expect(DayState.worst(.incomplete, .rejected) == .rejected)
        #expect(DayState.worst(.rejected, .overridden) == .overridden)
        #expect(DayState.worst(.overridden, .clean) == .overridden)
    }

    @Test("any real outcome beats noData")
    func noDataLosesToEverything() {
        for state in DayState.allCases where state != .noData {
            #expect(DayState.worst(.noData, state) == state)
        }
    }

    @Test("precedence does not depend on argument order")
    func commutative() {
        for a in DayState.allCases {
            for b in DayState.allCases {
                #expect(DayState.worst(a, b) == DayState.worst(b, a))
            }
        }
    }

    @Test("clean and earned days extend the streak (SPEC F6.2)")
    func extendingStates() {
        #expect(DayState.clean.streakEffect == .extends)
        #expect(DayState.earned.streakEffect == .extends)
    }

    @Test("rejecting the lock or overriding breaks the streak (SPEC F6.3)")
    func breakingStates() {
        #expect(DayState.rejected.streakEffect == .breaks)
        #expect(DayState.overridden.streakEffect == .breaks)
    }

    @Test("an unfinished protocol neither extends nor breaks (SPEC Q1, assumed)")
    func incompleteHolds() {
        #expect(DayState.incomplete.streakEffect == .holds)
    }

    @Test("noData is ignored by the streak (SPEC F6.6)")
    func noDataIgnored() {
        #expect(DayState.noData.streakEffect == .ignored)
    }

    @Test("only clean days count toward the hero metric (SPEC F6.4)")
    func cleanDayMetric() {
        #expect(DayState.clean.isCleanDay)
        #expect(!DayState.earned.isCleanDay)
    }

    @Test("round-trips through Codable", arguments: DayState.allCases)
    func codableRoundTrip(state: DayState) throws {
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(DayState.self, from: data) == state)
    }
}

@Suite("Day record")
struct DayRecordTests {
    @Test("folding outcomes keeps the worst one")
    func foldsToWorst() {
        var record = DayRecord(day: CalendarDay(year: 2026, month: 9, day: 22))
        record.record(.clean)
        #expect(record.state == .clean)
        record.record(.earned)
        #expect(record.state == .earned)
        record.record(.rejected)
        #expect(record.state == .rejected)
        // A better outcome later must not improve the day.
        record.record(.clean)
        #expect(record.state == .rejected)
    }
}
