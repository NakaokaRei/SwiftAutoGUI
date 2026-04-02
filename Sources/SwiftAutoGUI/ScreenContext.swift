//
//  ScreenContext.swift
//  SwiftAutoGUI
//

import AppKit
import ApplicationServices
import Foundation

// MARK: - Data Types

/// Rich context about the current macOS screen state, including the frontmost app,
/// visible windows, and an accessibility tree of the focused window.
///
/// This information supplements screenshots to give AI agents precise knowledge
/// of UI element positions, labels, roles, and states.
public struct ScreenContext: Sendable, Codable {
    /// The currently active (frontmost) application.
    public let frontmostApp: AppInfo?

    /// All visible on-screen windows, ordered by layer.
    public let visibleWindows: [WindowInfo]

    /// The accessibility tree of the focused window (nil if unavailable).
    public let focusedWindowAXTree: AXNode?

    public init(frontmostApp: AppInfo?, visibleWindows: [WindowInfo], focusedWindowAXTree: AXNode?) {
        self.frontmostApp = frontmostApp
        self.visibleWindows = visibleWindows
        self.focusedWindowAXTree = focusedWindowAXTree
    }
}

/// Information about a running application.
public struct AppInfo: Sendable, Codable {
    public let name: String
    public let bundleIdentifier: String?
    public let pid: Int32

    public init(name: String, bundleIdentifier: String?, pid: Int32) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
    }
}

/// Information about a visible window on screen.
public struct WindowInfo: Sendable, Codable {
    public let title: String?
    public let ownerApp: String
    public let bounds: CodableRect
    public let layer: Int
    public let isOnScreen: Bool

    public init(title: String?, ownerApp: String, bounds: CodableRect, layer: Int, isOnScreen: Bool) {
        self.title = title
        self.ownerApp = ownerApp
        self.bounds = bounds
        self.layer = layer
        self.isOnScreen = isOnScreen
    }
}

/// A node in the macOS accessibility tree.
///
/// Represents a single UI element with its role, label, value, position, and children.
/// The tree is depth- and node-limited to control token usage when sent to an LLM.
public struct AXNode: Sendable, Codable {
    /// The accessibility role (e.g. "AXButton", "AXTextField", "AXWindow").
    public let role: String

    /// The element's title or description label.
    public let label: String?

    /// The element's value (e.g. text field content), truncated for long values.
    public let value: String?

    /// The element's position and size in screen coordinates (top-left origin).
    public let frame: CodableRect

    /// Whether the element is currently enabled.
    public let isEnabled: Bool

    /// Child elements. `nil` means the subtree was pruned due to depth/node limits.
    /// An empty array means the element genuinely has no children.
    public let children: [AXNode]?

    public init(role: String, label: String?, value: String?, frame: CodableRect, isEnabled: Bool, children: [AXNode]?) {
        self.role = role
        self.label = label
        self.value = value
        self.frame = frame
        self.isEnabled = isEnabled
        self.children = children
    }
}

/// A `Codable`-conforming wrapper for `CGRect`, since `CGRect` does not conform to `Codable`.
public struct CodableRect: Sendable, Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(_ rect: CGRect) {
        self.x = Double(rect.origin.x)
        self.y = Double(rect.origin.y)
        self.width = Double(rect.size.width)
        self.height = Double(rect.size.height)
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - ScreenContextProvider

/// Gathers rich context about the current macOS screen state.
public struct ScreenContextProvider: Sendable {

    /// Options controlling what information is gathered and how much of the
    /// accessibility tree is traversed.
    public struct Options: Sendable {
        /// Maximum depth of the accessibility tree traversal.
        public var maxDepth: Int

        /// Maximum total number of AX nodes to collect.
        public var maxNodes: Int

        /// Maximum length for element values (longer values are truncated).
        public var maxValueLength: Int

        /// Whether to include the accessibility tree at all.
        public var includeAXTree: Bool

        public init(maxDepth: Int = 5, maxNodes: Int = 200, maxValueLength: Int = 100, includeAXTree: Bool = true) {
            self.maxDepth = maxDepth
            self.maxNodes = maxNodes
            self.maxValueLength = maxValueLength
            self.includeAXTree = includeAXTree
        }
    }

    /// Gathers the current screen context.
    ///
    /// - Parameter options: Controls tree depth, node limits, and whether to include the AX tree.
    /// - Returns: A ``ScreenContext`` with the current screen state.
    @MainActor
    public static func gather(options: Options = Options()) -> ScreenContext {
        let frontmostApp = gatherFrontmostApp()
        let visibleWindows = gatherVisibleWindows()

        var axTree: AXNode?
        if options.includeAXTree, let app = frontmostApp {
            var nodeCount = 0
            axTree = gatherAXTree(pid: app.pid, options: options, nodeCount: &nodeCount)
        }

        return ScreenContext(
            frontmostApp: frontmostApp,
            visibleWindows: visibleWindows,
            focusedWindowAXTree: axTree
        )
    }
}

// MARK: - Gathering: Frontmost App

extension ScreenContextProvider {
    private static func gatherFrontmostApp() -> AppInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AppInfo(
            name: app.localizedName ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier
        )
    }
}

// MARK: - Gathering: Visible Windows

extension ScreenContextProvider {
    private static func gatherVisibleWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return windowList.compactMap { dict -> WindowInfo? in
            guard let ownerName = dict[kCGWindowOwnerName as String] as? String else { return nil }

            let layer = dict[kCGWindowLayer as String] as? Int ?? 0
            // Only include normal windows (layer 0)
            guard layer == 0 else { return nil }

            let title = dict[kCGWindowName as String] as? String
            let isOnScreen = dict[kCGWindowIsOnscreen as String] as? Bool ?? false

            let bounds: CodableRect
            if let boundsDict = dict[kCGWindowBounds as String] as? [String: Any],
               let boundsRef = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                bounds = CodableRect(boundsRef)
            } else {
                bounds = CodableRect(x: 0, y: 0, width: 0, height: 0)
            }

