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
