import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct ActionsDemoFeature {
    @ObservableState
    struct State: Equatable {
        var executionLog: [String] = []
        var isExecuting = false
        var selectedExample = ActionExample.mouseClick
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case executeActions, clearLog
        case logged(String)
        case finished
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isExecuting = false
                return .cancel(id: CancelID.work)
            case .clearLog:
                state.executionLog = []
                return .none
            case .executeActions:
                guard !state.isExecuting else { return .none }
                state.isExecuting = true
                state.executionLog.append("Starting action execution...")
                let example = state.selectedExample
                return .run { @MainActor [client] send in
                    for (index, action) in example.actions.enumerated() {
                        try Task.checkCancellation()
                        send(.logged("[\(index + 1)] Executing: \(describeAction(action))"))
                        _ = await client.execute(action)
                    }
                    send(.finished)
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .logged(let message):
                state.executionLog.append(message)
                return .none
            case .finished:
                state.isExecuting = false
                state.executionLog.append("Execution completed!")
                return .none
            }
        }
    }
    enum ActionExample: String, CaseIterable {
        case mouseClick = "Mouse Click"
        case typeText = "Type Text"
        case keyboardShortcut = "Keyboard Shortcut"
        case mouseMovement = "Mouse Movement"
        case scrolling = "Scrolling"

        var description: String {
            switch self {
            case .mouseClick:
                return "Move mouse and perform clicks"
            case .typeText:
                return "Type text using keyboard"
            case .keyboardShortcut:
                return "Execute keyboard shortcuts"
            case .mouseMovement:
                return "Move mouse to different positions"
            case .scrolling:
                return "Scroll vertically and horizontally"
            }
        }

        var actions: [AutomationAction] {
            switch self {
            case .mouseClick:
                return [
                    .move(to: CGPoint(x: 400, y: 400)),
                    .wait(0.5),
                    .leftClick,
                    .wait(0.5),
                    .doubleClick(),
                    .wait(0.5),
                    .rightClick,
                ]

            case .typeText:
                return [
                    .write("Hello, SwiftAutoGUI!", interval: 0.05),
                    .wait(0.5),
                    .keyShortcut([.returnKey]),
                    .write("This is an Action demo.", interval: 0.05),
                ]

            case .keyboardShortcut:
                return [
                    AutomationAction.selectAll(),
                    .wait(0.3),
                    AutomationAction.copy(),
                    .wait(0.3),
                    AutomationAction.paste(),
                    .wait(0.3),
                    AutomationAction.undo(),
                ]

            case .mouseMovement:
                return [
                    .move(to: CGPoint(x: 100, y: 100)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 500, y: 100)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 500, y: 500)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 100, y: 500)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 300, y: 300)),
                ]

            case .scrolling:
                return [
                    .vscroll(clicks: -5),
                    .wait(0.5),
                    .vscroll(clicks: 5),
                    .wait(0.5),
                    .hscroll(clicks: -3),
                    .wait(0.5),
                    .hscroll(clicks: 3),
                ]
            }
        }
    }

}
