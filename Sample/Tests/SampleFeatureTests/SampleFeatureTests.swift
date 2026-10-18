import ComposableArchitecture
import Foundation
import SampleSupport
import SwiftAutoGUI
import SwiftAutoGUIBrowser
import Testing

@testable import AIGenerationDemoFeature
@testable import ActionsDemoFeature
@testable import AppleScriptFeature
@testable import BrowserDemoFeature
@testable import DialogDemoFeature
@testable import ImageRecognitionFeature
@testable import InputObserverFeature
@testable import KeyboardDemoFeature
@testable import KeyboardLayoutFeature
@testable import MouseControlFeature
@testable import PixelDetectionFeature
@testable import ScreenContextFeature
@testable import ScreenshotFeature
@testable import ScrollingDemoFeature
@testable import TextTypingFeature

@MainActor
struct SampleFeatureTests {
    @Test func typingCapturesInputAndSpeed() async {
        let clock = TestClock()
        let calls = LockIsolated<[String]>([])
        var state = TextTypingFeature.State()
        state.textToType = "Hello"
        state.typingSpeed = 0.2
        let store = TestStore(initialState: state) {
            TextTypingFeature()
        } withDependencies: {
            $0.automationClient.execute = { action in
                let description = describeAction(action)
                calls.withValue { $0.append(description) }
                if case .wait = action { try? await clock.sleep(for: .seconds(1)) }
                return .init()
            }
        }
        await store.send(.focusAndTypeInTargetField) {
            $0.isTyping = true
            $0.isTargetFieldFocused = true
            $0.typingStatus = "Focusing target field and typing..."
        }
        await store.send(.binding(.set(\.textToType, "Changed"))) { $0.textToType = "Changed" }
        await clock.advance(by: .seconds(3))
        await store.receive(\.typingFinished) {
            $0.isTyping = false
            $0.typingStatus = "✅ Completed typing: Hello"
        }
        #expect(calls.value.last == "Write: \"Hello\" (interval: 0.2s)")
        await store.finish()
    }

