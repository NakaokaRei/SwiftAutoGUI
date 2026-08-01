import CoreGraphics
import Testing
@testable import SwiftAutoGUI

@Suite("Input Event Tests")
struct InputEventTests {
    @Test("Modifier events use flagsChanged and accumulate flags")
    func modifierEvents() throws {
        let existing: CGEventFlags = [.maskCommand]
        let shiftKeycode = try #require(Key.shift.normalKeycode)
        let down = try #require(InputEvent.keyboardEvent(
            for: .shift,
            keycode: shiftKeycode,
            down: true,
            currentFlags: existing
        ))
        #expect(down.type == .flagsChanged)
        #expect(down.flags.contains(.maskCommand))
        #expect(down.flags.contains(.maskShift))

        let up = try #require(InputEvent.keyboardEvent(
            for: .shift,
            keycode: shiftKeycode,
            down: false,
            currentFlags: down.flags
        ))
        #expect(up.type == .flagsChanged)
        #expect(up.flags.contains(.maskCommand))
        #expect(!up.flags.contains(.maskShift))
    }

    @Test("Ordinary key events retain current modifiers")
    func ordinaryKeyEvent() throws {
        let keycode = try #require(Key.a.normalKeycode)
        let event = try #require(InputEvent.keyboardEvent(
            for: .a,
            keycode: keycode,
            down: true,
            currentFlags: [.maskShift]
        ))
        #expect(event.type == .keyDown)
        #expect(event.flags.contains(.maskShift))
    }

    @Test("Arrow shortcut events preserve automatic keypad flags")
    func arrowShortcutEvent() throws {
        let keycode = try #require(Key.leftArrow.normalKeycode)
        let event = try #require(InputEvent.keyboardEvent(
            for: .leftArrow,
            keycode: keycode,
            down: true,
            currentFlags: [.maskControl]
        ))
        #expect(event.type == .keyDown)
        #expect(event.flags.contains(.maskControl))
        #expect(event.flags.contains(.maskNumericPad))
    }

    @Test("Releasing one side keeps a paired modifier active")
    func pairedModifierRelease() throws {
        let leftShiftDeviceFlag = try #require(InputEvent.modifierDeviceFlag(for: .shift))
        let rightShiftDeviceFlag = try #require(InputEvent.modifierDeviceFlag(for: .rightShift))
        let current: CGEventFlags = [.maskShift, leftShiftDeviceFlag, rightShiftDeviceFlag]
        let adjusted = InputEvent.adjustedFlags(
            for: .shift,
            down: false,
            currentFlags: current
        )
        #expect(adjusted.contains(.maskShift))
        #expect(!adjusted.contains(leftShiftDeviceFlag))
        #expect(adjusted.contains(rightShiftDeviceFlag))
    }

    @Test("Shortcut modifiers preserve device flags on a shared source")
    func shortcutModifierEvents() throws {
        let source = try #require(CGEventSource(stateID: .hidSystemState))
        let keycode = try #require(Key.control.normalKeycode)
        let down = try #require(InputEvent.keyboardEvent(
            for: .control,
            keycode: keycode,
            down: true,
            currentFlags: [],
            source: source
        ))
        #expect(down.type == .flagsChanged)
        #expect(down.flags.contains(.maskControl))
        #expect(down.flags.contains(CGEventFlags(rawValue: 0x0000_0001)))

        let up = try #require(InputEvent.keyboardEvent(
            for: .control,
            keycode: keycode,
            down: false,
            currentFlags: down.flags,
            source: source
        ))
        #expect(up.type == .flagsChanged)
        #expect(!up.flags.contains(.maskControl))
        #expect(!up.flags.contains(CGEventFlags(rawValue: 0x0000_0001)))
    }

    @Test("Mouse events include location, flags, and click count")
    func mouseEvent() throws {
        let point = CGPoint(x: 123, y: 456)
        let event = try #require(InputEvent.mouseEvent(
            type: .rightMouseDown,
            position: point,
            button: .right,
            clickCount: 2,
            flags: [.maskCommand]
        ))
        #expect(event.type == .rightMouseDown)
        #expect(event.location == point)
        #expect(event.flags.contains(.maskCommand))
        #expect(event.getIntegerValueField(.mouseEventClickState) == 2)
    }

    @Test("Scroll events include location, flags, and axes")
    func scrollEvent() throws {
        let point = CGPoint(x: 50, y: 75)
        let event = try #require(InputEvent.scrollEvent(
            vertical: -4,
            horizontal: 3,
            at: point,
            flags: [.maskAlternate]
        ))
        #expect(event.location == point)
        #expect(event.flags.contains(.maskAlternate))
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -4)
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis2) == 3)
    }

    @Test("Scroll deltas preserve the requested total", arguments: [0, 1, -1, 9, -9, 10, -10, 11, -11, 25, -25])
    func scrollDeltas(clicks: Int) {
        let deltas = InputEvent.scrollDeltas(clicks: clicks)
        #expect(deltas.reduce(0) { $0 + Int($1) } == clicks)
        #expect(deltas.allSatisfy { abs($0) <= 10 && $0 != 0 })
        #expect(clicks != 0 || deltas.isEmpty)
    }
}
