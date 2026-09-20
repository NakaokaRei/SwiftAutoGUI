import Foundation
import FoundationModels
import AppKit
import Testing
@testable import SwiftAutoGUI

@Suite("Agent language models and automation")
struct AgentAutomationBackendTests {
    private func decision(_ actions: [BasicAction] = [], done: Bool = false) -> ModelRecorder.Outcome {
        .text(AgentDecision(actions: actions, reasoningSummary: "Test decision", isDone: done).generatedContent.jsonString)
    }

    @Test("Agent defaults to native automation")
    func nativeDefault() {
        #expect(Agent(model: MockLanguageModel([])).automationBackend is NativeAutomationBackend)
    }

    @Test("Browser semantic observations work without vision capability")
    @MainActor
    func semanticOnly() async throws {
        let model = MockLanguageModel([decision(done: true)], capabilities: .init([.guidedGeneration]))
        let automation = FakeAutomationBackend()
        let result = try await Agent(model: model, delayBetweenSteps: 0, visionMode: .never,
                                     automationBackend: automation).run(goal: "Done")
        #expect(result.completed)
        #expect(await automation.observationCount == 1)
        #expect(model.recorder.requests.first?.transcript.renderedText.contains("Browser tab: test") == true)
    }

    @Test("Successive decisions retain the session and receive actual execution results")
    @MainActor
    func sessionHistory() async throws {
        let model = MockLanguageModel([decision([.pressElement(elementID: 1)]), decision(done: true)])
        let automation = FakeAutomationBackend()
        let result = try await Agent(model: model, delayBetweenSteps: 0, automationBackend: automation).run(goal: "Test goal")
        #expect(result.completed)
        #expect(await automation.executed.count == 1)
        let requests = model.recorder.requests
        #expect(requests.count == 2)
        #expect(requests[1].transcript.history.count > requests[0].transcript.history.count)
        #expect(requests[1].transcript.renderedText.contains("succeeded"))
        #expect(requests[1].transcript.renderedText.contains("Test goal"))
    }

    @Test("UI changes stop remaining actions and completion requires a new observation")
    @MainActor
    func stopsAtUIChange() async throws {
        let model = MockLanguageModel([
            decision([.pressElement(elementID: 1), .pressElement(elementID: 2)], done: true),
            decision(done: true)
        ])
        let automation = FakeAutomationBackend(screenChanged: true)
        let result = try await Agent(model: model, delayBetweenSteps: 0, automationBackend: automation).run(goal: "Done")
        #expect(result.completed)
        #expect(result.iterationsUsed == 2)
        #expect(await automation.executed.count == 1)
    }

    @Test("PCC failure retries only the decision, never executed actions", arguments: [false, true])
    @MainActor
    func fallbackDoesNotReplay(network: Bool) async throws {
        let primary = MockLanguageModel([decision([.pressElement(elementID: 1)]), network ? .network : .quota])
        let fallback = MockLanguageModel([decision(done: true)])
        let automation = FakeAutomationBackend()
        let result = try await Agent(model: primary, fallbackModel: fallback,
            delayBetweenSteps: 0, automationBackend: automation).run(goal: "Complete the test")
        #expect(result.completed)
        #expect(await automation.executed.count == 1)
        #expect(fallback.recorder.requests.count == 1)
        let transcript = try #require(fallback.recorder.requests.first?.transcript)
        #expect(transcript.history.count == 1)
        #expect(transcript.renderedText.contains("Complete the test"))
        #expect(transcript.renderedText.contains("succeeded"))
    }

