import AppKit
import SwiftUI

struct ObservedInputEvent: Identifiable {
    let id = UUID()
    let sequence: Int
    let timestamp: Date
    let name: String
    let details: String
    let modifiers: String
    let sourcePID: Int64?
}

@MainActor
@Observable
final class InputEventObserverViewModel {
    private(set) var events: [ObservedInputEvent] = []
    private(set) var eventCounts: [String: Int] = [:]
    private(set) var currentModifiers = "none"
    private(set) var latestPointerPosition: CGPoint?
    private(set) var isObserving = false

    private var monitor: Any?
    private var sequence = 0

    func startObserving() {
        guard monitor == nil else { return }

        NSApp.windows.forEach { $0.acceptsMouseMovedEvents = true }
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .scrollWheel,
            .flagsChanged,
            .keyDown,
            .keyUp
        ]

        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.record(event)
            return event
        }
        isObserving = monitor != nil
    }

    func stopObserving() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isObserving = false
    }

    func clear() {
        events.removeAll()
        eventCounts.removeAll()
        sequence = 0
    }

    private func record(_ event: NSEvent) {
        let name = eventName(event.type)
        let modifiers = modifierDescription(event.modifierFlags)
        let point = event.cgEvent?.location

        if event.type == .mouseMoved, let point {
            latestPointerPosition = point
        }
        currentModifiers = modifiers
        eventCounts[name, default: 0] += 1
        sequence += 1

        let record = ObservedInputEvent(
            sequence: sequence,
            timestamp: Date(),
            name: name,
            details: eventDetails(event, point: point),
            modifiers: modifiers,
            sourcePID: event.cgEvent?.getIntegerValueField(.eventSourceUnixProcessID)
        )

        // Human pointer movement can generate hundreds of events. Keep the latest
        // movement visible without allowing it to bury click and scroll events.
        if event.type == .mouseMoved,
           let first = events.first,
           first.name == "mouseMoved",
           record.timestamp.timeIntervalSince(first.timestamp) < 0.05 {
            events[0] = record
        } else {
            events.insert(record, at: 0)
        }

        if events.count > 80 {
            events.removeLast(events.count - 80)
        }
    }

    private func eventName(_ type: NSEvent.EventType) -> String {
        switch type {
        case .mouseMoved: "mouseMoved"
        case .leftMouseDown: "leftMouseDown"
        case .leftMouseUp: "leftMouseUp"
        case .rightMouseDown: "rightMouseDown"
        case .rightMouseUp: "rightMouseUp"
        case .scrollWheel: "scrollWheel"
        case .flagsChanged: "flagsChanged"
        case .keyDown: "keyDown"
        case .keyUp: "keyUp"
        default: "type(\(type.rawValue))"
        }
    }

    private func eventDetails(_ event: NSEvent, point: CGPoint?) -> String {
        let location = point.map { "x=\(Int($0.x)) y=\(Int($0.y))" } ?? "location unavailable"
        switch event.type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp:
            return "\(location) clickCount=\(event.clickCount)"
        case .mouseMoved:
            return location
        case .scrollWheel:
            return "\(location) dx=\(format(event.scrollingDeltaX)) dy=\(format(event.scrollingDeltaY)) precise=\(event.hasPreciseScrollingDeltas)"
        case .flagsChanged, .keyDown, .keyUp:
            return "keyCode=\(event.keyCode) characters=\(event.charactersIgnoringModifiers ?? "-")"
        default:
            return location
        }
    }

    private func modifierDescription(_ flags: NSEvent.ModifierFlags) -> String {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var names: [String] = []
        if flags.contains(.capsLock) { names.append("capsLock") }
        if flags.contains(.shift) { names.append("shift") }
        if flags.contains(.control) { names.append("control") }
        if flags.contains(.option) { names.append("option") }
        if flags.contains(.command) { names.append("command") }
        if flags.contains(.function) { names.append("fn") }
        return names.isEmpty ? "none" : names.joined(separator: "+")
    }

    private func format(_ value: CGFloat) -> String {
        String(format: "%.2f", Double(value))
    }
}
