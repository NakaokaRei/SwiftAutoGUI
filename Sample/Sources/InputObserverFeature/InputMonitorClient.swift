import AppKit
import ComposableArchitecture

struct ObservedInputEvent: Equatable, Identifiable, Sendable {
    var id = UUID()
    var sequence = 0
    var timestamp: Date
    var name: String
    var details: String
    var modifiers: String
    var sourcePID: Int64?
    var point: CGPoint?
}

struct InputMonitorClient: Sendable {
    var events: @MainActor @Sendable () -> AsyncStream<ObservedInputEvent>
}
extension InputMonitorClient: DependencyKey {
    static let liveValue = Self {
        AsyncStream { continuation in
            let owner = MonitorOwner(continuation: continuation)
            continuation.onTermination = { _ in Task { @MainActor in owner.stop() } }
        }
    }
    static let testValue = Self { AsyncStream { $0.finish() } }
}
extension DependencyValues {
    var inputMonitorClient: InputMonitorClient {
        get { self[InputMonitorClient.self] }
        set { self[InputMonitorClient.self] = newValue }
    }
}

@MainActor
private final class MonitorOwner {
    private var monitor: Any?
    private var windows: [(NSWindow, Bool)] = []
    init(continuation: AsyncStream<ObservedInputEvent>.Continuation) {
        windows = NSApp.windows.map { ($0, $0.acceptsMouseMovedEvents) }
        windows.forEach { $0.0.acceptsMouseMovedEvents = true }
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .scrollWheel,
            .flagsChanged, .keyDown, .keyUp,
        ]
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            let point = event.cgEvent?.location
            continuation.yield(
                ObservedInputEvent(
                    timestamp: Date(), name: Self.eventName(event.type),
                    details: Self.eventDetails(event, point: point),
                    modifiers: Self.modifierDescription(event.modifierFlags),
                    sourcePID: event.cgEvent?.getIntegerValueField(.eventSourceUnixProcessID),
                    point: point
                ))
            return event
        }
        if monitor == nil {
            stop()
            continuation.finish()
        }
    }
    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        windows.forEach { $0.0.acceptsMouseMovedEvents = $0.1 }
        windows = []
    }
    private static func eventName(_ type: NSEvent.EventType) -> String {
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

    private static func eventDetails(_ event: NSEvent, point: CGPoint?) -> String {
        let location = point.map { "x=\(Int($0.x)) y=\(Int($0.y))" } ?? "location unavailable"
        switch event.type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp:
            return "\(location) clickCount=\(event.clickCount)"
        case .mouseMoved:
            return location
        case .scrollWheel:
            return
                "\(location) dx=\(format(event.scrollingDeltaX)) dy=\(format(event.scrollingDeltaY)) precise=\(event.hasPreciseScrollingDeltas)"
        case .flagsChanged, .keyDown, .keyUp:
            return "keyCode=\(event.keyCode) characters=\(event.charactersIgnoringModifiers ?? "-")"
        default:
            return location
        }
    }

    private static func modifierDescription(_ flags: NSEvent.ModifierFlags) -> String {
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

    private static func format(_ value: CGFloat) -> String {
        String(format: "%.2f", Double(value))
    }
}
