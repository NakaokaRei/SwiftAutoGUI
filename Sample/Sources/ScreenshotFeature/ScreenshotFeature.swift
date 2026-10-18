import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct ScreenshotFeature {
    @ObservableState
    struct State: Equatable {
        var imageData: Data?
        var screenshotImage: NSImage? { imageData.flatMap(NSImage.init(data:)) }
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case takeScreenshot, takeScreenshotRegion, saveScreenshotToDocuments, saveRegionToDocuments
        case imageReceived(Data?)
    }
    @Dependency(\.automationClient) var client
    @Dependency(\.sampleFiles) var files

    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop: return .cancel(id: CancelID.work)
            case .takeScreenshot, .takeScreenshotRegion:
                let region: Bool
                if case .takeScreenshotRegion = action { region = true } else { region = false }
                return .run { @MainActor [client] send in
                    let output = await client.execute(
                        region
                            ? .screenshotRegion(CGRect(x: 100, y: 100, width: 200, height: 200))
                            : .screenshot)
                    send(.imageReceived(output.imageData))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .imageReceived(let data):
                state.imageData = data
                return .none
            case .saveScreenshotToDocuments, .saveRegionToDocuments:
                let region: CGRect?
                if case .saveRegionToDocuments = action {
                    region = CGRect(x: 0, y: 0, width: 300, height: 300)
                } else {
                    region = nil
                }
                return .run { @MainActor [files] _ in await files.saveScreenshot(region) }
                    .cancellable(id: CancelID.work)
            }
        }
    }

}
