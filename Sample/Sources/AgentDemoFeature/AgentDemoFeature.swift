import ComposableArchitecture
import Foundation
import SwiftAutoGUI

@Reducer
struct AgentDemoFeature {
    @ObservableState
    struct State: Equatable {
        var goal = ""
        var isRunning = false
        var error: String?
        var provider: AIProviderChoice = .onDevice
        var openAIKey = ""
        var openAIModel = AutomationModels.defaultAgentModel
        var maxIterations = 20
        var delayBetweenSteps = 1.0
        var useScreenContext = true
        var steps: [StepDisplay] = []
        var completed: Bool?
        var runID: UUID?
    }

    struct StepDisplay: Equatable, Identifiable, Sendable {
        var id = UUID()
        var number = 0
        var reasoning: String
        var actions: String
        var timestamp: Date
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case start
        case stop
        case sampleGoalSelected(String)
        case clear
        case event(UUID, AgentClient.Event)
        case failed(UUID, String)
        case ended(UUID)
    }

    @Dependency(\.agentClient) var agentClient
    @Dependency(\.uuid) var uuid
    private enum CancelID { case run }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .sampleGoalSelected(let goal):
                state.goal = goal
                return .none
            case .clear:
                guard !state.isRunning else { return .none }
                state.steps = []
                state.completed = nil
                state.error = nil
                return .none
            case .start:
                guard !state.isRunning else { return .none }
                guard !state.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.error = "Please enter a goal"
                    return .none
                }
                guard state.provider != .openAI || !state.openAIKey.isEmpty else {
                    state.error = "Please enter your OpenAI API key"
                    return .none
                }
                guard state.maxIterations > 0, state.delayBetweenSteps.isFinite,
                      state.delayBetweenSteps >= 0 else {
                    state.error = "Iterations must be positive and delay must be finite and nonnegative."
                    return .none
                }
                let id = uuid()
                state.runID = id
                state.isRunning = true
                state.error = nil
                state.steps = []
                state.completed = nil
                let request = AgentClient.Request(
                    goal: state.goal, provider: state.provider, apiKey: state.openAIKey,
                    model: state.openAIModel, maxIterations: state.maxIterations,
                    delay: state.delayBetweenSteps, useScreenContext: state.useScreenContext
                )
                return .run { [agentClient] send in
                    do {
                        for try await event in agentClient.run(request) {
                            try Task.checkCancellation()
                            await send(.event(id, event))
                        }
                        await send(.ended(id))
                    } catch is CancellationError {
                        await send(.ended(id))
                    } catch {
                        await send(.failed(id, String(describing: error)))
                    }
                }
                .cancellable(id: CancelID.run, cancelInFlight: true)
            case .stop:
                state.isRunning = false
                state.runID = nil
                return .cancel(id: CancelID.run)
            case let .event(id, event):
                guard state.runID == id else { return .none }
                switch event {
                case .step(var step):
                    step.number = state.steps.count + 1
                    state.steps.append(step)
                case .finished(let completed):
                    state.completed = completed
                }
                return .none
            case let .failed(id, error):
                guard state.runID == id else { return .none }
                state.error = error
                state.isRunning = false
                state.runID = nil
                return .none
            case .ended(let id):
                guard state.runID == id else { return .none }
                state.isRunning = false
                state.runID = nil
                return .none
            }
        }
    }

    static let availableModels = [
        "gpt-5.6-sol",
        "gpt-5.6-terra",
        "gpt-5.6-luna",
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-5.4-nano",
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-4.1",
        "gpt-4.1-mini",
    ]

    static let sampleGoals: [String] = [
        "Open Safari and search for Swift programming",
        "Open System Settings",
        "Open Finder and create a new folder on Desktop",
        "Open TextEdit and type 'Hello, World!'",
    ]

}
