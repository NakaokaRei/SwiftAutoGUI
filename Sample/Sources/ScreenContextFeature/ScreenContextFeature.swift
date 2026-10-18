import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct ScreenContextFeature {
    @ObservableState
    struct State {
        var context: ScreenContext?
        var formattedOutput = ""
        var isLoading = false
        var autoRefresh = false
        var refreshInterval = 2.0
        var maxDepth = 5
        var maxNodes = 200
        var maxValueLength = 100
        var includeAXTree = true
        var selectedElementID = 1
        var elementValue = ""
        var executionLog = "No element action executed yet."
        var isExecuting = false
        var nodeCount: Int {
            context?.focusedWindowAXTree.map { ScreenContextFeature.countNodes($0) } ?? 0
        }
        var actionableElementCount: Int { context?.actionableElementCount ?? 0 }
        var options: ScreenContextProvider.Options {
            .init(
                maxDepth: maxDepth, maxNodes: maxNodes, maxValueLength: maxValueLength,
                includeAXTree: includeAXTree)
        }
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case gather, startAutoRefresh, stopAutoRefresh
        case pressSelectedElement, setSelectedElementValue
        case gathered(ScreenContext)
        case executed(AgentActionExecution)
    }
    @Dependency(\.screenContextClient) var screen
    @Dependency(\.continuousClock) var clock
    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isLoading = false
                state.isExecuting = false
                state.autoRefresh = false
                return .merge(.cancel(id: CancelID.work), .cancel(id: TimerID.refresh))
            case .gather:
                guard !state.isLoading, !state.isExecuting else { return .none }
                state.isLoading = true
                let options = state.options
                return .run { @MainActor [screen] send in send(.gathered(screen.gather(options))) }
                    .cancellable(id: CancelID.work)
            case .gathered(let context):
                state.context = context
                state.formattedOutput = context.formatted()
                state.isLoading = false
                return .none
            case .startAutoRefresh:
                state.autoRefresh = true
                let interval = max(0.1, state.refreshInterval.isFinite ? state.refreshInterval : 2)
                return .run { @MainActor [clock] send in
                    while !Task.isCancelled {
                        send(.gather)
                        try await clock.sleep(for: .seconds(interval))
                    }
                }.cancellable(id: TimerID.refresh, cancelInFlight: true)
            case .stopAutoRefresh:
                state.autoRefresh = false
                return .cancel(id: TimerID.refresh)
            case .pressSelectedElement, .setSelectedElementValue:
                guard !state.isExecuting, !state.isLoading else { return .none }
                guard let context = state.context else {
                    state.executionLog = "Capture a screen context first."
                    return .none
                }
                state.isExecuting = true
                let command: BasicAction
                if case .pressSelectedElement = action {
                    command = .pressElement(elementID: state.selectedElementID)
                } else {
                    command = .setElementValue(
                        elementID: state.selectedElementID, value: state.elementValue)
                }
                let options = state.options
                return .run { @MainActor [screen] send in
                    send(.executed(await screen.execute(command, context, options)))
                }.cancellable(id: CancelID.work)
            case .executed(let execution):
                state.isExecuting = false
                state.context = execution.screenContext
                state.formattedOutput = execution.screenContext?.formatted() ?? ""
                state.executionLog = Self.describe(execution.result)
                return .none
            }
        }
    }
    private enum TimerID { case refresh }
    static func describe(_ result: ActionExecutionResult) -> String {
        var lines = [
            "Result: \(result.succeeded ? "succeeded" : "failed")",
            "Method: \(result.method.rawValue)",
            "Screen changed: \(result.screenChanged)",
            "Focused app changed: \(result.focusedAppChanged)",
            "Focused element changed: \(result.focusedElementChanged)",
        ]
        if let reason = result.failureReason {
            lines.append("Reason: \(reason)")
        }
        return lines.joined(separator: "\n")
    }

    static func countNodes(_ node: AXNode) -> Int {
        var count = 1
        if let children = node.children {
            for child in children {
                count += countNodes(child)
            }
        }
        return count
    }
}
