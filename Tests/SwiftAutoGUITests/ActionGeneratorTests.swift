//
//  ActionGeneratorTests.swift
//  SwiftAutoGUITests
//

import Foundation
import Testing
@testable import SwiftAutoGUI

@Suite("ActionGenerator Tests")
struct ActionGeneratorTests {

    // MARK: - BasicAction Codable Round-Trip Tests

    @Suite("BasicAction Codable Round-Trip")
    struct CodableRoundTripTests {

        @Test("write round-trip")
        func writeRoundTrip() throws {
            let action = BasicAction.write(text: "Hello, World!")
            let roundTripped = try roundTrip(action)
            guard case .write(let text) = roundTripped else {
                Issue.record("Expected .write, got \(roundTripped)")
                return
            }
            #expect(text == "Hello, World!")
        }

        @Test("move round-trip")
        func moveRoundTrip() throws {
            let action = BasicAction.move(x: 100.5, y: 200.5)
            let roundTripped = try roundTrip(action)
            guard case .move(let x, let y) = roundTripped else {
                Issue.record("Expected .move, got \(roundTripped)")
                return
            }
            #expect(x == 100.5)
            #expect(y == 200.5)
        }

        @Test("leftClick round-trip")
        func leftClickRoundTrip() throws {
            let roundTripped = try roundTrip(.leftClick)
            guard case .leftClick = roundTripped else {
                Issue.record("Expected .leftClick, got \(roundTripped)")
                return
            }
        }

        @Test("rightClick round-trip")
        func rightClickRoundTrip() throws {
            let roundTripped = try roundTrip(.rightClick)
            guard case .rightClick = roundTripped else {
                Issue.record("Expected .rightClick, got \(roundTripped)")
                return
            }
        }

        @Test("doubleClick round-trip")
        func doubleClickRoundTrip() throws {
            let roundTripped = try roundTrip(.doubleClick)
            guard case .doubleClick = roundTripped else {
                Issue.record("Expected .doubleClick, got \(roundTripped)")
                return
            }
        }

        @Test("vscroll round-trip")
        func vscrollRoundTrip() throws {
            let action = BasicAction.vscroll(clicks: -5)
            let roundTripped = try roundTrip(action)
            guard case .vscroll(let clicks) = roundTripped else {
                Issue.record("Expected .vscroll, got \(roundTripped)")
                return
            }
            #expect(clicks == -5)
        }

        @Test("hscroll round-trip")
        func hscrollRoundTrip() throws {
            let action = BasicAction.hscroll(clicks: 3)
            let roundTripped = try roundTrip(action)
            guard case .hscroll(let clicks) = roundTripped else {
                Issue.record("Expected .hscroll, got \(roundTripped)")
                return
            }
            #expect(clicks == 3)
        }

        @Test("wait round-trip")
        func waitRoundTrip() throws {
            let action = BasicAction.wait(duration: 1.5)
            let roundTripped = try roundTrip(action)
            guard case .wait(let duration) = roundTripped else {
                Issue.record("Expected .wait, got \(roundTripped)")
                return
            }
            #expect(duration == 1.5)
        }

        @Test("keyShortcut round-trip")
        func keyShortcutRoundTrip() throws {
            let action = BasicAction.keyShortcut(keys: ["command", "shift", "a"])
            let roundTripped = try roundTrip(action)
            guard case .keyShortcut(let keys) = roundTripped else {
                Issue.record("Expected .keyShortcut, got \(roundTripped)")
                return
            }
            #expect(keys == ["command", "shift", "a"])
        }

        @Test("drag round-trip")
        func dragRoundTrip() throws {
            let action = BasicAction.drag(fromX: 10, fromY: 20, toX: 300, toY: 400)
            let roundTripped = try roundTrip(action)
            guard case .drag(let fromX, let fromY, let toX, let toY) = roundTripped else {
                Issue.record("Expected .drag, got \(roundTripped)")
                return
            }
            #expect(fromX == 10)
            #expect(fromY == 20)
            #expect(toX == 300)
            #expect(toY == 400)
        }

        @Test("pressButton round-trip")
        func pressButtonRoundTrip() throws {
            let action = BasicAction.pressButton(label: "Save", bundleID: "com.apple.TextEdit")
            let roundTripped = try roundTrip(action)
            guard case .pressButton(let label, let bundleID) = roundTripped else {
                Issue.record("Expected .pressButton, got \(roundTripped)")
                return
            }
            #expect(label == "Save")
            #expect(bundleID == "com.apple.TextEdit")
        }

