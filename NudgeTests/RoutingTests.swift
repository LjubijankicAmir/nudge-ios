import Foundation
import NudgeCore
import Testing

@testable import Nudge

@Suite("Deep links")
struct DeepLinkTests {
    @Test("nudge://protocol opens the escape protocol")
    func protocolLink() throws {
        #expect(Route(deepLink: try #require(URL(string: "nudge://protocol"))) == .escapeProtocol)
    }

    @Test("nudge://settings opens settings")
    func settingsLink() throws {
        #expect(Route(deepLink: try #require(URL(string: "nudge://settings"))) == .settings)
    }

    @Test("an unknown host is rejected rather than guessed at")
    func unknownHost() throws {
        #expect(Route(deepLink: try #require(URL(string: "nudge://banana"))) == nil)
    }

    @Test("a foreign scheme is rejected", arguments: [
        "https://nudge.app/protocol", "otherapp://protocol", "protocol",
    ])
    func foreignScheme(raw: String) throws {
        #expect(Route(deepLink: try #require(URL(string: raw))) == nil)
    }
}

@Suite("App router")
@MainActor
struct AppRouterTests {
    @Test("starts at the root")
    func startsEmpty() {
        #expect(AppRouter().path.isEmpty)
    }

    @Test("navigating pushes onto the stack")
    func pushes() {
        let router = AppRouter()
        router.navigate(to: .settings)
        router.navigate(to: .taskLibrary)
        #expect(router.path == [.settings, .taskLibrary])
    }

    @Test("a deep link replaces the stack rather than pushing onto it")
    func deepLinkReplaces() throws {
        let router = AppRouter()
        router.navigate(to: .settings)
        router.navigate(to: .taskLibrary)

        #expect(router.handle(deepLink: try #require(URL(string: "nudge://protocol"))))
        // Arriving from a shield must not leave the user's previous screens
        // stacked underneath.
        #expect(router.path == [.escapeProtocol])
    }

    @Test("an unrecognised link leaves navigation untouched")
    func badLinkIsIgnored() throws {
        let router = AppRouter()
        router.navigate(to: .settings)
        #expect(router.handle(deepLink: try #require(URL(string: "nudge://banana"))) == false)
        #expect(router.path == [.settings])
    }

    @Test("popToRoot clears the stack")
    func popToRoot() {
        let router = AppRouter()
        router.navigate(to: .settings)
        router.popToRoot()
        #expect(router.path.isEmpty)
    }
}