    @Test func typingCancellationStopsRemainingInput() async {
        let clock = TestClock()
        let calls = LockIsolated(0)
        let store = TestStore(initialState: TextTypingFeature.State()) {
            TextTypingFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in
                calls.withValue { $0 += 1 }
                try? await clock.sleep(for: .seconds(10))
                return .init()
            }
        }
        await store.send(.typeText("Hello")) {
            $0.isTyping = true
            $0.typingStatus = "Typing: Hello"
        }
        await store.send(.stop) { $0.isTyping = false }
        await store.finish()
        #expect(calls.value == 1)
    }

    @Test func keyboardAndScrollingUseInjectedActions() async {
        let calls = LockIsolated<[String]>([])
        let keyboard = Store(initialState: KeyboardDemoFeature.State()) {
            KeyboardDemoFeature()
        } withDependencies: {
            $0.automationClient.execute = { action in
                let description = describeAction(action)
                calls.withValue { $0.append(description) }
                return .init()
            }
        }
        await keyboard.send(.sendSpecialKeyEvent).finish()
        #expect(calls.value.count == 2)
        let scrolling = Store(initialState: ScrollingDemoFeature.State()) {
            ScrollingDemoFeature()
        } withDependencies: {
            $0.automationClient.execute = { action in
                let description = describeAction(action)
                calls.withValue { $0.append(description) }
                return .init()
            }
        }
        await scrolling.send(.verticalScrollDown).finish()
        #expect(calls.value.last == "Vertical scroll: -5 clicks")
    }

    @Test func keyboardLayoutUsesClientAndUpdatesSelection() async {
        let store = TestStore(initialState: KeyboardLayoutFeature.State()) {
            KeyboardLayoutFeature()
        } withDependencies: {
            $0.automationClient.resetLayout = { .jis }
            $0.automationClient.detectedLayout = { .jis }
        }
        await store.send(.resetToAutoDetect)
        await store.receive(\.layoutReceived) {
            $0.selectedLayout = .jis
            $0.detectedLayout = .jis
            $0.statusMessage = "Reset to auto-detect"
        }
    }

    @Test func mouseAnimationFinishesWithPosition() async {
        let store = TestStore(initialState: MouseControlFeature.State()) {
            MouseControlFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in .init() }
            $0.automationClient.position = { CGPoint(x: 10, y: 20) }
        }
        await store.send(.performLinearMove) { $0.isAnimating = true }
        await store.receive(\.positionReceived) {
            $0.isAnimating = false
            $0.mousePosition = "Mouse at: x=10, y=20"
        }
    }

    @Test func pixelAndScreenshotResultsStayValueBased() async {
        let pixel = TestStore(initialState: PixelDetectionFeature.State()) {
            PixelDetectionFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in
                var result = AutomationClient.Output()
                result.size = CGSize(width: 1920, height: 1080)
                return result
            }
        }
        await pixel.send(.getScreenSize)
        await pixel.receive(\.sizeReceived) { $0.screenSize = "Screen: 1920 x 1080" }
        let image = Data([1, 2, 3])
        let screenshot = TestStore(initialState: ScreenshotFeature.State()) {
            ScreenshotFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in
                var result = AutomationClient.Output()
                result.imageData = image
                return result
            }
        }
        await screenshot.send(.takeScreenshot)
        await screenshot.receive(\.imageReceived) { $0.imageData = image }
    }

    @Test func dialogCancellationAndScriptResult() async {
        let dialog = TestStore(initialState: DialogDemoFeature.State()) {
            DialogDemoFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in .init() }
        }
        await dialog.send(.showPrompt)
        await dialog.receive(\.resultReceived) { $0.promptResult = "Cancelled" }
        let script = TestStore(initialState: AppleScriptFeature.State()) {
            AppleScriptFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in .init(text: "Result") }
        }
        await script.send(.executeScript) { $0.isExecuting = true }
        await script.receive(\.finished) {
            $0.isExecuting = false
            $0.result = "Result"
        }
    }

    @Test func actionsCompleteWithoutRealInput() async {
        let calls = LockIsolated(0)
        let store = Store(initialState: ActionsDemoFeature.State()) {
            ActionsDemoFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in
                calls.withValue { $0 += 1 }
                return .init()
            }
        }
        await store.send(.executeActions).finish()
        #expect(calls.value == ActionsDemoFeature.ActionExample.mouseClick.actions.count)
        #expect(!store.isExecuting)
        #expect(store.executionLog.last == "Execution completed!")
    }

    @Test func generationAndExecutionUseCapturedPlan() async {
        var state = AIGenerationDemoFeature.State()
        state.prompt = "Type hello"
        let executed = LockIsolated<[Int]>([])
        let store = Store(initialState: state) {
            AIGenerationDemoFeature()
        } withDependencies: {
            $0.generationClient.generate = { _, _, _, _ in GeneratedPlan(actions: [.write("hello")])
            }
            $0.generationClient.execute = { _, index in executed.withValue { $0.append(index) } }
        }
        await store.send(.generateActions).finish()
        #expect(store.generatedActions.count == 1)
        #expect(!store.isGenerating)
        await store.send(.executeGeneratedActions).finish()
        #expect(executed.value == [0])
        #expect(!store.isExecuting)
    }

    @Test func imageSearchRequiresTemplateAndHandlesNoMatch() async {
        let store = TestStore(initialState: ImageRecognitionFeature.State()) {
            ImageRecognitionFeature()
        } withDependencies: {
            $0.automationClient.execute = { _ in .init() }
        }
        await store.send(.locateTestImage) {
            $0.imageRecognitionResult = "Please create a test image first"
        }
        await store.send(.binding(.set(\.testImagePath, "/tmp/template.png"))) {
            $0.testImagePath = "/tmp/template.png"
        }
        await store.send(.locateTestImage) {
            $0.isWorking = true
            $0.imageRecognitionResult = "Searching for test image on screen..."
        }
        await store.receive(\.finished) {
            $0.isWorking = false
            $0.imageRecognitionResult =
                "No test images found on screen. Make sure the test image is visible."
        }
    }

    @Test func inputMonitorCoalescesMovementAndStopsStream() async {
        let events = AsyncStream<ObservedInputEvent>.makeStream()
        let terminated = LockIsolated(false)
        events.continuation.onTermination = { _ in terminated.setValue(true) }
        let store = TestStore(initialState: InputObserverFeature.State()) {
            InputObserverFeature()
        } withDependencies: {
            $0.inputMonitorClient.events = { events.stream }
        }
        await store.send(.startObserving) { $0.isObserving = true }
        var event = ObservedInputEvent(
            timestamp: Date(timeIntervalSince1970: 0), name: "mouseMoved", details: "move",
            modifiers: "none", point: CGPoint(x: 5, y: 6))
        events.continuation.yield(event)
        await store.receive(\.received) {
            var numbered = event
            numbered.sequence = 1
            $0.events = [numbered]
            $0.sequence = 1
            $0.eventCounts = ["mouseMoved": 1]
            $0.latestPointerPosition = event.point
        }
        event.timestamp = Date(timeIntervalSince1970: 0.01)
        events.continuation.yield(event)
        await store.receive(\.received) {
            var numbered = event
            numbered.sequence = 2
            $0.events = [numbered]
            $0.sequence = 2
            $0.eventCounts = ["mouseMoved": 2]
        }
        await store.send(.stop) { $0.isObserving = false }
        await store.finish()
        #expect(terminated.value)
        await store.send(.received(event))
    }

    @Test func screenContextRefreshStopsOnDisappear() async {
        let clock = TestClock()
        let gathers = LockIsolated(0)
        let store = Store(initialState: ScreenContextFeature.State()) {
            ScreenContextFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.screenContextClient.gather = { _ in
                gathers.withValue { $0 += 1 }
                return ScreenContext(
                    frontmostApp: nil, visibleWindows: [], focusedWindowAXTree: nil)
            }
        }
        let task = store.send(.startAutoRefresh)
        await clock.advance(by: .seconds(2))
        #expect(gathers.value >= 1)
        await store.send(.stop).finish()
        await task.finish()
        let count = gathers.value
        await clock.advance(by: .seconds(4))
        #expect(gathers.value == count)
        #expect(!store.autoRefresh)
    }

    @Test func browserDisconnectClearsStateAndIgnoresOldResponse() async {
        let connection = UUID()
        let operation = UUID()
        var state = BrowserDemoFeature.State()
        state.connectionID = connection
        state.operationID = operation
        state.isConnected = true
        state.isWorking = true
        let closed = LockIsolated<[UUID]>([])
        let store = Store(initialState: state) {
            BrowserDemoFeature()
        } withDependencies: {
            $0.browserClient.close = { id in closed.withValue { $0.append(id) } }
        }
        await store.send(.disconnect).finish()
        #expect(closed.value == [connection])
        #expect(!store.isConnected && !store.isWorking)
        #expect(store.connectionID == nil)
        store.send(
            .updated(operation, .init(tabs: [], selectedTabID: "old", message: "old response")))
        #expect(store.selectedTabID.isEmpty)
        #expect(store.statusMessage == "Disconnected.")
    }

    @Test func browserRejectsInvalidConnectionAndMissingGoal() async {
        var state = BrowserDemoFeature.State()
        state.endpoint = "file:///tmp/test"
        let store = Store(initialState: state) { BrowserDemoFeature() }
        await store.send(.connect).finish()
        #expect(store.statusMessage == "Enter a valid HTTP endpoint.")
        store.send(.startAgent)
        #expect(store.agentError == "Connect to Chromium first.")
    }

    @Test func browserConnectUsesAllowlistAndClosesOldSession() async {
        let old = UUID()
        let next = UUID()
        let closed = LockIsolated<[UUID]>([])
        var state = BrowserDemoFeature.State()
        state.connectionID = old
        state.isConnected = true
        state.allowedDomains = " Example.com, swift.org "
        let store = Store(initialState: state) {
            BrowserDemoFeature()
        } withDependencies: {
            $0.uuid = .constant(next)
            $0.browserClient.close = { id in closed.withValue { $0.append(id) } }
            $0.browserClient.connect = { id, endpoint, domains in
                #expect(id == next)
                #expect(endpoint.absoluteString == "http://127.0.0.1:9222")
                #expect(domains == ["example.com", "swift.org"])
                return .init(tabs: [], selectedTabID: "new", message: "Connected")
            }
        }
        await store.send(.connect).finish()
        #expect(closed.value == [old])
        #expect(store.connectionID == next && store.isConnected && !store.isWorking)
        #expect(store.selectedTabID == "new")
        await store.send(.disconnect).finish()
        #expect(closed.value == [old, next])
    }

    @Test func browserAgentStreamsProgressAndCompletes() async {
        let connection = UUID()
        let run = UUID()
        var state = BrowserDemoFeature.State()
        state.connectionID = connection
        state.isConnected = true
        let store = Store(initialState: state) {
            BrowserDemoFeature()
        } withDependencies: {
            $0.uuid = .constant(run)
            $0.browserClient.run = { id, request in
                #expect(id == connection)
                #expect(request.iterations == 12)
                return AsyncThrowingStream {
                    $0.yield(.step(.init(reasoning: "Found page", actions: "click")))
                    $0.yield(
                        .finished(true, .init(tabs: [], selectedTabID: "tab", message: "Done")))
                    $0.finish()
                }
            }
        }
        await store.send(.startAgent).finish()
        #expect(store.agentSteps.count == 1)
        #expect(store.agentSteps.first?.number == 1)
        #expect(store.agentCompleted == true && !store.isAgentRunning)
        #expect(store.runID == nil)
        store.send(.agentFailed(run, "Late failure"))
        #expect(store.agentError == nil)
        #expect(store.statusMessage == "Done")
    }

    @Test(arguments: [false, true])
    func generationFailureClearsBusyState(cancelled: Bool) async {
        struct Failed: Error {}
        var state = AIGenerationDemoFeature.State()
        state.prompt = "Hello"
        let store = Store(initialState: state) {
            AIGenerationDemoFeature()
        } withDependencies: {
            $0.generationClient.generate = { _, _, _, _ in
                if cancelled { throw CancellationError() }
                throw Failed()
            }
        }
        await store.send(.generateActions).finish()
        #expect(!store.isGenerating)
        #expect((store.error == nil) == cancelled)
        #expect(store.generatedActions.isEmpty)
    }
}
