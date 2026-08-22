import Foundation
import Testing
@testable import SwiftAutoGUI

@Suite("Agent automation backend")
struct AgentAutomationBackendTests {
    @Test("Agent defaults to native automation")
    func nativeDefault() {
        let agent = Agent(backend: DoneVisionBackend())
        #expect(agent.automationBackend is NativeAutomationBackend)
    }

    @Test("Agent observes through an explicitly supplied backend")
    @MainActor
    func explicitBackend() async throws {
        let automation = FakeAutomationBackend()
        let agent = Agent(
            backend: DoneVisionBackend(),
            maxIterations: 1,
            delayBetweenSteps: 0,
            visionMode: .always,
            automationBackend: automation
        )
        let result = try await agent.run(goal: "Done")
        #expect(result.completed)
        #expect(await automation.observationCount == 1)
    }
}

private struct DoneVisionBackend: VisionActionGenerating {
    var isAvailable: Bool { true }
    var unavailableReason: String? { nil }

    func generateActions(
        goal: String,
        screenshot: Data,
        screenSize: CGSize,
        history: [AgentStep]
    ) async throws -> AgentResponse {
        AgentResponse(actions: [], reasoning: "Already complete", isDone: true)
    }
}

private actor FakeAutomationBackend: AgentAutomationBackend {
    private(set) var observationCount = 0

    func observe(visionMode: AgentVisionMode) async throws -> AgentObservation {
        observationCount += 1
        return AgentObservation(
            kind: .browser,
            formattedContext: "Browser tab: test",
            stateFingerprint: "test",
            actionableElementCount: 0,
            viewportSize: CGSize(width: 100, height: 100),
            screenshotJPEGData: Data([0x01])
        )
    }

    func execute(
        _ action: BasicAction,
        in observation: AgentObservation
    ) async -> AgentAutomationExecution {
        AgentAutomationExecution(
            result: ActionExecutionResult(action: action, succeeded: true, method: .none),
            observation: observation
        )
    }
}
