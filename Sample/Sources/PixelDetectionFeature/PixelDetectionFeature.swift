import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct PixelDetectionFeature {
    @ObservableState
    struct State: Equatable {
        var pixelComponents: [Double]?
        var screenSize = ""
        var pixelColor: NSColor? {
            pixelComponents.map {
                NSColor(deviceRed: $0[0], green: $0[1], blue: $0[2], alpha: $0[3])
            }
        }
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case getScreenSize, getPixelColor
        case sizeReceived(CGSize?)
        case colorReceived([Double]?)
    }
    @Dependency(\.automationClient) var client

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return .cancel(id: CancelID.work)
            case .getScreenSize:
                return .run { @MainActor [client] send in
                    let output = await client.execute(.getScreenSize)
                    send(.sizeReceived(output.size))
                }.cancellable(id: CancelID.work)
            case .getPixelColor:
                return .run { @MainActor [client] send in
                    let output = await client.execute(.getPixel(x: 100, y: 100))
                    send(.colorReceived(output.color))
                }.cancellable(id: CancelID.work)
            case .sizeReceived(let size):
                if let size {
                    state.screenSize = "Screen: \(Int(size.width)) x \(Int(size.height))"
                }
                return .none
            case .colorReceived(let color):
                state.pixelComponents = color
                return .none
            }
        }
    }

}
