import ComposableArchitecture
import Foundation
import Testing
@testable import AgentDemoFeature

@MainActor
struct AgentDemoFeatureTests {
    private let runID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    @Test func validatesBeforeStarting() async {
        let store = TestStore(initialState: AgentDemoFeature.State()) { AgentDemoFeature() }
        await store.send(.start) { $0.error = "Please enter a goal" }
        await store.send(.binding(.set(\.goal, "Open Finder"))) { $0.goal = "Open Finder" }
        await store.send(.binding(.set(\.provider, .openAI))) { $0.provider = .openAI }
        await store.send(.start) { $0.error = "Please enter your OpenAI API key" }
        await store.send(.binding(.set(\.provider, .onDevice))) { $0.provider = .onDevice }
        await store.send(.binding(.set(\.maxIterations, 0))) { $0.maxIterations = 0 }
        await store.send(.start) {
            $0.error = "Iterations must be positive and delay must be finite and nonnegative."
        }
    }

    @Test(arguments: [true, false])
    func streamsStepsAndCompletes(completed: Bool) async {
        var initial = AgentDemoFeature.State()
        initial.goal = "Open Finder"
        let step = AgentDemoFeature.StepDisplay(reasoning: "Done", actions: "", timestamp: Date(timeIntervalSince1970: 0))
        let store = TestStore(initialState: initial) { AgentDemoFeature() } withDependencies: {
            $0.uuid = .constant(runID)
            $0.agentClient.run = { request in
                #expect(request.goal == "Open Finder")
                #expect(request.maxIterations == 20)
                return AsyncThrowingStream {
                    $0.yield(.step(step))
                    $0.yield(.finished(completed))
                    $0.finish()
                }
            }
        }
        await store.send(.start) { $0.isRunning = true; $0.runID = runID }
        await store.receive(.event(runID, .step(step))) {
            var numbered = step
            numbered.number = 1
            $0.steps = [numbered]
        }
        await store.receive(.event(runID, .finished(completed))) { $0.completed = completed }
        await store.receive(.ended(runID)) { $0.isRunning = false; $0.runID = nil }
        await store.finish()
        await store.send(.clear) { $0.steps = []; $0.completed = nil }
    }

    @Test func reportsFailure() async {
        struct Failure: Error, CustomStringConvertible { var description: String { "Generation failed" } }
        var initial = AgentDemoFeature.State()
        initial.goal = "Open Finder"
        let store = TestStore(initialState: initial) { AgentDemoFeature() } withDependencies: {
            $0.uuid = .constant(runID)
            $0.agentClient.run = { _ in AsyncThrowingStream { $0.finish(throwing: Failure()) } }
        }
        await store.send(.start) { $0.isRunning = true; $0.runID = runID }
        await store.receive(.failed(runID, "Generation failed")) {
            $0.error = "Generation failed"
            $0.isRunning = false
            $0.runID = nil
        }
        await store.finish()
    }

    @Test func stopCancelsStreamAndIgnoresOldResultsAfterRestart() async {
        let stream = AsyncThrowingStream<AgentClient.Event, any Error>.makeStream()
        let terminated = LockIsolated(false)
        stream.continuation.onTermination = { _ in terminated.setValue(true) }
        var initial = AgentDemoFeature.State()
        initial.goal = "Open Finder"
        let store = TestStore(initialState: initial) { AgentDemoFeature() } withDependencies: {
            $0.uuid = .constant(runID)
            $0.agentClient.run = { _ in stream.stream }
        }
        await store.send(.start) { $0.isRunning = true; $0.runID = runID }
        await store.send(.start) // A second click must not start another run.
        await store.send(.stop) { $0.isRunning = false; $0.runID = nil }
        await store.finish()
        #expect(terminated.value)

        let nextID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let nextStream = AsyncThrowingStream<AgentClient.Event, any Error>.makeStream()
        store.dependencies.uuid = .constant(nextID)
        store.dependencies.agentClient.run = { _ in nextStream.stream }
        await store.send(.start) { $0.isRunning = true; $0.runID = nextID }
        await store.send(.event(runID, .finished(true)))
        await store.send(.failed(runID, "Old error"))
        await store.send(.ended(runID))
        await store.send(.stop) { $0.isRunning = false; $0.runID = nil }
        await store.finish()
    }
}
