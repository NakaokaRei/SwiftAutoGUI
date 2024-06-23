import Foundation
import AppKit

public class SwiftAutoGUI {

    // MARK: Key Event

    /// Send a key shortcut
    ///
    /// - Parameter keys: The keys to be pressed. The order of the keys is the order of pressing.
    /// For example, if you want to press `command + c`, you should call `sendKeyShortcut([.command, .c])`. The details of Key is in ``Key``
    ///
    /// Example
    /// ```swift
    /// // Send ctrl + ←
    /// import SwiftAutoGUI
    /// SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
    ///
    /// // Send sound up
    /// SwiftAutoGUI.keyDown(.soundUp)
    /// SwiftAutoGUI.keyUp(.soundUp)
    /// ```
    public static func sendKeyShortcut(_ keys: [Key]) {
        for key in keys {
            keyDown(key)
        }
        for key in keys.reversed() {
            keyUp(key)
        }
    }

    /// Press a key
    ///
    /// - Parameter key: The key to be pressed. The details of Key is in ``Key``
    public static func keyDown(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: true)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: true)
        }
    }

    /// Release a key
    ///
    /// - Parameter key: The key to be released.
    public static func keyUp(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: false)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: false)
        }
    }

    /// Press a key and release it
    ///
    /// - Parameter key: The key to be pressed and released. The details of Key is in  `normalKeycode` of ``Key``
    private static func normalKeyEvent(_ key: CGKeyCode, down: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
        event?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Press a special key and release it
    ///
    /// - Parameter key: The key to be pressed and released. The details of Key is in  `specialKeycode` of ``Key``
    private static func specialKeyEvent(_ key: Int32, down: Bool) {
        let modifierFlags = NSEvent.ModifierFlags(rawValue: down ? 0xA00 : 0xB00)
        let nsEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint(x: 0, y: 0),
            modifierFlags: modifierFlags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((key << 16)) | ((down ? 0xA : 0xB) << 8),
            data2: -1
        )
        let cgEvent = nsEvent?.cgEvent
        cgEvent?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
    }

    // MARK: Mouse Event

    /// Move mouse by dx, dy from the current location
    ///
    /// - Parameters:
    ///     - dx: The distance to move in the x-axis
    ///     - dy: The distance to move in the y-axis
    public static func moveMouse(dx: CGFloat, dy: CGFloat) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x-CGFloat(dx), y: mouseLoc.y + CGFloat(dy))
        CGDisplayMoveCursorToPoint(0, newLoc)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Move the mouse to a specific position
    /// - Parameter to: This parameter is the `CGWindow` coordinate.
    public static func move(to: CGPoint) {
        CGDisplayMoveCursorToPoint(0, to)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Press the left mouse button at a current position
    public static func leftClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        leftClickDown(position: mouseLoc)
        leftClickUp(position: mouseLoc)
    }

    /// Press the left mouse button at a current position
    public static func rightClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        rightClickDown(position: mouseLoc)
        rightClickUp(position: mouseLoc)
    }

    /// Dragg the left mouse button from a position to another position
    ///
    /// - Parameters:
    ///    - to: The position to drag to
    ///    - from: The position to drag from
    public static func leftDragged(to: CGPoint, from: CGPoint) {
        leftClickDown(position: from)
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.leftMouseDragged,
                            mouseCursorPosition: to, mouseButton: CGMouseButton.left)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
        leftClickUp(position: to)
    }

    /// Scroll the mouse wheel vertically
    ///
    /// - Parameter clicks: The number of clicks to scroll. Positive value means scroll up, negative value means scroll down.
    public static func vscroll(clicks: Int) {
        for _ in 0...Int(abs(clicks) / 10) {
            let scrollEvent = CGEvent(
                scrollWheelEvent2Source: nil,
                units: .line,
                wheelCount: 1,
                wheel1: clicks >= 0 ? 10 : -10,
                wheel2: 0,
                wheel3: 0
            )
            scrollEvent?.post(tap: .cghidEventTap)
        }

        let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: Int32(clicks >= 0 ? clicks % 10 : -1 * (-clicks % 10)),
            wheel2: 0,
            wheel3: 0
        )
        scrollEvent?.post(tap: .cghidEventTap)
    }

    /// Scroll the mouse wheel horizontally
    ///
    /// - Parameter clicks: The number of clicks to scroll. Positive value means scroll left, negative value means scroll right.
    public static func hscroll(clicks: Int) {
        for _ in 0...Int(abs(clicks) / 10) {
            let scrollEvent = CGEvent(
                scrollWheelEvent2Source: nil,
                units: .line,
                wheelCount: 2,
                wheel1: 0,
                wheel2: clicks >= 0 ? 10 : -10,
                wheel3: 0
            )
            scrollEvent?.post(tap: .cghidEventTap)
        }

        let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 2,
            wheel1: 0,
            wheel2: Int32(clicks >= 0 ? clicks % 10 : -1 * (-clicks % 10)),
            wheel3: 0
        )
        scrollEvent?.post(tap: .cghidEventTap)
    }

    private static func leftClickDown(position: CGPoint) {
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.leftMouseDown,
                            mouseCursorPosition: position, mouseButton: CGMouseButton.left)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private static func leftClickUp(position: CGPoint) {
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.leftMouseUp,
                            mouseCursorPosition: position, mouseButton: CGMouseButton.left)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private static func rightClickDown(position: CGPoint) {
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.rightMouseDown,
                            mouseCursorPosition: position, mouseButton: CGMouseButton.right)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private static func rightClickUp(position: CGPoint) {
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.rightMouseUp,
                            mouseCursorPosition: position, mouseButton: CGMouseButton.right)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