        @Test("setTextField round-trip preserves empty label")
        func setTextFieldRoundTrip() throws {
            let action = BasicAction.setTextField(label: "", value: "hello", bundleID: "")
            let roundTripped = try roundTrip(action)
            guard case .setTextField(let label, let value, let bundleID) = roundTripped else {
                Issue.record("Expected .setTextField, got \(roundTripped)")
                return
            }
            #expect(label == "")
            #expect(value == "hello")
            #expect(bundleID == "")
        }

        @Test("selectMenuItem round-trip preserves path")
        func selectMenuItemRoundTrip() throws {
            let action = BasicAction.selectMenuItem(path: ["File", "Save As…"], bundleID: "com.apple.TextEdit")
            let roundTripped = try roundTrip(action)
            guard case .selectMenuItem(let path, let bundleID) = roundTripped else {
                Issue.record("Expected .selectMenuItem, got \(roundTripped)")
                return
            }
            #expect(path == ["File", "Save As…"])
            #expect(bundleID == "com.apple.TextEdit")
        }

        @Test("raiseWindow round-trip")
        func raiseWindowRoundTrip() throws {
            let action = BasicAction.raiseWindow(title: "Untitled", bundleID: "")
            let roundTripped = try roundTrip(action)
            guard case .raiseWindow(let title, let bundleID) = roundTripped else {
                Issue.record("Expected .raiseWindow, got \(roundTripped)")
                return
            }
            #expect(title == "Untitled")
            #expect(bundleID == "")
        }

        @Test("openURL round-trip")
        func openURLRoundTrip() throws {
            let roundTripped = try roundTrip(.openURL(url: "https://example.com/path?q=swift"))
            guard case .openURL(let url) = roundTripped else {
                Issue.record("Expected .openURL, got \(roundTripped)")
                return
            }
            #expect(url == "https://example.com/path?q=swift")
        }

        @Test("activateApp round-trip")
        func activateAppRoundTrip() throws {
            let roundTripped = try roundTrip(.activateApp(name: "Safari"))
            guard case .activateApp(let name) = roundTripped else {
                Issue.record("Expected .activateApp, got \(roundTripped)")
                return
            }
            #expect(name == "Safari")
        }

        @Test("quitApp round-trip")
        func quitAppRoundTrip() throws {
            let roundTripped = try roundTrip(.quitApp(name: "Google Chrome"))
            guard case .quitApp(let name) = roundTripped else {
                Issue.record("Expected .quitApp, got \(roundTripped)")
                return
            }
            #expect(name == "Google Chrome")
        }

        @Test("getFrontmostApp round-trip")
        func getFrontmostAppRoundTrip() throws {
            let roundTripped = try roundTrip(.getFrontmostApp)
            guard case .getFrontmostApp = roundTripped else {
                Issue.record("Expected .getFrontmostApp, got \(roundTripped)")
                return
            }
        }
    }

    // MARK: - OpenAI JSON Response Parsing Tests

    @Suite("OpenAI JSON Response Parsing")
    struct OpenAIParsingTests {

