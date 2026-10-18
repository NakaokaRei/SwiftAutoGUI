import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct KeyboardDemoFeature {
    @ObservableState
    struct State: Equatable {

    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case sendKeyShortcut
        case sendSpecialKeyEvent
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return .cancel(id: CancelID.work)
            case .sendKeyShortcut:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(AutomationAction.keyShortcut([.control, .leftArrow]))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .sendSpecialKeyEvent:
                return .run { @MainActor [client] _ in
                    let actions: [AutomationAction] = [
                        .keyDown(.soundUp),
                        .keyUp(.soundUp),
                    ]
                    for action in actions {
                        try Task.checkCancellation()
                        _ = await client.execute(action)
                    }
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            }
        }
    }

}
