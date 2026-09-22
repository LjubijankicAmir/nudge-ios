import Foundation
import Testing

@testable import NudgeCore

@Suite("Fake screen time service")
struct FakeScreenTimeServiceTests {
    @Test("monitoring requires authorization")
    func monitoringNeedsAuthorization() async throws {
        let service = FakeScreenTimeService(initialStatus: .notDetermined)
        await #expect(throws: NudgeError.screenTimeAuthorizationDenied) {
            try await service.startMonitoring(dailyThreshold: 1800)
        }
    }

    @Test("a denied user cannot be granted by asking again")
    func deniedStaysDenied() async throws {
        let service = FakeScreenTimeService(initialStatus: .denied)
        await #expect(throws: NudgeError.screenTimeAuthorizationDenied) {
            try await service.requestAuthorization()
        }
        #expect(await service.authorizationStatus() == .denied)
    }

    @Test("authorizing then monitoring records the threshold")
    func startsMonitoring() async throws {
        let service = FakeScreenTimeService()
        try await service.requestAuthorization()
        try await service.startMonitoring(dailyThreshold: 1800)
        #expect(await service.isMonitoring)
        #expect(await service.configuredThreshold == 1800)
    }

    @Test("shield can be applied and removed")
    func shielding() async throws {
        let service = FakeScreenTimeService(initialStatus: .approved)
        #expect(await service.isShielded() == false)
        try await service.applyShield()
        #expect(await service.isShielded())
        try await service.removeShield()
        #expect(await service.isShielded() == false)
    }

    @Test("a simulated breach reaches the app as an event")
    func thresholdEventIsEmitted() async throws {
        let service = FakeScreenTimeService(initialStatus: .approved)
        try await service.startMonitoring(dailyThreshold: 1800)

        var iterator = service.events.makeAsyncIterator()
        await service.simulateThresholdReached()
        #expect(await iterator.next() == .thresholdReached)
    }

    @Test("no breach is emitted while monitoring is stopped")
    func noEventWithoutMonitoring() async throws {
        let service = FakeScreenTimeService(initialStatus: .approved)
        await service.simulateThresholdReached()
        try await service.startMonitoring(dailyThreshold: 1800)

        var iterator = service.events.makeAsyncIterator()
        await service.simulateThresholdReached()
        // The first, un-monitored call must not have been queued ahead of this one.
        #expect(await iterator.next() == .thresholdReached)
    }
}

@Suite("Lock session")
struct LockSessionTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("default cooldown is the sum of the tier durations (SPEC §5)")
    func defaultDuration() {
        #expect(LockSession.defaultDuration == 32 * 60)
    }

    @Test("is active until its cooldown elapses")
    func activeWindow() {
        let session = LockSession(startedAt: start, duration: 600)
        #expect(session.isActive(at: start))
        #expect(session.isActive(at: start.addingTimeInterval(599)))
        #expect(!session.isActive(at: start.addingTimeInterval(600)))
    }

    @Test("an ended session is never active, even inside its window")
    func outcomeEndsIt() {
        let session = LockSession(startedAt: start, duration: 600, outcome: .overridden)
        #expect(!session.isActive(at: start.addingTimeInterval(1)))
    }

    @Test("remaining time never goes negative")
    func remainingClamps() {
        let session = LockSession(startedAt: start, duration: 600)
        #expect(session.remaining(at: start) == 600)
        #expect(session.remaining(at: start.addingTimeInterval(900)) == 0)
    }
}

@Suite("Protocol session")
struct ProtocolSessionTests {
    private func session(_ steps: [ProtocolStep]) -> ProtocolSession {
        ProtocolSession(lockSessionID: UUID(), startedAt: .init(timeIntervalSince1970: 0), steps: steps)
    }

    @Test("complete only when every tier has a completed task (SPEC F4.5)")
    func requiresEveryTier() {
        let all = TaskTier.allCases.map { ProtocolStep(tier: $0, taskID: UUID(), outcome: .completed) }
        #expect(session(all).isComplete)
    }

    @Test("a skipped tier leaves the protocol incomplete (SPEC F4.6)")
    func skippedTierBlocksCompletion() {
        var steps = TaskTier.allCases.map { ProtocolStep(tier: $0, taskID: UUID(), outcome: .completed) }
        steps[1].outcome = .skipped
        #expect(!session(steps).isComplete)
    }

    @Test("a missing tier leaves the protocol incomplete")
    func missingTierBlocksCompletion() {
        let steps = [ProtocolStep(tier: .instantReset, taskID: UUID(), outcome: .completed)]
        #expect(!session(steps).isComplete)
    }
}

@Suite("Task tiers")
struct TaskTierTests {
    @Test("escalate from instant reset to longer activity")
    func ascendingOrder() {
        #expect(TaskTier.ascending == [.instantReset, .smallWin, .longerActivity])
        #expect(TaskTier.instantReset < TaskTier.smallWin)
        #expect(TaskTier.smallWin < TaskTier.longerActivity)
    }
}
