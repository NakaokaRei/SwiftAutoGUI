import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct ScrollingDemoFeature {
    @ObservableState
    struct State: Equatable {

    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case verticalScrollDown
        case verticalScrollUp
        case horizontalScrollLeft
        case horizontalScrollRight
        case smoothVerticalScrollDown
        case smoothVerticalScrollUp
        case smoothHorizontalScrollLeft
        case smoothHorizontalScrollRight
        case smoothScrollWithBounce
        case smoothScrollWithElastic
        case smoothScrollCustomEasing
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return .cancel(id: CancelID.work)
            case .verticalScrollDown:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(AutomationAction.vscroll(clicks: -5))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .verticalScrollUp:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(AutomationAction.vscroll(clicks: 5))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .horizontalScrollLeft:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(AutomationAction.hscroll(clicks: 5))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .horizontalScrollRight:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(AutomationAction.hscroll(clicks: -5))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothVerticalScrollDown:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothVScroll(
                            clicks: -150, duration: 3.0, tweening: .easeInOutQuad))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothVerticalScrollUp:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothVScroll(
                            clicks: 150, duration: 3.0, tweening: .easeInOutQuad))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothHorizontalScrollLeft:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothHScroll(
                            clicks: 100, duration: 2.5, tweening: .easeInOutQuad))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothHorizontalScrollRight:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothHScroll(
                            clicks: -100, duration: 2.5, tweening: .easeInOutQuad))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothScrollWithBounce:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothVScroll(
                            clicks: -200, duration: 4.0, tweening: .easeOutBounce))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothScrollWithElastic:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothVScroll(
                            clicks: 180, duration: 3.5, tweening: .easeOutElastic))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .smoothScrollCustomEasing:
                return .run { @MainActor [client] _ in
                    _ = await client.execute(
                        AutomationAction.smoothVScroll(
                            clicks: -120, duration: 3.0,
                            tweening: .custom({ t in
                                return t * t * (3 - 2 * t)  // Smooth step
                            })))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            }
        }
    }

}
