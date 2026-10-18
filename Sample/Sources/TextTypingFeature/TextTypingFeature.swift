import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct TextTypingFeature {
    @ObservableState
    struct State: Equatable {
        var textToType = ""
        var typingSpeed = 0.0
        var typingStatus = ""
        var targetTextField = ""
        var isTargetFieldFocused = false
        var isTyping = false
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case typeText(String)
        case typeCustomText, focusAndTypeInTargetField
        case typingFinished(String)
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isTyping = false
                return .cancel(id: CancelID.work)
            case .typeCustomText: return .send(.typeText(state.textToType))
            case .typeText(let text):
                return startTyping(state: &state, text: text, focus: false)
            case .focusAndTypeInTargetField:
                return startTyping(state: &state, text: state.textToType, focus: true)
            case .typingFinished(let message):
                state.isTyping = false
                state.typingStatus = message
                return .none
            }
        }
    }

    private func startTyping(state: inout State, text: String, focus: Bool) -> Effect<Action> {
        guard !state.isTyping else { return .none }
        guard !text.isEmpty else {
            state.typingStatus = "Please enter some text to type"
            return .none
        }
        state.isTyping = true
        state.typingStatus = focus ? "Focusing target field and typing..." : "Typing: \(text)"
        if focus {
            state.targetTextField = ""
            state.isTargetFieldFocused = true
        }
        let speed = state.typingSpeed
        return .run { @MainActor [client] send in
            let actions: [AutomationAction] =
                focus
                ? [
                    .wait(0.5), .selectAll(), .wait(0.1), .keyDown(.delete), .keyUp(.delete),
                    .wait(0.1),
                    .write(text, interval: speed),
                ]
                : [.wait(1), .write(text, interval: speed)]
            for action in actions {
                try Task.checkCancellation()
                _ = await client.execute(action)
            }
            send(.typingFinished("✅ Completed typing: \(text)"))
        }.cancellable(id: CancelID.work, cancelInFlight: true)
    }

}