    @Test("No fallback is implicit")
    @MainActor
    func noImplicitFallback() async {
        let model = MockLanguageModel([.quota])
        let automation = FakeAutomationBackend()
        await #expect(throws: PrivateCloudComputeLanguageModel.Error.self) {
            try await Agent(model: model, automationBackend: automation).run(goal: "test")
        }
        #expect(await automation.executed.isEmpty)
    }

    @Test("Cancellation and malformed decisions do not execute or fall back", arguments: [false, true])
    @MainActor
    func failedGeneration(cancel: Bool) async {
        let model = MockLanguageModel([cancel ? .cancel : .text("not valid JSON")])
        let fallback = MockLanguageModel([decision([.leftClick])])
        let automation = FakeAutomationBackend()
        await #expect(throws: (any Error).self) {
            try await Agent(model: model, fallbackModel: fallback,
                            automationBackend: automation).run(goal: "test")
        }
        #expect(await automation.executed.isEmpty)
        #expect(fallback.recorder.requests.isEmpty)
    }

    @Test("Context exhaustion resets history once and preserves current state")
    @MainActor
    func contextRecovery() async throws {
        let model = MockLanguageModel([decision([.pressElement(elementID: 1)]), .context, decision(done: true)])
        let automation = FakeAutomationBackend()
        let result = try await Agent(model: model, delayBetweenSteps: 0, automationBackend: automation).run(goal: "test")
        #expect(result.completed)
        #expect(model.recorder.requests.count == 3)
        #expect(model.recorder.requests[2].transcript.history.count == 1)
        #expect(model.recorder.requests[2].transcript.renderedText.contains("succeeded"))
        #expect(await automation.executed.count == 1)
    }

    @Test("History retention can be disabled without losing latest execution results")
    @MainActor
    func boundedHistory() async throws {
        let model = MockLanguageModel([decision([.pressElement(elementID: 1)]), decision(done: true)])
        _ = try await Agent(model: model, historyPolicy: .init(maximumTurns: 0),
            delayBetweenSteps: 0, automationBackend: FakeAutomationBackend()).run(goal: "test")
        #expect(model.recorder.requests[1].transcript.history.count == 1)
        #expect(model.recorder.requests[1].transcript.renderedText.contains("succeeded"))
    }

    @Test("Unsupported structured output is rejected before any request")
    @MainActor
    func capabilityCheck() async {
        let model = MockLanguageModel([], capabilities: .init([]))
        await #expect(throws: ActionGeneratorError.self) {
            try await Agent(model: model, automationBackend: FakeAutomationBackend()).run(goal: "test")
        }
        #expect(model.recorder.requests.isEmpty)
    }

    @Test("Independent generator requests have no shared conversation")
    func independentRequests() async throws {
        let response = ModelRecorder.Outcome.text(SingleAction(action: .write(text: "hello")).generatedContent.jsonString)
        let model = MockLanguageModel([response, response])
        let generator = ActionGenerator(model: model)
        async let first = generator.generateAction(from: "first")
        async let second = generator.generateAction(from: "second")
        _ = try await (first, second)
        #expect(model.recorder.requests.count == 2)
        #expect(model.recorder.requests.allSatisfy { $0.transcript.history.count == 1 })
    }

    @Test("A fresh-session context failure cannot be fixed by dropping history")
    @MainActor
    func boundedContextRetry() async {
        let model = MockLanguageModel([.context, .context, decision([.leftClick])])
        let automation = FakeAutomationBackend()
        await #expect(throws: LanguageModelError.self) {
            try await Agent(model: model, automationBackend: automation).run(goal: "test")
        }
        #expect(model.recorder.requests.count == 1)
        #expect(await automation.executed.isEmpty)
    }

    @Test("Fallback must have the capabilities required by the current observation")
    @MainActor
    func fallbackCapabilities() async {
        let primary = MockLanguageModel([.quota])
        let fallback = MockLanguageModel([], capabilities: .init([]))
        await #expect(throws: ActionGeneratorError.self) {
            try await Agent(model: primary, fallbackModel: fallback,
                            automationBackend: FakeAutomationBackend()).run(goal: "test")
        }
        #expect(fallback.recorder.requests.isEmpty)
    }

    @Test("Only the current screenshot reaches the model")
    @MainActor
    func imageHistory() async throws {
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let jpeg = try #require(bitmap.representation(using: .jpeg, properties: [:]))
        let model = MockLanguageModel([decision([.pressElement(elementID: 1)]), decision(done: true)])
        _ = try await Agent(model: model, delayBetweenSteps: 0,
                            automationBackend: FakeAutomationBackend(image: jpeg)).run(goal: "test")
        for request in model.recorder.requests {
            let images = request.transcript.compactMap { entry -> Transcript.Prompt? in
                if case .prompt(let prompt) = entry { return prompt }; return nil
            }.flatMap(\.segments).filter { if case .attachment = $0 { true } else { false } }
            #expect(images.count == 1)
        }
        let noVision = MockLanguageModel([], capabilities: .init([.guidedGeneration]))
        await #expect(throws: ActionGeneratorError.self) {
            try await Agent(model: noVision, automationBackend: FakeAutomationBackend(image: jpeg)).run(goal: "test")
        }
        #expect(noVision.recorder.requests.isEmpty)
    }

    @Test("Unsupported reasoning configuration is rejected before any request")
    func unsupportedReasoning() async {
        let model = MockLanguageModel([])
        let session = ActionSession(model: model, instructions: "test", contextOptions: .init(reasoningLevel: .deep))
        await #expect(throws: ActionGeneratorError.self) {
            try await session.respond(to: Prompt("test"), generating: AgentDecision.self)
        }
        #expect(model.recorder.requests.isEmpty)
    }

    @Test("Two calls cannot mutate a shared session concurrently")
    func concurrentSessionRequests() async throws {
        let gate = ModelGate()
        let json = AgentDecision(actions: [], reasoningSummary: "done", isDone: true).generatedContent.jsonString
        let model = MockLanguageModel([.paused(gate, json)])
        let session = ActionSession(model: model, instructions: "test")
        let first = Task { try await session.respond(to: Prompt("one"), generating: AgentDecision.self) }
        await gate.waitUntilStarted()
        await #expect(throws: LanguageModelSession.Error.self) {
            try await session.respond(to: Prompt("two"), generating: AgentDecision.self)
        }
        await gate.resume()
        _ = try await first.value
        #expect(model.recorder.requests.count == 1)
    }

    @Test("All native and browser action cases round-trip through Generable")
    func generatedSchema() throws {
        let actions: [BasicAction] = [
            .write(text: "hello"), .move(x: 1, y: 2), .leftClick, .rightClick, .doubleClick,
            .vscroll(clicks: -1), .hscroll(clicks: 1), .wait(duration: 0), .keyShortcut(keys: ["command", "a"]),
            .drag(fromX: 1, fromY: 2, toX: 3, toY: 4), .pressButton(label: "OK", bundleID: ""),
            .pressElement(elementID: 1), .setTextField(label: "Search", value: "a", bundleID: ""),
            .setElementValue(elementID: 2, value: "b"), .selectMenuItem(path: ["File"], bundleID: ""),
            .raiseWindow(title: "Test", bundleID: ""), .openURL(url: "https://example.com"),
            .activateApp(name: "Safari"), .quitApp(name: "Safari"), .getFrontmostApp, .activateTab(tabID: "tab")
        ]
        for action in actions {
            let decoded = try BasicAction(GeneratedContent(json: action.generatedContent.jsonString))
            #expect(decoded.generatedContent.jsonString == action.generatedContent.jsonString)
        }
    }
}

private actor FakeAutomationBackend: AgentAutomationBackend {
    private(set) var observationCount = 0
    private(set) var executed: [BasicAction] = []
    let screenChanged: Bool
    let image: Data?
    init(screenChanged: Bool = false, image: Data? = nil) {
        self.screenChanged = screenChanged
        self.image = image
    }

    func observe(visionMode: AgentVisionMode) async throws -> AgentObservation {
        observationCount += 1
        return AgentObservation(kind: .browser, formattedContext: "Browser tab: test [#1] Button",
            stateFingerprint: "test", actionableElementCount: 1,
            viewportSize: CGSize(width: 100, height: 100), screenshotJPEGData: image)
    }

    func execute(_ action: BasicAction, in observation: AgentObservation) async -> AgentAutomationExecution {
        executed.append(action)
        return AgentAutomationExecution(result: ActionExecutionResult(action: action, succeeded: true,
            method: .none, screenChanged: screenChanged), observation: observation)
    }
}

private extension Transcript {
    var renderedText: String { map { String(describing: $0) }.joined(separator: "\n") }
}
