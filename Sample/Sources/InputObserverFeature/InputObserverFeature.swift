import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct InputObserverFeature {
    @ObservableState
    struct State: Equatable {
        var events: [ObservedInputEvent] = []
        var eventCounts: [String: Int] = [:]
        var currentModifiers = "none"
        var latestPointerPosition: CGPoint?
        var isObserving = false
        var sequence = 0
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case startObserving, stopObserving, clear
        case received(ObservedInputEvent)
        case ended
    }
    @Dependency(\.inputMonitorClient) var monitor
    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isObserving = false
                return .cancel(id: CancelID.work)
            case .startObserving:
                guard !state.isObserving else { return .none }
                state.isObserving = true
                return .run { @MainActor [monitor] send in
                    for await event in monitor.events() {
                        try Task.checkCancellation()
                        send(.received(event))
                    }
                    send(.ended)
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .stopObserving:
                state.isObserving = false
                return .cancel(id: CancelID.work)
            case .ended:
                state.isObserving = false
                return .none
            case .clear:
                state.events = []
                state.eventCounts = [:]
                state.sequence = 0
                return .none
            case .received(var event):
                guard state.isObserving else { return .none }
                if event.name == "mouseMoved" { state.latestPointerPosition = event.point }
                state.currentModifiers = event.modifiers
                state.eventCounts[event.name, default: 0] += 1
                state.sequence += 1
                event.sequence = state.sequence
                if event.name == "mouseMoved", let first = state.events.first,
                    first.name == "mouseMoved",
                    event.timestamp.timeIntervalSince(first.timestamp) < 0.05
                {
                    state.events[0] = event
                } else {
                    state.events.insert(event, at: 0)
                }
                if state.events.count > 80 { state.events.removeLast(state.events.count - 80) }
                return .none
            }
        }
    }

}
