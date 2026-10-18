import AppKit
import ComposableArchitecture
import IssueReporting
import SwiftAutoGUI

public typealias AutomationAction = Action

public struct AutomationClient: Sendable {
    public struct Output: Equatable, Sendable {
        public var text: String?
        public var imageData: Data?
        public var color: [Double]?
        public var size: CGSize?
        public var rects: [CGRect] = []
        public var point: CGPoint?
        public var success = false
        public init(text: String? = nil) { self.text = text }
    }
    public var execute: @MainActor @Sendable (AutomationAction) async -> Output
    public var position: @MainActor @Sendable () -> CGPoint
    public var layout: @MainActor @Sendable (KeyboardLayout?) -> KeyboardLayout
    public var detectedLayout: @MainActor @Sendable () -> KeyboardLayout
    public var resetLayout: @MainActor @Sendable () -> KeyboardLayout
}
extension AutomationClient: DependencyKey {
    public static let liveValue = Self(
        execute: { action in
            guard !Task.isCancelled else { return Output() }
            let value = await action.execute()
            var output = Output(text: value as? String)
            output.imageData = (value as? NSImage)?.tiffRepresentation
            if let color = (value as? NSColor)?.usingColorSpace(.deviceRGB) {
                output.color = [
                    color.redComponent, color.greenComponent, color.blueComponent,
                    color.alphaComponent,
                ]
            }
            if let size = value as? (CGFloat, CGFloat) {
                output.size = CGSize(width: size.0, height: size.1)
            }
            output.rects = (value as? [CGRect]) ?? (value as? CGRect).map { [$0] } ?? []
            output.point = value as? CGPoint
            output.success = (value as? Bool) ?? false
            return output
        },
        position: { SwiftAutoGUI.position() },
        layout: { layout in
            if let layout { SwiftAutoGUI.currentLayout = layout }
            return SwiftAutoGUI.currentLayout
        },
        detectedLayout: { KeyboardLayout.detect() },
        resetLayout: {
            SwiftAutoGUI.resetLayoutToAutoDetect()
            return SwiftAutoGUI.currentLayout
        }
    )
    public static let testValue = Self(
        execute: { _ in
            reportIssue("Unimplemented AutomationClient.execute")
            return Output()
        },
        position: { .zero }, layout: { $0 ?? .us }, detectedLayout: { .us }, resetLayout: { .us }
    )
}
extension DependencyValues {
    public var automationClient: AutomationClient {
        get { self[AutomationClient.self] }
        set { self[AutomationClient.self] = newValue }
    }
}
