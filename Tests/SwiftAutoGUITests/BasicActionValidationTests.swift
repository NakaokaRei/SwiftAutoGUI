import Foundation
import Testing
@testable import SwiftAutoGUI

@Suite("Generated action validation")
struct BasicActionValidationTests {
    @Test("Malformed parameters never become successful no-ops")
    @MainActor
    func invalidParameters() async {
        let invalid: [BasicAction] = [.openURL(url: "javascript:alert(1)"), .openURL(url: "https://"),
            .activateApp(name: "../Safari"), .quitApp(name: ""), .move(x: .nan, y: 1),
            .drag(fromX: 0, fromY: 0, toX: .infinity, toY: 0), .wait(duration: -1),
            .wait(duration: .infinity), .wait(duration: 1e30), .vscroll(clicks: Int.max),
            .keyShortcut(keys: []), .pressButton(label: "", bundleID: ""),
            .selectMenuItem(path: [], bundleID: ""), .raiseWindow(title: "", bundleID: "")]
        for action in invalid {
            #expect(throws: ActionGeneratorError.self) { try action.toAction() }
            let result = await AgentActionExecutor.execute(action, in: nil,
                screenContextOptions: nil, observationDelay: 0).result
            #expect(!result.succeeded)
            #expect(result.method == .none)
        }
    }

    @Test("Standalone generation rejects actions requiring observations")
    func standaloneTargets() async {
        for action: BasicAction in [.pressElement(elementID: 1), .setElementValue(elementID: 1, value: "x"), .activateTab(tabID: "tab")] {
            let model = MockLanguageModel([.text(SingleAction(action: action).generatedContent.jsonString)])
            await #expect(throws: ActionGeneratorError.self) {
                try await ActionGenerator(model: model).generateAction(from: "test")
            }
        }
    }

    @Test("Missing action parameters are not replaced with zero or empty text")
    func missingFields() {
        for type in ["move", "drag", "write", "wait", "keyShortcut", "setElementValue", "openURL", "activateApp"] {
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(BasicAction.self, from: Data("{\"type\":\"\(type)\"}".utf8))
            }
        }
    }

    @Test("Failed target lookup remains an execution failure")
    @MainActor
    func missingTargets() async {
        let missing = "invalid.swift-auto-gui.nonexistent-test-app"
        let actions: [BasicAction] = [.pressButton(label: "Missing", bundleID: missing),
            .setTextField(label: "Missing", value: "test", bundleID: missing),
            .selectMenuItem(path: ["Missing"], bundleID: missing),
            .raiseWindow(title: "Missing", bundleID: missing)]
        for action in actions {
            let result = await AgentActionExecutor.execute(action, in: nil,
                screenContextOptions: nil, observationDelay: 0).result
            #expect(!result.succeeded)
            #expect(result.failureReason != nil)
        }
    }
}
