import Foundation
import NudgeCore
import Testing

/// Guards the App Group capability, which is easy to lose in a project-file
/// merge and fails silently: the app and its extensions simply stop seeing each
/// other's data. Hosted by the app target, so it runs with the app's entitlements.
@Suite("App Group")
struct AppGroupTests {
    @Test("the shared container resolves")
    func containerResolves() throws {
        let url = try AppGroup.requireContainerURL()
        #expect(url.path().isEmpty == false)
    }

    @Test("the shared UserDefaults suite opens")
    func settingsSuiteOpens() throws {
        let store = try UserDefaultsSettingsStore.appGroup()
        #expect(store.dailyThreshold == SettingsDefaults.dailyThreshold)
    }

    @Test("a value written to the shared container reads back")
    func sharedContainerRoundTrip() throws {
        let store = try JSONFileStore.appGroup()
        let file = StoreFile("app-group-smoke-test")
        defer { try? store.delete(file) }

        let written = [DayRecord(day: CalendarDay(year: 2026, month: 9, day: 22), state: .clean)]
        try store.save(written, to: file)
        #expect(try store.load([DayRecord].self, from: file) == written)
    }
}
