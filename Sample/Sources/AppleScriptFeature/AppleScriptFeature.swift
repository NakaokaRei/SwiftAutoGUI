import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct AppleScriptFeature {
    @ObservableState
    struct State: Equatable {
        var scriptText = SampleScript.safariSearch.script
        var result = ""
        var isExecuting = false
        var errorMessage: String?
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case executeScript
        case loadSampleScript(SampleScript)
        case finished(String)
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
            case .loadSampleScript(let sample):
                state.scriptText = sample.script
                state.result = ""
                state.errorMessage = nil
                return .none
            case .executeScript:
                guard !state.isExecuting else { return .none }
                state.isExecuting = true
                state.result = ""
                state.errorMessage = nil
                let script = state.scriptText
                return .run { @MainActor [client] send in
                    let output = await client.execute(.executeAppleScript(script))
                    send(.finished(output.text ?? "Script executed successfully (no output)"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .finished(let result):
                state.result = result
                state.isExecuting = false
                return .none
            }
        }
    }
    enum SampleScript: String, CaseIterable, Sendable {
        case safariSearch = "Safari Search"
        case systemInfo = "System Info"
        case volumeControl = "Volume Control"
        case notification = "Notification"
        case calculator = "Calculator"

        var script: String {
            switch self {
            case .safariSearch:
                return """
                    tell application "Safari"
                        activate
                        make new document
                        set URL of current tab of front window to "https://github.com/NakaokaRei/SwiftAutoGUI"
                    end tell
                    """
            case .systemInfo:
                return """
                    tell application "System Events"
                        set userName to name of current user
                        set osVersion to system version of (system info)
                        return "User: " & userName & ", macOS: " & osVersion
                    end tell
                    """
            case .volumeControl:
                return """
                    -- Get current volume
                    set currentVolume to output volume of (get volume settings)

                    -- Set volume to 50%
                    set volume output volume 50

                    -- Return the previous volume
                    return "Previous volume was: " & currentVolume & "%"
                    """
            case .notification:
                return """
                    display notification "Hello from SwiftAutoGUI!" with title "AppleScript Demo" subtitle "This is a test notification"
                    return "Notification sent!"
                    """
            case .calculator:
                return """
                    -- Simple calculation
                    set result to (25 * 4) + (100 / 2)
                    return "25 × 4 + 100 ÷ 2 = " & result
                    """
            }
        }
    }
}
