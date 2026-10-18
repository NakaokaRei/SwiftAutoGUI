import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct AIGenerationDemoFeature {
    @ObservableState
    struct State {
        var prompt = ""
        var generatedActions: [String] = []
        var plan: GeneratedPlan?
        var executionLog: [String] = []
        var isGenerating = false
        var isExecuting = false
        var error: String?
        var selectedBackend: Backend = .foundationModels
        var openAIKey = ""
        var openAIModel = AutomationModels.defaultTextModel
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case generateActions, executeGeneratedActions, clearLog
        case useSamplePrompt(String)
        case generated(GeneratedPlan)
        case failed(String)
        case logged(String)
        case finished, cancelled
    }
    @Dependency(\.generationClient) var generator
    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isGenerating = false
                state.isExecuting = false
                return .cancel(id: CancelID.work)
            case .clearLog:
                state.executionLog = []
                return .none
            case .useSamplePrompt(let prompt):
                state.prompt = prompt
                return .none
            case .generateActions:
                guard !state.isGenerating, !state.isExecuting else { return .none }
                guard !state.prompt.isEmpty else {
                    state.error = "Please enter a prompt"
                    return .none
                }
                guard state.selectedBackend != .openAI || !state.openAIKey.isEmpty else {
                    state.error = "Please enter your OpenAI API key."
                    return .none
                }
                state.isGenerating = true
                state.error = nil
                state.generatedActions = []
                state.plan = nil
                state.executionLog = [
                    "Generating actions from prompt...",
                    "Backend: \(state.selectedBackend.rawValue)",
                    "Prompt: \(state.prompt)",
                ]
                let prompt = state.prompt
                let backend = state.selectedBackend
                let key = state.openAIKey
                let model = state.openAIModel
                return .run { @MainActor [generator] send in
                    do {
                        let actions = try await generator.generate(prompt, backend, key, model)
                        try Task.checkCancellation()
                        send(.generated(actions))
                    } catch is CancellationError {
                        send(.cancelled)
                    } catch {
                        send(.failed(error.localizedDescription))
                    }
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .generated(let plan):
                let actions = plan.descriptions
                state.plan = plan
                state.isGenerating = false
                state.generatedActions = actions
                if actions.isEmpty { state.error = "Could not generate actions from prompt" }
                state.executionLog.append("Generated \(actions.count) action(s)")
                return .none
            case .failed(let error):
                state.isGenerating = false
                state.isExecuting = false
                state.error = error
                state.executionLog.append("Error: \(error)")
                return .none
            case .executeGeneratedActions:
                guard !state.isExecuting, !state.isGenerating, !state.generatedActions.isEmpty
                else {
                    return .none
                }
                guard let plan = state.plan else { return .none }
                state.isExecuting = true
                let actions = state.generatedActions
                return .run { @MainActor [generator] send in
                    for (index, action) in actions.enumerated() {
                        try Task.checkCancellation()
                        send(.logged("Executing [\(index + 1)]: \(action)"))
                        await generator.execute(plan, index)
                    }
                    send(.finished)
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .logged(let message):
                state.executionLog.append(message)
                return .none
            case .cancelled:
                state.isGenerating = false
                state.isExecuting = false
                return .none
            case .finished:
                state.isExecuting = false
                state.executionLog.append("Execution completed!")
                return .none
            }
        }
    }
    enum Backend: String, CaseIterable, Identifiable {
        case foundationModels = "On-device"
        case pcc = "Private Cloud Compute"
        case openAI = "OpenAI"

        var id: String { rawValue }
    }

    static let availableOpenAIModels = [
        "gpt-5.6-luna",
        "gpt-5.6-terra",
        "gpt-5.6-sol",
        "gpt-4.1-nano",
        "gpt-4.1-mini",
        "gpt-4.1",
        "gpt-5-nano",
        "gpt-5-mini",
        "gpt-5",
    ]

    static let samplePrompts: [String] = [
        "Click at 300, 400",
        "Type 'Hello, AI!'",
        "Scroll down 5 clicks",
        "Press Command+C to copy",
        "Move to 200, 200, click, wait 0.5 seconds, then type 'test'",
    ]

}
