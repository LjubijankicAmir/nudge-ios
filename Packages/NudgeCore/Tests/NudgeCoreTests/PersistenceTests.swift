import Testing
import Foundation
@testable import NudgeCore

@Suite("JSON file store")
final class JSONFileStoreTests: Sendable {
    // Swift Testing builds a fresh instance per test, so each one gets its own
    // directory and cleans up after itself.
    private let directory: URL
    private let store: JSONFileStore

    init() {
        directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        store = JSONFileStore(directory: directory)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test("returns nil for a file that was never written")
    func missingFileIsNil() throws {
        #expect(try store.load([DayRecord].self, from: .dayRecords) == nil)
    }

    @Test("round-trips day records")
    func roundTrip() throws {
        let records = [
            DayRecord(day: CalendarDay(year: 2026, month: 9, day: 21), state: .clean),
            DayRecord(day: CalendarDay(year: 2026, month: 9, day: 22), state: .earned,
                      emergencyUnlocksUsed: 1, reflections: [.better]),
        ]
        try store.save(records, to: .dayRecords)
        #expect(try store.load([DayRecord].self, from: .dayRecords) == records)
    }

    @Test("a later save replaces the earlier one")
    func overwrite() throws {
        try store.save([DayRecord(day: CalendarDay(year: 2026, month: 9, day: 1), state: .clean)],
                       to: .dayRecords)
        try store.save([DayRecord(day: CalendarDay(year: 2026, month: 9, day: 2), state: .rejected)],
                       to: .dayRecords)
        let loaded = try store.load([DayRecord].self, from: .dayRecords)
        #expect(loaded?.count == 1)
        #expect(loaded?.first?.state == .rejected)
    }

    @Test("separate files do not collide")
    func filesAreIndependent() throws {
        try store.save([ResetTask(title: "Cold water", tier: .instantReset)], to: .taskLibrary)
        try store.save([DayRecord(day: CalendarDay(year: 2026, month: 9, day: 1))], to: .dayRecords)
        #expect(try store.load([ResetTask].self, from: .taskLibrary)?.count == 1)
        #expect(try store.load([DayRecord].self, from: .dayRecords)?.count == 1)
    }

    @Test("deleting removes the document")
    func delete() throws {
        try store.save([DayRecord(day: CalendarDay(year: 2026, month: 9, day: 1))], to: .dayRecords)
        try store.delete(.dayRecords)
        #expect(try store.load([DayRecord].self, from: .dayRecords) == nil)
    }

    @Test("deleting a file that is not there is not an error")
    func deleteMissingIsNoop() throws {
        try store.delete(.lockSessions)
    }

    @Test("malformed JSON surfaces as a read failure")
    func corruptFile() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appending(path: "day-records.json"))

        #expect(throws: NudgeError.storageReadFailed(file: "day-records")) {
            try store.load([DayRecord].self, from: .dayRecords)
        }
    }
}

@Suite("Settings store")
struct SettingsStoreTests {
    private func makeStore() -> (UserDefaultsSettingsStore, String) {
        let suite = "test.\(UUID().uuidString)"
        return (UserDefaultsSettingsStore(suiteName: suite), suite)
    }

    @Test("falls back to the documented defaults")
    func defaults() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.dailyThreshold == SettingsDefaults.dailyThreshold)
        #expect(store.emergencyUnlocksPerWeek == SettingsDefaults.emergencyUnlocksPerWeek)
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test("persists what it is given")
    func persists() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        store.setDailyThreshold(3600)
        store.setHasCompletedOnboarding(true)
        store.setEmergencyUnlocksPerWeek(5)
        #expect(store.dailyThreshold == 3600)
        #expect(store.hasCompletedOnboarding)
        #expect(store.emergencyUnlocksPerWeek == 5)
    }
}
