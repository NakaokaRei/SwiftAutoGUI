//
//  ScreenContextTests.swift
//  SwiftAutoGUITests
//

import Foundation
import Testing
@testable import SwiftAutoGUI

@Suite("ScreenContext Tests")
struct ScreenContextTests {

    // MARK: - InputSourceInfo Tests

    @Suite("InputSourceInfo")
    struct InputSourceInfoTests {

        @Test("round-trip encoding/decoding")
        func roundTrip() throws {
            let info = InputSourceInfo(id: "com.apple.keylayout.US", localizedName: "U.S.")
            let data = try JSONEncoder().encode(info)
            let decoded = try JSONDecoder().decode(InputSourceInfo.self, from: data)
            #expect(decoded.id == info.id)
            #expect(decoded.localizedName == info.localizedName)
        }
    }

    // MARK: - CodableRect Tests

    @Suite("CodableRect")
    struct CodableRectTests {

        @Test("round-trip encoding/decoding")
        func roundTrip() throws {
            let rect = CodableRect(x: 10, y: 20, width: 300, height: 400)
            let data = try JSONEncoder().encode(rect)
            let decoded = try JSONDecoder().decode(CodableRect.self, from: data)
            #expect(decoded == rect)
        }

        @Test("init from CGRect")
        func initFromCGRect() {
            let cgRect = CGRect(x: 1.5, y: 2.5, width: 100.0, height: 200.0)
            let rect = CodableRect(cgRect)
            #expect(rect.x == 1.5)
            #expect(rect.y == 2.5)
            #expect(rect.width == 100.0)
            #expect(rect.height == 200.0)
        }

        @Test("cgRect conversion")
        func cgRectConversion() {
            let rect = CodableRect(x: 5, y: 10, width: 50, height: 60)
            let cgRect = rect.cgRect
            #expect(cgRect.origin.x == 5)
            #expect(cgRect.origin.y == 10)
            #expect(cgRect.size.width == 50)
            #expect(cgRect.size.height == 60)
        }
    }

    // MARK: - Formatting Tests

    @Suite("ScreenContext Formatting")
    struct FormattingTests {

        @Test("formats frontmost app")
        func frontmostApp() {
            let context = ScreenContext(
                frontmostApp: AppInfo(name: "Safari", bundleIdentifier: "com.apple.Safari", pid: 123),
                visibleWindows: [],
                focusedWindowAXTree: nil
            )
            let output = context.formatted()
            #expect(output.contains("Frontmost app: Safari (com.apple.Safari)"))
        }

        @Test("formats frontmost app without bundle identifier")
        func frontmostAppNoBundleId() {
            let context = ScreenContext(
                frontmostApp: AppInfo(name: "MyApp", bundleIdentifier: nil, pid: 456),
                visibleWindows: [],
                focusedWindowAXTree: nil
            )
            let output = context.formatted()
            #expect(output.contains("Frontmost app: MyApp"))
            #expect(!output.contains("("))
        }

        @Test("formats visible windows")
        func visibleWindows() {
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [
                    WindowInfo(
                        title: "Documents",
                        ownerApp: "Finder",
                        bounds: CodableRect(x: 0, y: 25, width: 1200, height: 775),
                        layer: 0,
                        isOnScreen: true
                    ),
                    WindowInfo(
                        title: "Terminal",
                        ownerApp: "Terminal",
                        bounds: CodableRect(x: 200, y: 100, width: 800, height: 600),
                        layer: 0,
                        isOnScreen: true
                    ),
                ],
                focusedWindowAXTree: nil
            )
            let output = context.formatted()
            #expect(output.contains("Visible windows:"))
            #expect(output.contains("[0] \"Documents\" - Finder @ {0,25 1200x775}"))
            #expect(output.contains("[1] \"Terminal\" - Terminal @ {200,100 800x600}"))
        }

