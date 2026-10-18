import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct MouseControlFeature {
    @ObservableState
    struct State: Equatable {
        var mousePosition = ""
        var isAnimating = false
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case moveMouse
        case leftClick
        case doubleClick
        case tripleClick
        case performLinearMove
        case performEaseInOutMove
        case performElasticMove
        case performBounceMove
        case performCirclePattern
        case performLowFPSMove
        case performHighFPSMove
        case getMousePosition
        case positionReceived(CGPoint)
        case positionUpdated(CGPoint)
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isAnimating = false
                return .cancel(id: CancelID.work)
            case .moveMouse:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in
                    _ = await client.execute(AutomationAction.moveMouse(dx: 10, dy: 10))
                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .leftClick:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in
                    _ = await client.execute(AutomationAction.leftClick)
                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .doubleClick:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in
                    _ = await client.execute(AutomationAction.doubleClick())
                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .tripleClick:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in
                    _ = await client.execute(AutomationAction.tripleClick())
                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performLinearMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x + 200, y: startPos.y + 100)
                    _ = await client.execute(
                        AutomationAction.moveSmooth(to: targetPos, duration: 2.0, tweening: .linear)
                    )

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performEaseInOutMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x - 150, y: startPos.y + 150)
                    _ = await client.execute(
                        AutomationAction.moveSmooth(
                            to: targetPos, duration: 1.5, tweening: .easeInOutQuad))

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performElasticMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x + 250, y: startPos.y - 100)
                    _ = await client.execute(
                        AutomationAction.moveSmooth(
                            to: targetPos, duration: 2.0, tweening: .easeOutElastic))

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performBounceMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x - 200, y: startPos.y - 150)
                    _ = await client.execute(
                        AutomationAction.moveSmooth(
                            to: targetPos, duration: 2.0, tweening: .easeOutBounce))

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performCirclePattern:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let center = client.position()
                    let radius: CGFloat = 100
                    let steps = 60
                    let duration = 3.0
                    let stepDuration = duration / Double(steps)

                    var actions: [AutomationAction] = []
                    for i in 0...steps {
                        let angle = (Double(i) / Double(steps)) * 2 * Double.pi
                        let x = center.x + radius * cos(angle)
                        let y = center.y + radius * sin(angle)

                        actions.append(
                            .moveSmooth(
                                to: CGPoint(x: x, y: y), duration: stepDuration,
                                tweening: .easeInOutSine)
                        )
                    }
                    for action in actions {
                        try Task.checkCancellation()
                        _ = await client.execute(action)
                    }

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performLowFPSMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x + 300, y: startPos.y)
                    // 24 FPS creates visible stepping effect
                    _ = await client.execute(
                        AutomationAction.moveSmooth(
                            to: targetPos, duration: 2.0, tweening: .linear, fps: 24))

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .performHighFPSMove:
                guard !state.isAnimating else { return .none }
                state.isAnimating = true
                return .run { @MainActor [client] send in

                    let startPos = client.position()
                    let targetPos = CGPoint(x: startPos.x - 300, y: startPos.y)
                    // 120 FPS creates ultra-smooth movement
                    _ = await client.execute(
                        AutomationAction.moveSmooth(
                            to: targetPos, duration: 2.0, tweening: .linear, fps: 120))

                    send(.positionReceived(client.position()))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .getMousePosition:
                return .run { @MainActor [client] send in send(.positionUpdated(client.position()))
                }
            case .positionUpdated(let point):
                state.mousePosition = "Mouse at: x=\(Int(point.x)), y=\(Int(point.y))"
                return .none
            case .positionReceived(let point):
                state.mousePosition = "Mouse at: x=\(Int(point.x)), y=\(Int(point.y))"
                state.isAnimating = false
                return .none
            }
        }
    }

}
