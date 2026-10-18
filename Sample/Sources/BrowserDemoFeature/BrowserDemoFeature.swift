import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftAutoGUIBrowser
import SwiftUI

@Reducer
struct BrowserDemoFeature {
    @ObservableState
    struct State {
        var endpoint = "http://127.0.0.1:9222"
        var allowedDomains = "example.com"
        var selectedTabID = ""
        var selectedElementID = 1
        var replacementText = ""
        var agentGoal = "Find the SwiftAutoGUI repository and open its Issues page"
        var provider: AIProviderChoice = .onDevice
        var openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        var openAIModel = AutomationModels.defaultAgentModel
        var maxAgentIterations = 12
        var agentDelay = 0.8

        var tabs: [BrowserTab] = []
        var observation: BrowserObservation?
        var statusMessage = "Start Chromium with remote debugging, then connect."
        var isConnected = false
        var isWorking = false
        var isAgentRunning = false
        var agentCompleted: Bool?
        var agentError: String?
        var agentSteps: [AgentStepDisplay] = []

        var connectionID: UUID?
        var operationID: UUID?
        var runID: UUID?
        var formattedOutput: String { observation?.formattedContext ?? "" }

    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case connect, disconnect, refreshTabs, capture, clickSelectedElement,
            replaceSelectedElementText
        case selectTab(String)
        case startAgent, stopAgent, clearAgentResult
        case connected(UUID, BrowserClient.Snapshot)
        case updated(UUID, BrowserClient.Snapshot)
        case connectionFailed(UUID, String)
        case operationFailed(UUID, String)
        case agentEvent(UUID, BrowserClient.Event)
        case agentFailed(UUID, String)
        case agentEnded(UUID)
    }
    @Dependency(\.browserClient) var browser
    @Dependency(\.uuid) var uuid
    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return disconnect(&state)
            case .connect:
                guard !state.isWorking, !state.isAgentRunning else { return .none }
                guard let endpoint = URL(string: state.endpoint), endpoint.host != nil,
                    ["http", "https"].contains(endpoint.scheme?.lowercased() ?? "")
                else {
                    state.statusMessage = "Enter a valid HTTP endpoint."
                    return .none
                }
                let domains = Set(
                    state.allowedDomains.split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }.filter { !$0.isEmpty })
                guard !domains.isEmpty else {
                    state.statusMessage = "Enter at least one allowed page domain."
                    return .none
                }
                let old = state.connectionID
                let id = uuid()
                state.connectionID = id
                state.isConnected = false
                state.isWorking = true
                state.tabs = []
                state.observation = nil
                state.statusMessage = "Connecting to Chromium…"
                return .run { @MainActor [browser] send in
                    if let old { await browser.close(old) }
                    do {
                        send(.connected(id, try await browser.connect(id, endpoint, domains)))
                    } catch is CancellationError { await browser.close(id) } catch {
                        send(.connectionFailed(id, error.localizedDescription))
                    }
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .connected(let id, let snapshot):
                guard state.connectionID == id else {
                    return .run { @MainActor [browser] _ in await browser.close(id) }
                }
                state.isConnected = true
                state.isWorking = false
                Self.apply(snapshot, to: &state)
                return .none
            case .connectionFailed(let id, let error):
                guard state.connectionID == id else { return .none }
                state.connectionID = nil
                state.isConnected = false
                state.isWorking = false
                state.statusMessage = error
                return .none
            case .disconnect:
                return disconnect(&state)
            case .refreshTabs: return perform(.refresh, state: &state)
            case .capture: return perform(.capture, state: &state)
            case .selectTab(let id): return perform(.select(id), state: &state)
            case .clickSelectedElement:
                guard let observation = state.observation else { return .none }
                return perform(
                    .execute(.click(elementID: state.selectedElementID), observation), state: &state
                )
            case .replaceSelectedElementText:
                guard let observation = state.observation else { return .none }
                return perform(
                    .execute(
                        .replaceText(
                            elementID: state.selectedElementID, value: state.replacementText),
                        observation), state: &state)
            case .updated(let id, let snapshot):
                guard state.operationID == id else { return .none }
                state.operationID = nil
                state.isWorking = false
                Self.apply(snapshot, to: &state)
                return .none
            case .operationFailed(let id, let error):
                guard state.operationID == id else { return .none }
                state.operationID = nil
                state.isWorking = false
                state.statusMessage = error
                return .none
            case .startAgent:
                guard state.isConnected, let connection = state.connectionID else {
                    state.agentError = "Connect to Chromium first."
                    return .none
                }
                guard !state.isAgentRunning, !state.isWorking else { return .none }
                guard !state.agentGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    state.agentError = "Enter a browser goal."
                    return .none
                }
                guard state.provider != .openAI || !state.openAIKey.isEmpty else {
                    state.agentError =
                        "Enter an OpenAI API key or launch the app with OPENAI_API_KEY."
                    return .none
                }
                guard state.maxAgentIterations > 0, state.agentDelay.isFinite, state.agentDelay >= 0
                else {
                    state.agentError =
                        "Iterations must be positive and delay must be finite and nonnegative."
                    return .none
                }
                let id = uuid()
                state.runID = id
                state.isAgentRunning = true
                state.agentCompleted = nil
                state.agentError = nil
                state.agentSteps = []
                state.statusMessage = "Browser AI Agent is running…"
                let request = BrowserClient.AgentRequest(
                    goal: state.agentGoal, provider: state.provider,
                    key: state.openAIKey, model: state.openAIModel,
                    iterations: state.maxAgentIterations,
                    delay: state.agentDelay, tabID: state.selectedTabID)
                return .run { @MainActor [browser] send in
                    do {
                        for try await event in browser.run(connection, request) {
                            try Task.checkCancellation()
                            send(.agentEvent(id, event))
                        }
                        send(.agentEnded(id))
                    } catch is CancellationError { send(.agentEnded(id)) } catch {
                        send(.agentFailed(id, error.localizedDescription))
                    }
                }.cancellable(id: AgentCancelID.run, cancelInFlight: true)
            case .stopAgent:
                state.runID = nil
                state.isAgentRunning = false
                state.statusMessage = "Browser AI Agent stopped."
                return .cancel(id: AgentCancelID.run)
            case .clearAgentResult:
                guard !state.isAgentRunning else { return .none }
                state.agentSteps = []
                state.agentCompleted = nil
                state.agentError = nil
                return .none
            case .agentEvent(let id, let event):
                guard state.runID == id else { return .none }
                switch event {
                case .step(var step):
                    step.number = state.agentSteps.count + 1
                    state.agentSteps.append(step)
                case .finished(let completed, let snapshot):
                    state.agentCompleted = completed
                    Self.apply(snapshot, to: &state)
                }
                return .none
            case .agentFailed(let id, let error):
                guard state.runID == id else { return .none }
                state.runID = nil
                state.isAgentRunning = false
                state.agentError = error
                state.statusMessage = "Browser AI Agent failed."
                return .none
            case .agentEnded(let id):
                guard state.runID == id else { return .none }
                state.runID = nil
                state.isAgentRunning = false
                return .none
            }
        }
    }
    private enum AgentCancelID { case run }
    struct AgentStepDisplay: Identifiable, Equatable, Sendable {
        var id = UUID()
        var number = 0
        var reasoning: String
        var actions: String
    }
    private func perform(_ command: BrowserClient.Command, state: inout State) -> Effect<Action> {
        guard let connection = state.connectionID, state.isConnected, !state.isWorking,
            !state.isAgentRunning
        else { return .none }
        let id = uuid()
        let selected = state.selectedTabID
        state.operationID = id
        state.isWorking = true
        return .run { @MainActor [browser] send in
            do {
                send(.updated(id, try await browser.perform(connection, selected, command)))
            } catch is CancellationError {} catch {
                send(.operationFailed(id, error.localizedDescription))
            }
        }.cancellable(id: CancelID.work, cancelInFlight: true)
    }
    private func disconnect(_ state: inout State) -> Effect<Action> {
        let connection = state.connectionID
        state.connectionID = nil
        state.operationID = nil
        state.runID = nil
        state.isConnected = false
        state.isWorking = false
        state.isAgentRunning = false
        state.tabs = []
        state.selectedTabID = ""
        state.observation = nil
        state.statusMessage = "Disconnected."
        return .merge(
            .cancel(id: CancelID.work), .cancel(id: AgentCancelID.run),
            .run { @MainActor [browser] _ in if let connection { await browser.close(connection) } }
        )
    }
    private static func apply(_ snapshot: BrowserClient.Snapshot, to state: inout State) {
        state.tabs = snapshot.tabs
        state.selectedTabID = snapshot.selectedTabID
        if let observation = snapshot.observation {
            state.observation = observation
        } else if state.observation?.tab.id != snapshot.selectedTabID {
            state.observation = nil
        }
        state.statusMessage = snapshot.message
    }
    static let availableModels = [
        "gpt-5.6-sol",
        "gpt-5.6-terra",
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-4o",
        "gpt-4o-mini",
    ]

    static let sampleAgentGoals = [
        "Open the Issues page for this repository",
        "Find issue 118 and open it",
        "Search this page for BrowserSession",
    ]

}