        @Test("formats untitled window")
        func untitledWindow() {
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [
                    WindowInfo(
                        title: nil,
                        ownerApp: "Finder",
                        bounds: CodableRect(x: 0, y: 0, width: 100, height: 100),
                        layer: 0,
                        isOnScreen: true
                    ),
                ],
                focusedWindowAXTree: nil
            )
            let output = context.formatted()
            #expect(output.contains("(untitled)"))
        }

        @Test("formats AX tree with children")
        func axTreeWithChildren() {
            let tree = AXNode(
                role: "AXWindow",
                label: "Documents",
                value: nil,
                frame: CodableRect(x: 0, y: 25, width: 1200, height: 775),
                isEnabled: true,
                children: [
                    AXNode(
                        role: "AXButton",
                        label: "Back",
                        value: nil,
                        frame: CodableRect(x: 10, y: 30, width: 28, height: 28),
                        isEnabled: true,
                        children: []
                    ),
                    AXNode(
                        role: "AXButton",
                        label: "Forward",
                        value: nil,
                        frame: CodableRect(x: 42, y: 30, width: 28, height: 28),
                        isEnabled: false,
                        children: []
                    ),
                ]
            )
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [],
                focusedWindowAXTree: tree
            )
            let output = context.formatted()
            #expect(output.contains("Focused window AX tree:"))
            #expect(output.contains("AXWindow \"Documents\" {0,25 1200x775}"))
            #expect(output.contains("AXButton \"Back\" {10,30 28x28}"))
            #expect(output.contains("AXButton \"Forward\" {42,30 28x28} disabled"))
        }

        @Test("formats AX node with value")
        func axNodeWithValue() {
            let node = AXNode(
                role: "AXTextField",
                label: "Search",
                value: "hello world",
                frame: CodableRect(x: 100, y: 50, width: 200, height: 22),
                isEnabled: true,
                children: []
            )
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [],
                focusedWindowAXTree: node
            )
            let output = context.formatted()
            #expect(output.contains("AXTextField \"Search\" value=\"hello world\" {100,50 200x22}"))
        }

        @Test("formats pruned subtree with [...]")
        func prunedSubtree() {
            let node = AXNode(
                role: "AXGroup",
                label: nil,
                value: nil,
                frame: CodableRect(x: 0, y: 0, width: 500, height: 500),
                isEnabled: true,
                children: nil // nil = pruned
            )
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [],
                focusedWindowAXTree: node
            )
            let output = context.formatted()
            #expect(output.contains("[...]"))
        }

        @Test("formats keyboard input source")
        func keyboardInputSource() {
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [],
                focusedWindowAXTree: nil,
                keyboardInputSource: InputSourceInfo(
                    id: "com.apple.keylayout.US",
                    localizedName: "U.S."
                )
            )
            let output = context.formatted()
            #expect(output.contains("Keyboard input source: U.S. (com.apple.keylayout.US)"))
        }

        @Test("omits keyboard input source when nil")
        func noKeyboardInputSource() {
            let context = ScreenContext(
                frontmostApp: nil,
                visibleWindows: [],
                focusedWindowAXTree: nil,
                keyboardInputSource: nil
            )
            let output = context.formatted()
            #expect(!output.contains("Keyboard input source"))
        }

        @Test("full context output combines all sections")
        func fullContext() {
            let context = ScreenContext(
                frontmostApp: AppInfo(name: "Finder", bundleIdentifier: "com.apple.finder", pid: 312),
                visibleWindows: [
                    WindowInfo(
                        title: "Documents",
                        ownerApp: "Finder",
                        bounds: CodableRect(x: 0, y: 25, width: 1200, height: 775),
                        layer: 0,
                        isOnScreen: true
                    ),
                ],
                focusedWindowAXTree: AXNode(
                    role: "AXWindow",
                    label: "Documents",
                    value: nil,
                    frame: CodableRect(x: 0, y: 25, width: 1200, height: 775),
                    isEnabled: true,
                    children: []
                )
            )
            let output = context.formatted()
            // All three sections present
            #expect(output.contains("Frontmost app:"))
            #expect(output.contains("Visible windows:"))
            #expect(output.contains("Focused window AX tree:"))
        }
    }
}
