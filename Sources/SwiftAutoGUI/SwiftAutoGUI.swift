import Foundation
import AppKit

public class SwiftAutoGUI {

    public init() {}

    // MARK: Key Event

    public static func sendKeyShortcut(_ keys: [Key]) {
        for key in keys {
            keyDown(key)
        }
        for key in keys.reversed() {
            keyUp(key)
        }
    }

    public static func keyDown(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: true)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: true)
        }
    }

    public static func keyUp(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: false)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: false)
        }
    }

    private static func normalKeyEvent(_ key: CGKeyCode, down: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
        event?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
    }

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

    public static func moveMouse(dx: CGFloat, dy: CGFloat) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x-CGFloat(dx), y: mouseLoc.y + CGFloat(dy))
        CGDisplayMoveCursorToPoint(0, newLoc)
        Thread.sleep(forTimeInterval: 0.01)
    }

    public static func move(to: CGPoint) {
        CGDisplayMoveCursorToPoint(0, to)
        Thread.sleep(forTimeInterval: 0.01)
    }

    public static func leftClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        leftClickDown(position: mouseLoc)
        leftClickUp(position: mouseLoc)
    }

    public static func rightClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        rightClickDown(position: mouseLoc)
        rightClickUp(position: mouseLoc)
    }

    public static func leftDragged(to: CGPoint, from: CGPoint) {
        leftClickDown(position: from)
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.leftMouseDragged,
                            mouseCursorPosition: to, mouseButton: CGMouseButton.left)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
        leftClickUp(position: to)
    }

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
