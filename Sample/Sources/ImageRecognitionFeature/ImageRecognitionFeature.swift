import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

@Reducer
struct ImageRecognitionFeature {
    @ObservableState
    struct State: Equatable {
        var imageRecognitionResult = ""
        var testImagePath = ""
        var isWorking = false
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case stop
        case createTestImageForRecognition, createTiledTestImageForRecognition
        case locateTestImage, locateAndClickTestImage, findAllTestImages
        case imageCreated(SampleFiles.ImageResult)
        case finished(String)
    }
    @Dependency(\.automationClient) var client
    @Dependency(\.sampleFiles) var files
    private enum CancelID { case work }
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .stop:
                state.isWorking = false
                return .cancel(id: CancelID.work)
            case .createTestImageForRecognition, .createTiledTestImageForRecognition:
                guard !state.isWorking else { return .none }
                state.isWorking = true
                let tiled: Bool
                if case .createTiledTestImageForRecognition = action {
                    tiled = true
                } else {
                    tiled = false
                }
                return .run { @MainActor [files] send in
                    send(.imageCreated(files.createImage(tiled)))
                }
                .cancellable(id: CancelID.work)
            case .imageCreated(let result):
                state.isWorking = false
                state.testImagePath = result.path
                state.imageRecognitionResult = result.message
                return .none
            case .locateTestImage, .locateAndClickTestImage, .findAllTestImages:
                guard !state.isWorking else { return .none }
                guard !state.testImagePath.isEmpty else {
                    state.imageRecognitionResult = "Please create a test image first"
                    return .none
                }
                state.isWorking = true
                state.imageRecognitionResult = "Searching for test image on screen..."
                let path = state.testImagePath
                return .run { @MainActor [client] send in
                    if case .locateAndClickTestImage = action {
                        let result = await client.execute(.locateCenterOnScreen(path))
                        guard let center = result.point else {
                            send(.finished("Test image not found on screen."))
                            return
                        }
                        for step: AutomationAction in [.move(to: center), .wait(0.5), .leftClick] {
                            try Task.checkCancellation()
                            _ = await client.execute(step)
                        }
                        send(
                            .finished(
                                "Clicked on the test image at x=\(Int(center.x)), y=\(Int(center.y))"
                            ))
                        return
                    }
                    let query: AutomationAction
                    if case .findAllTestImages = action {
                        query = .locateAllOnScreen(path, confidence: 0.95)
                    } else {
                        query = .locateOnScreen(path)
                    }
                    let rects = await client.execute(query).rects
                    guard !rects.isEmpty else {
                        send(
                            .finished(
                                "No test images found on screen. Make sure the test image is visible."
                            ))
                        return
                    }
                    var lines = ["Found \(rects.count) instance(s) of the test image:"]
                    for (index, rect) in rects.enumerated() {
                        lines.append(
                            "[\(index + 1)] x=\(Int(rect.minX)), y=\(Int(rect.minY)), size=\(Int(rect.width))x\(Int(rect.height))"
                        )
                        for point in [
                            CGPoint(x: rect.minX, y: rect.minY),
                            CGPoint(x: rect.maxX, y: rect.minY),
                            CGPoint(x: rect.maxX, y: rect.maxY),
                            CGPoint(x: rect.minX, y: rect.maxY),
                            CGPoint(x: rect.minX, y: rect.minY),
                        ] {
                            try Task.checkCancellation()
                            _ = await client.execute(.move(to: point))
                            _ = await client.execute(.wait(0.2))
                        }
                    }
                    if let rect = rects.first {
                        try Task.checkCancellation()
                        _ = await client.execute(.move(to: CGPoint(x: rect.midX, y: rect.midY)))
                    }
                    send(.finished(lines.joined(separator: "\n") + "\nHighlighted all matches!"))
                }.cancellable(id: CancelID.work, cancelInFlight: true)
            case .finished(let message):
                state.isWorking = false
                state.imageRecognitionResult = message
                return .none
            }
        }
    }

}
