import CoreGraphics

enum InputEvent {
    static let clickDelayNanoseconds: UInt64 = 60_000_000

    static func currentFlags() -> CGEventFlags {
        CGEventSource.flagsState(.hidSystemState)
    }

    static func modifierFlag(for key: Key) -> CGEventFlags? {
        switch key {
        case .command:
            return .maskCommand
        case .shift, .rightShift:
            return .maskShift
        case .option, .rightOption:
            return .maskAlternate
        case .control, .rightControl:
            return .maskControl
        case .function:
            return .maskSecondaryFn
        default:
            return nil
        }
    }

    static func modifierDeviceFlag(for key: Key) -> CGEventFlags? {
        switch key {
        case .control:
            return CGEventFlags(rawValue: 0x0000_0001)
        case .shift:
            return CGEventFlags(rawValue: 0x0000_0002)
        case .rightShift:
            return CGEventFlags(rawValue: 0x0000_0004)
        case .command:
            return CGEventFlags(rawValue: 0x0000_0008)
        case .option:
            return CGEventFlags(rawValue: 0x0000_0020)
        case .rightOption:
            return CGEventFlags(rawValue: 0x0000_0040)
        case .rightControl:
            return CGEventFlags(rawValue: 0x0000_2000)
        default:
            return nil
        }
    }

    static func pairedModifierDeviceFlag(for key: Key) -> CGEventFlags? {
        switch key {
        case .shift:
            return modifierDeviceFlag(for: .rightShift)
        case .rightShift:
            return modifierDeviceFlag(for: .shift)
        case .option:
            return modifierDeviceFlag(for: .rightOption)
        case .rightOption:
            return modifierDeviceFlag(for: .option)
        case .control:
            return modifierDeviceFlag(for: .rightControl)
        case .rightControl:
            return modifierDeviceFlag(for: .control)
        default:
            return nil
        }
    }

    static func adjustedFlags(
        for key: Key,
        down: Bool,
        currentFlags: CGEventFlags
    ) -> CGEventFlags {
        guard let flag = modifierFlag(for: key) else {
            return currentFlags
        }

        let deviceFlag = modifierDeviceFlag(for: key) ?? []
        let keyFlags = flag.union(deviceFlag)

        if down {
            return currentFlags.union(keyFlags)
        }

        var adjusted = currentFlags.subtracting(keyFlags)
        if let pairedFlag = pairedModifierDeviceFlag(for: key),
           adjusted.contains(pairedFlag) {
            adjusted.formUnion(flag)
        }
        return adjusted
    }

    static func keyboardEvent(
        for key: Key,
        keycode: CGKeyCode,
        down: Bool,
        currentFlags: CGEventFlags? = nil,
        source: CGEventSource? = nil
    ) -> CGEvent? {
        let eventSource = source ?? CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(keyboardEventSource: eventSource, virtualKey: keycode, keyDown: down)
        guard let event else { return nil }

        let existingFlags = currentFlags ?? self.currentFlags()
        if let modifierFlag = modifierFlag(for: key) {
            var flags = adjustedFlags(for: key, down: down, currentFlags: existingFlags)
            if down {
                flags.formUnion(event.flags)
            } else {
                let deviceFlag = modifierDeviceFlag(for: key) ?? []
                flags.formUnion(event.flags.subtracting(modifierFlag.union(deviceFlag)))
            }
            event.flags = flags
        } else {
            event.flags = existingFlags.union(event.flags)
        }
        return event
    }

    static func mouseEvent(
        type: CGEventType,
        position: CGPoint,
        button: CGMouseButton,
        clickCount: Int64 = 0,
        flags: CGEventFlags? = nil,
        source: CGEventSource? = nil
    ) -> CGEvent? {
        let eventSource = source ?? CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: type,
            mouseCursorPosition: position,
            mouseButton: button
        )
        event?.flags = flags ?? currentFlags()
        event?.setIntegerValueField(.mouseEventClickState, value: clickCount)
        return event
    }

    static func mouseMovedEvent(
        at position: CGPoint,
        flags: CGEventFlags? = nil,
        source: CGEventSource? = nil
    ) -> CGEvent? {
        mouseEvent(
            type: .mouseMoved,
            position: position,
            button: .left,
            flags: flags,
            source: source
        )
    }

    static func scrollEvent(
        vertical: Int32,
        horizontal: Int32,
        at position: CGPoint,
        flags: CGEventFlags? = nil,
        source: CGEventSource? = nil
    ) -> CGEvent? {
        let eventSource = source ?? CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(
            scrollWheelEvent2Source: eventSource,
            units: .line,
            wheelCount: horizontal == 0 ? 1 : 2,
            wheel1: vertical,
            wheel2: horizontal,
            wheel3: 0
        )
        event?.location = position
        event?.flags = flags ?? currentFlags()
        return event
    }

    static func scrollDeltas(clicks: Int) -> [Int32] {
        guard clicks != 0 else { return [] }

        var remaining = clicks
        var deltas: [Int32] = []
        while remaining != 0 {
            let delta = min(10, max(-10, remaining))
            deltas.append(Int32(delta))
            remaining -= delta
        }
        return deltas
    }

    static func postMouseMoved(at position: CGPoint, source: CGEventSource? = nil) {
        mouseMovedEvent(at: position, source: source)?.post(tap: .cghidEventTap)
    }
}
