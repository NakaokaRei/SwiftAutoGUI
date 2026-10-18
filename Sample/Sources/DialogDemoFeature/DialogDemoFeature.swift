import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct DialogDemoFeature {
    @ObservableState
    struct State: Equatable {
        var alertResult: String?
        var confirmResult: String?
        var promptResult: String?
        var passwordResult: String?
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case showAlert
        case showDefaultConfirm
        case showCustomConfirm
        case showPrompt
        case showPassword
        case resultReceived(ResultField, String?)
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return .cancel(id: CancelID.work)
            case .showAlert:
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        .alert(
                            "This is a sample alert message!",
                            title: "SwiftAutoGUI Alert",
                            button: "Got it!"
                        ))
                    send(.resultReceived(.alertResult, output.text))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .showDefaultConfirm:
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        .confirm(
                            "Do you want to continue with the operation?",
                            title: "Confirmation Required"
                        ))
                    send(.resultReceived(.confirmResult, output.text ?? "Cancelled"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .showCustomConfirm:
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        .confirm(
                            "What would you like to do next?",
                            title: "Choose Action",
                            buttons: ["Save", "Don't Save", "Cancel"]
                        ))
                    send(.resultReceived(.confirmResult, output.text ?? "Cancelled"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .showPrompt:
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        .prompt(
                            "Please enter your name:",
                            title: "User Information",
                            defaultAnswer: "John Doe"
                        ))
                    send(.resultReceived(.promptResult, output.text ?? "Cancelled"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .showPassword:
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        .password(
                            "Enter your password to continue:",
                            title: "Authentication Required"
                        ))
                    send(.resultReceived(.passwordResult, output.text ?? "Cancelled"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .resultReceived(let field, let text):
                switch field {
                case .alertResult: state.alertResult = text
                case .confirmResult: state.confirmResult = text
                case .promptResult: state.promptResult = text
                case .passwordResult: state.passwordResult = text
                }
                return .none
            }
        }
    }
    enum ResultField { case alertResult, confirmResult, promptResult, passwordResult }
}
