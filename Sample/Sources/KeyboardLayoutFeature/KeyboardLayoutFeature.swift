import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct KeyboardLayoutFeature {
    @ObservableState
    struct State: Equatable {
        var textToType = ""
        var typingSpeed = 0.0
        var statusMessage = ""
        var targetTextField = ""
        var isTargetFieldFocused = false
        var isTyping = false
        var selectedLayout: KeyboardLayout = .us
        var detectedLayout: KeyboardLayout = .us
        let comparisonCharacters: [Character] = [
            "@", "[", "]", ":", "^", "\"", "&", "'", "(", ")", "=", "~", "`", "+", "*", "_", "\\",
            "{",
            "}", "|",
        ]
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case typeText(String)
        case typeCustomText, focusAndTypeInTargetField
        case typingFinished(String)
        case appeared, applyLayout, resetToAutoDetect
        case layoutReceived(KeyboardLayout, KeyboardLayout, String)
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
                state.statusMessage = message
                return .none
            case .appeared, .applyLayout, .resetToAutoDetect:
                let selected = state.selectedLayout
                return .run { @MainActor [client] send in
                    let current: KeyboardLayout
                    let message: String
                    switch action {
                    case .applyLayout:
                        current = client.layout(selected)
                        message = "Layout set to \(current.rawValue.uppercased())"
                    case .resetToAutoDetect:
                        current = client.resetLayout()
                        message = "Reset to auto-detect"
                    default:
                        current = client.layout(nil)
                        message = ""
                    }
                    send(.layoutReceived(current, client.detectedLayout(), message))
                }.cancellable(id: CancelID.work)
            case .layoutReceived(let current, let detected, let message):
                state.selectedLayout = current
                state.detectedLayout = detected
                state.statusMessage = message
                return .none
            }
        }
    }

    private func startTyping(state: inout State, text: String, focus: Bool) -> Effect<Action> {
        guard !state.isTyping else { return .none }
        guard !text.isEmpty else {
            state.statusMessage = "Please enter some text to type"
            return .none
        }
        state.isTyping = true
        state.statusMessage = focus ? "Focusing target field and typing..." : "Typing: \(text)"
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
    static func mappingDescription(for character: Character, layout: KeyboardLayout) -> String {
        guard let mapping = layout.mapping(for: character) else { return "-" }
        return (mapping.needsShift ? "Shift + ." : ".") + mapping.key.rawValue
    }

}