            return WindowInfo(
                title: title,
                ownerApp: ownerName,
                bounds: bounds,
                layer: layer,
                isOnScreen: isOnScreen
            )
        }
    }
}

// MARK: - Gathering: Accessibility Tree

extension ScreenContextProvider {

    private static func gatherAXTree(pid: Int32, options: Options, nodeCount: inout Int) -> AXNode? {
        let appElement = AXUIElementCreateApplication(pid)

        // Get the focused window
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )

        guard result == .success, let windowElement = focusedWindow else {
            return nil
        }

        // The CFTypeRef is actually an AXUIElement
        let axWindow = windowElement as! AXUIElement
        return buildAXNode(from: axWindow, options: options, depth: 0, nodeCount: &nodeCount)
    }

    private static func buildAXNode(
        from element: AXUIElement,
        options: Options,
        depth: Int,
        nodeCount: inout Int
    ) -> AXNode? {
        guard nodeCount < options.maxNodes else { return nil }
        nodeCount += 1

        let role = axStringAttribute(element, kAXRoleAttribute) ?? "AXUnknown"
        let title = axStringAttribute(element, kAXTitleAttribute)
        let description = axStringAttribute(element, kAXDescriptionAttribute)
        let label = title ?? description

        var value: String? = nil
        if let rawValue = axStringAttribute(element, kAXValueAttribute) {
            if rawValue.count > options.maxValueLength {
                value = String(rawValue.prefix(options.maxValueLength)) + "..."
            } else {
                value = rawValue
            }
        }

        let frame = axFrame(element)
        let isEnabled = axBoolAttribute(element, kAXEnabledAttribute) ?? true

        // Get children if within depth limit
        let children: [AXNode]?
        if depth < options.maxDepth {
            var childrenRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                element,
                kAXChildrenAttribute as CFString,
                &childrenRef
            )
            if result == .success, let childArray = childrenRef as? [AXUIElement] {
                children = childArray.compactMap { child in
                    buildAXNode(from: child, options: options, depth: depth + 1, nodeCount: &nodeCount)
                }
            } else {
                children = []
            }
        } else {
            // Check if there are children we're not traversing
            var childCount: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                element,
                kAXChildrenAttribute as CFString,
                &childCount
            )
            if result == .success, let arr = childCount as? [AnyObject], !arr.isEmpty {
                children = nil // nil signals pruned subtree
            } else {
                children = []
            }
        }

        return AXNode(
            role: role,
            label: label,
            value: value,
            frame: frame,
            isEnabled: isEnabled,
            children: children
        )
    }

    // MARK: AX Attribute Helpers

    private static func axStringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private static func axBoolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return (value as? NSNumber)?.boolValue
    }

    private static func axFrame(_ element: AXUIElement) -> CodableRect {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)

        var position = CGPoint.zero
        var size = CGSize.zero

        if let positionRef = positionRef {
            // AXValue contains a CGPoint
            let axValue = positionRef as! AXValue
            AXValueGetValue(axValue, .cgPoint, &position)
        }

        if let sizeRef = sizeRef {
            let axValue = sizeRef as! AXValue
            AXValueGetValue(axValue, .cgSize, &size)
        }

        return CodableRect(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height)
        )
    }
}

// MARK: - Formatting

extension ScreenContext {
    /// Formats the screen context as compact, LLM-friendly text.
    ///
    /// The output uses indented tree structure which is token-efficient
    /// and easy for LLMs to parse.
    public func formatted() -> String {
        var lines: [String] = []

        // Frontmost app
        if let app = frontmostApp {
            let bundle = app.bundleIdentifier.map { " (\($0))" } ?? ""
            lines.append("Frontmost app: \(app.name)\(bundle)")
        }

        // Visible windows
        if !visibleWindows.isEmpty {
            lines.append("Visible windows:")
            for (index, window) in visibleWindows.enumerated() {
                let title = window.title.map { "\"\($0)\"" } ?? "(untitled)"
                let b = window.bounds
                lines.append("  [\(index)] \(title) - \(window.ownerApp) @ {\(Int(b.x)),\(Int(b.y)) \(Int(b.width))x\(Int(b.height))}")
            }
        }

        // AX tree
        if let tree = focusedWindowAXTree {
            lines.append("Focused window AX tree:")
            tree.appendFormatted(to: &lines, indent: 1)
        }

        return lines.joined(separator: "\n")
    }
}

extension AXNode {
    func appendFormatted(to lines: inout [String], indent: Int) {
        let prefix = String(repeating: "  ", count: indent)
        var parts: [String] = [role]

        if let label = label, !label.isEmpty {
            parts.append("\"\(label)\"")
        }

        if let value = value, !value.isEmpty {
            parts.append("value=\"\(value)\"")
        }

        let f = frame
        if f.width > 0 || f.height > 0 {
            parts.append("{\(Int(f.x)),\(Int(f.y)) \(Int(f.width))x\(Int(f.height))}")
        }

        if !isEnabled {
            parts.append("disabled")
        }

        lines.append(prefix + parts.joined(separator: " "))

        if let children = children {
            for child in children {
                child.appendFormatted(to: &lines, indent: indent + 1)
            }
        } else {
            // nil children means pruned
            lines.append(prefix + "  [...]")
        }
    }
}