        @Test("parse write action")
        func parseWrite() throws {
            let json = """
            {"actions": [{"type": "write", "text": "Hello", "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .write(let text) = actions[0] else {
                Issue.record("Expected .write")
                return
            }
            #expect(text == "Hello")
        }

        @Test("parse move action")
        func parseMove() throws {
            let json = """
            {"actions": [{"type": "move", "text": null, "x": 100, "y": 200, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .move(let x, let y) = actions[0] else {
                Issue.record("Expected .move")
                return
            }
            #expect(x == 100)
            #expect(y == 200)
        }

        @Test("parse leftClick action")
        func parseLeftClick() throws {
            let json = """
            {"actions": [{"type": "leftClick", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .leftClick = actions[0] else {
                Issue.record("Expected .leftClick")
                return
            }
        }

        @Test("parse multiple actions")
        func parseMultipleActions() throws {
            let json = """
            {"actions": [
                {"type": "move", "text": null, "x": 100, "y": 200, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null},
                {"type": "leftClick", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null},
                {"type": "write", "text": "test", "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}
            ]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 3)
            guard case .move(let x, let y) = actions[0] else {
                Issue.record("Expected .move as first action")
                return
            }
            #expect(x == 100)
            #expect(y == 200)
            guard case .leftClick = actions[1] else {
                Issue.record("Expected .leftClick as second action")
                return
            }
            guard case .write(let text) = actions[2] else {
                Issue.record("Expected .write as third action")
                return
            }
            #expect(text == "test")
        }

        @Test("parse keyShortcut action")
        func parseKeyShortcut() throws {
            let json = """
            {"actions": [{"type": "keyShortcut", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": ["command", "c"], "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .keyShortcut(let keys) = actions[0] else {
                Issue.record("Expected .keyShortcut")
                return
            }
            #expect(keys == ["command", "c"])
        }

        @Test("parse drag action")
        func parseDrag() throws {
            let json = """
            {"actions": [{"type": "drag", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": 10, "fromY": 20, "toX": 300, "toY": 400}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .drag(let fromX, let fromY, let toX, let toY) = actions[0] else {
                Issue.record("Expected .drag")
                return
            }
            #expect(fromX == 10)
            #expect(fromY == 20)
            #expect(toX == 300)
            #expect(toY == 400)
        }

        @Test("parse vscroll action")
        func parseVScroll() throws {
            let json = """
            {"actions": [{"type": "vscroll", "text": null, "x": null, "y": null, "clicks": -5, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .vscroll(let clicks) = actions[0] else {
                Issue.record("Expected .vscroll")
                return
            }
            #expect(clicks == -5)
        }

        @Test("parse wait action")
        func parseWait() throws {
            let json = """
            {"actions": [{"type": "wait", "text": null, "x": null, "y": null, "clicks": null, "duration": 2.5, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .wait(let duration) = actions[0] else {
                Issue.record("Expected .wait")
                return
            }
            #expect(duration == 2.5)
        }

        @Test("parse pressButton action")
        func parsePressButton() throws {
            let json = """
            {"actions": [{"type": "pressButton", "label": "OK", "bundleID": "com.apple.calculator", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null, "value": null, "path": null, "title": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .pressButton(let label, let bundleID) = actions[0] else {
                Issue.record("Expected .pressButton")
                return
            }
            #expect(label == "OK")
            #expect(bundleID == "com.apple.calculator")
        }

        @Test("parse selectMenuItem action with array path")
        func parseSelectMenuItem() throws {
            let json = """
            {"actions": [{"type": "selectMenuItem", "path": ["File", "Save As…"], "bundleID": "", "text": null, "x": null, "y": null, "clicks": null, "duration": null, "keys": null, "fromX": null, "fromY": null, "toX": null, "toY": null, "label": null, "value": null, "title": null}]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 1)
            guard case .selectMenuItem(let path, let bundleID) = actions[0] else {
                Issue.record("Expected .selectMenuItem")
                return
            }
            #expect(path == ["File", "Save As…"])
            #expect(bundleID == "")
        }

        @Test("parse Tier 1 app-control actions")
        func parseAppControlActions() throws {
            let json = """
            {"actions": [
                {"type": "openURL", "url": "https://example.com"},
                {"type": "activateApp", "name": "Safari"},
                {"type": "quitApp", "name": "TextEdit"},
                {"type": "getFrontmostApp"}
            ]}
            """
            let actions = try decodeActions(from: json)
            #expect(actions.count == 4)

            guard case .openURL(let url) = actions[0] else {
                Issue.record("Expected .openURL")
                return
            }
            #expect(url == "https://example.com")

            guard case .activateApp(let activateName) = actions[1] else {
                Issue.record("Expected .activateApp")
                return
            }
            #expect(activateName == "Safari")

            guard case .quitApp(let quitName) = actions[2] else {
                Issue.record("Expected .quitApp")
                return
            }
            #expect(quitName == "TextEdit")

            guard case .getFrontmostApp = actions[3] else {
                Issue.record("Expected .getFrontmostApp")
                return
            }
        }

        @Test("Vision parser supports Tier 1 app-control actions")
        func visionParserSupportsAppControlActions() {
            let dictionaries: [[String: Any]] = [
                ["type": "openURL", "url": "https://example.com"],
                ["type": "activateApp", "name": "Safari"],
                ["type": "quitApp", "name": "TextEdit"],
                ["type": "getFrontmostApp"]
            ]
            let actions = dictionaries.compactMap(OpenAIVisionBackend.parseAction)
            #expect(actions.count == 4)

            guard case .openURL(let url) = actions[0] else {
                Issue.record("Expected .openURL")
                return
            }
            #expect(url == "https://example.com")

            guard case .activateApp(let activateName) = actions[1],
                  case .quitApp(let quitName) = actions[2],
                  case .getFrontmostApp = actions[3] else {
                Issue.record("Expected all Tier 1 app-control actions")
                return
            }
            #expect(activateName == "Safari")
            #expect(quitName == "TextEdit")
        }
    }

    // MARK: - BasicAction to Action Conversion Tests

    @Suite("BasicAction to Action Conversion")
    struct ConversionTests {

        @Test("write converts to Action.write")
        func writeConversion() {
            let basic = BasicAction.write(text: "test")
            let action = basic.toAction()
            guard case .write(let text, _) = action else {
                Issue.record("Expected Action.write")
                return
            }
            #expect(text == "test")
        }

        @Test("move converts to Action.move with correct CGPoint")
        func moveConversion() {
            let basic = BasicAction.move(x: 100, y: 200)
            let action = basic.toAction()
            guard case .move(let point) = action else {
                Issue.record("Expected Action.move")
                return
            }
            #expect(point.x == 100)
            #expect(point.y == 200)
        }

        @Test("keyShortcut with valid keys maps correctly")
        func keyShortcutValidKeys() {
            let basic = BasicAction.keyShortcut(keys: ["command", "c"])
            let action = basic.toAction()
            guard case .keyShortcut(let keys) = action else {
                Issue.record("Expected Action.keyShortcut")
                return
            }
            #expect(keys == [.command, .c])
        }

        @Test("keyShortcut with invalid keys falls back to wait(0)")
        func keyShortcutInvalidKeys() {
            let basic = BasicAction.keyShortcut(keys: ["invalidkey123"])
            let action = basic.toAction()
            guard case .wait(let duration) = action else {
                Issue.record("Expected Action.wait(0) for invalid keys")
                return
            }
            #expect(duration == 0)
        }

        @Test("pressButton with bundleID maps to .bundleID scope")
        func pressButtonWithBundleID() {
            let basic = BasicAction.pressButton(label: "Save", bundleID: "com.apple.TextEdit")
            let action = basic.toAction()
            guard case .pressButton(let label, let app, let exact, let axOnly) = action else {
                Issue.record("Expected Action.pressButton")
                return
            }
            #expect(label == "Save")
            #expect(exact == false)
            #expect(axOnly == false)
            guard case .bundleID(let id) = app else {
                Issue.record("Expected .bundleID scope, got \(app)")
                return
            }
            #expect(id == "com.apple.TextEdit")
        }

        @Test("pressButton with empty bundleID maps to .frontmost")
        func pressButtonFrontmost() {
            let basic = BasicAction.pressButton(label: "OK", bundleID: "")
            let action = basic.toAction()
            guard case .pressButton(_, let app, _, _) = action else {
                Issue.record("Expected Action.pressButton")
                return
            }
            guard case .frontmost = app else {
                Issue.record("Expected .frontmost scope, got \(app)")
                return
            }
        }

        @Test("setTextField with empty label converts to nil")
        func setTextFieldEmptyLabel() {
            let basic = BasicAction.setTextField(label: "", value: "hello", bundleID: "")
            let action = basic.toAction()
            guard case .setTextField(let label, _, let value, _, _) = action else {
                Issue.record("Expected Action.setTextField")
                return
            }
            #expect(label == nil)
            #expect(value == "hello")
        }

        @Test("selectMenuItem preserves path and scope")
        func selectMenuItemConversion() {
            let basic = BasicAction.selectMenuItem(path: ["File", "New"], bundleID: "com.apple.TextEdit")
            let action = basic.toAction()
            guard case .selectMenuItem(let path, let app, _) = action else {
                Issue.record("Expected Action.selectMenuItem")
                return
            }
            #expect(path == ["File", "New"])
            guard case .bundleID(let id) = app else {
                Issue.record("Expected .bundleID")
                return
            }
            #expect(id == "com.apple.TextEdit")
        }

        @Test("raiseWindow preserves title")
        func raiseWindowConversion() {
            let basic = BasicAction.raiseWindow(title: "Untitled", bundleID: "")
            let action = basic.toAction()
            guard case .raiseWindow(let title, _, _) = action else {
                Issue.record("Expected Action.raiseWindow")
                return
            }
            #expect(title == "Untitled")
        }

        @Test("openURL converts to native Action.openURL")
        func openURLConversion() {
            let action = BasicAction.openURL(url: "https://example.com/path?q=swift").toAction()
            guard case .openURL(let url) = action else {
                Issue.record("Expected Action.openURL")
                return
            }
            #expect(url.absoluteString == "https://example.com/path?q=swift")
        }

        @Test("openURL rejects non-HTTP schemes")
        func openURLRejectsUnsafeScheme() {
            let action = BasicAction.openURL(url: "javascript:alert(1)").toAction()
            guard case .wait(let duration) = action else {
                Issue.record("Expected Action.wait for invalid URL")
                return
            }
            #expect(duration == 0)
        }

        @Test("activateApp converts to native Action.activateApp")
        func activateAppConversion() {
            let action = BasicAction.activateApp(name: "Safari").toAction()
            guard case .activateApp(let name) = action else {
                Issue.record("Expected Action.activateApp")
                return
            }
            #expect(name == "Safari")
        }

        @Test("quitApp converts to native Action.quitApp")
        func quitAppConversion() {
            let action = BasicAction.quitApp(name: "Google Chrome").toAction()
            guard case .quitApp(let name) = action else {
                Issue.record("Expected Action.quitApp")
                return
            }
            #expect(name == "Google Chrome")
        }

        @Test("app names are passed as data without AppleScript interpolation")
        func appNamesRemainData() {
            let name = #"Example "App" & Tools"#

            guard case .activateApp(let activatedName) =
                    BasicAction.activateApp(name: name).toAction(),
                  case .quitApp(let quitName) =
                    BasicAction.quitApp(name: name).toAction() else {
                Issue.record("Expected native app-control actions")
                return
            }
            #expect(activatedName == name)
            #expect(quitName == name)
        }

        @Test("app actions reject path traversal")
        func appActionsRejectPathTraversal() {
            let action = BasicAction.activateApp(name: "../Calculator").toAction()
            guard case .wait(let duration) = action else {
                Issue.record("Expected Action.wait for an invalid app path")
                return
            }
            #expect(duration == 0)
        }

        @Test("getFrontmostApp converts to native action")
        func getFrontmostAppConversion() {
            let action = BasicAction.getFrontmostApp.toAction()
            guard case .getFrontmostApp = action else {
                Issue.record("Expected Action.getFrontmostApp")
                return
            }
        }
    }

    // MARK: - Backend and API Tests

    @Suite("Backend and API")
    struct BackendTests {

        @Test("OpenAIBackend is always available")
        func openAIBackendAvailable() {
            let backend = OpenAIBackend(apiKey: "test-key")
            #expect(backend.isAvailable)
            #expect(backend.unavailableReason == nil)
        }

        @Test("ActionGenerator with OpenAI key creates working instance")
        func generatorWithOpenAIKey() {
            let generator = ActionGenerator(openAIKey: "test-key", model: "gpt-4o")
            #expect(generator.backend.isAvailable)
        }

        @Test("ActionGenerator with custom backend")
        func generatorWithCustomBackend() {
            let backend = OpenAIBackend(apiKey: "test-key")
            let generator = ActionGenerator(backend: backend)
            #expect(generator.backend.isAvailable)
        }

        @Test("OpenAI action schema includes Tier 1 app-control fields")
        func actionSchemaIncludesAppControlFields() {
            let schema = OpenAIVisionBackend.actionItemSchemaDict
            let properties = schema["properties"] as? [String: Any]
            let required = schema["required"] as? [String]
            let typeProperty = properties?["type"] as? [String: Any]
            let actionTypes = typeProperty?["enum"] as? [String]

            #expect(properties?["url"] != nil)
            #expect(properties?["name"] != nil)
            #expect(required?.contains("url") == true)
            #expect(required?.contains("name") == true)
            #expect(actionTypes?.contains("openURL") == true)
            #expect(actionTypes?.contains("activateApp") == true)
            #expect(actionTypes?.contains("quitApp") == true)
            #expect(actionTypes?.contains("getFrontmostApp") == true)
        }
    }
}

// MARK: - Helpers

private func roundTrip(_ action: BasicAction) throws -> BasicAction {
    let data = try JSONEncoder().encode(action)
    return try JSONDecoder().decode(BasicAction.self, from: data)
}

private struct ActionsWrapper: Codable {
    let actions: [BasicAction]
}

private func decodeActions(from json: String) throws -> [BasicAction] {
    let data = json.data(using: .utf8)!
    return try JSONDecoder().decode(ActionsWrapper.self, from: data).actions
}
