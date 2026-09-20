import Foundation
import FoundationModels
import Synchronization

/// A deterministic framework executor. It never contacts a service or generates input.
struct MockLanguageModel: LanguageModel {
    struct Executor: LanguageModelExecutor {
        typealias Model = MockLanguageModel
        struct Configuration: Hashable, Sendable {
            let recorder: ModelRecorder
        }
        let recorder: ModelRecorder
        init(configuration: Configuration) { recorder = configuration.recorder }
        func prewarm(model: Model, transcript: Transcript) {}
        func respond(
            to request: LanguageModelExecutorGenerationRequest,
            model: Model,
            streamingInto channel: LanguageModelExecutorGenerationChannel
        ) async throws {
            let outcome = recorder.take(request)
            switch outcome {
            case .text(let text):
                await channel.send(.response(action: .appendText(text, tokenCount: 1)))
            case .paused(let gate, let text):
                await gate.pause()
                await channel.send(.response(action: .appendText(text, tokenCount: 1)))
            case .context:
                throw LanguageModelError.contextSizeExceeded(.init(
                    contextSize: 4096, tokenCount: 5000, debugDescription: "Mock context exhaustion"))
            case .quota:
                throw PrivateCloudComputeLanguageModel.Error.quotaLimitReached(.init(debugDescription: "Mock quota"))
            case .network:
                throw PrivateCloudComputeLanguageModel.Error.networkFailure(.init(debugDescription: "Mock network"))
            case .cancel:
                throw CancellationError()
            }
        }
    }

    let recorder: ModelRecorder
    var capabilities = LanguageModelCapabilities([.guidedGeneration, .vision])
    var executorConfiguration: Executor.Configuration { .init(recorder: recorder) }

    init(_ outcomes: [ModelRecorder.Outcome], capabilities: LanguageModelCapabilities? = nil) {
        recorder = ModelRecorder(outcomes)
        if let capabilities { self.capabilities = capabilities }
    }
}

final class ModelRecorder: Sendable, Hashable {
    enum Outcome: Sendable {
        case text(String), context, quota, network, cancel
        case paused(ModelGate, String)
    }
    private struct State {
        var outcomes: [Outcome]
        var requests: [LanguageModelExecutorGenerationRequest] = []
    }
    private let state: Mutex<State>
    init(_ outcomes: [Outcome]) { state = Mutex(State(outcomes: outcomes)) }
    var requests: [LanguageModelExecutorGenerationRequest] { state.withLock { $0.requests } }
    func take(_ request: LanguageModelExecutorGenerationRequest) -> Outcome {
        state.withLock { state in
            state.requests.append(request)
            guard !state.outcomes.isEmpty else { return .text("invalid: mock exhausted") }
            return state.outcomes.removeFirst()
        }
    }
    static func == (lhs: ModelRecorder, rhs: ModelRecorder) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

actor ModelGate {
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var release: CheckedContinuation<Void, Never>?

    func pause() async {
        await withCheckedContinuation { continuation in
            release = continuation
            started = true
            startWaiter?.resume()
            startWaiter = nil
        }
    }
    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func resume() {
        release?.resume()
        release = nil
    }
}
