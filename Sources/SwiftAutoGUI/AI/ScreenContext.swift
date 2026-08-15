//
//  ScreenContext.swift
//  SwiftAutoGUI
//

import AppKit
import ApplicationServices
import Carbon
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

    /// The element that currently owns keyboard focus, if exposed by Accessibility.
    public let focusedElement: FocusedElementInfo?

    /// The current keyboard input source / IME mode (nil if unavailable).
    public let keyboardInputSource: InputSourceInfo?

    public init(
        frontmostApp: AppInfo?,
        visibleWindows: [WindowInfo],
        focusedWindowAXTree: AXNode?,
        keyboardInputSource: InputSourceInfo? = nil,
        focusedElement: FocusedElementInfo? = nil
    ) {
        self.frontmostApp = frontmostApp
        self.visibleWindows = visibleWindows
        self.focusedWindowAXTree = focusedWindowAXTree
        self.keyboardInputSource = keyboardInputSource
        self.focusedElement = focusedElement
    }
}

/// Compact identity of the UI element that currently owns keyboard focus.
public struct FocusedElementInfo: Sendable, Codable, Equatable {
    public let role: String
    public let label: String?
    public let value: String?
    public let frame: CodableRect

    public init(role: String, label: String?, value: String?, frame: CodableRect) {
        self.role = role
        self.label = label
        self.value = value
        self.frame = frame
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

/// Information about the current keyboard input source (IME state).
public struct InputSourceInfo: Sendable, Codable {
    /// The input source identifier (e.g., "com.apple.inputmethod.Japanese.RomajiTyping").
    public let id: String

    /// The localized display name (e.g., "日本語ローマ字", "U.S.").
    public let localizedName: String

    public init(id: String, localizedName: String) {
        self.id = id
        self.localizedName = localizedName
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
    private enum CodingKeys: String, CodingKey {
        case elementID, path, actions, role, label, value, frame, isEnabled, children
    }
    /// Step-local identifier used by an agent to target this element.
    /// Only actionable elements receive an identifier.
    public let elementID: Int?

    /// Child-index path from the focused window, used to resolve a live element.
    public let path: [Int]

    /// Accessibility actions advertised by the element. `AXSetValue` is added
    /// when the value attribute is writable.
    public let actions: [String]

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

    public init(
        role: String,
        label: String?,
        value: String?,
        frame: CodableRect,
        isEnabled: Bool,
        children: [AXNode]?,
        elementID: Int? = nil,
        path: [Int] = [],
        actions: [String] = []
    ) {
        self.elementID = elementID
        self.path = path
        self.actions = actions
        self.role = role
        self.label = label
        self.value = value
        self.frame = frame
        self.isEnabled = isEnabled
        self.children = children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        elementID = try container.decodeIfPresent(Int.self, forKey: .elementID)
        path = try container.decodeIfPresent([Int].self, forKey: .path) ?? []
        actions = try container.decodeIfPresent([String].self, forKey: .actions) ?? []
        role = try container.decode(String.self, forKey: .role)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        frame = try container.decode(CodableRect.self, forKey: .frame)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        children = try container.decodeIfPresent([AXNode].self, forKey: .children)
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
        let inputSource = gatherKeyboardInputSource()

        var axTree: AXNode?
        var focusedElement: FocusedElementInfo?
        if options.includeAXTree, let app = frontmostApp {
            var nodeCount = 0
            var nextElementID = 1
            axTree = gatherAXTree(
                pid: app.pid,
                options: options,
                nodeCount: &nodeCount,
                nextElementID: &nextElementID
            )
            focusedElement = gatherFocusedElement(pid: app.pid, maxValueLength: options.maxValueLength)
        }

        return ScreenContext(
            frontmostApp: frontmostApp,
            visibleWindows: visibleWindows,
            focusedWindowAXTree: axTree,
            keyboardInputSource: inputSource,
            focusedElement: focusedElement
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

// MARK: - Gathering: Keyboard Input Source

extension ScreenContextProvider {
    private static func gatherKeyboardInputSource() -> InputSourceInfo? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)

        guard let idPtr, let namePtr else { return nil }

        let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        let localizedName = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String

        return InputSourceInfo(id: id, localizedName: localizedName)
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

    @MainActor
    private static func gatherAXTree(
        pid: Int32,
        options: Options,
        nodeCount: inout Int,
        nextElementID: inout Int
    ) -> AXNode? {
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
        return buildAXNode(
            from: axWindow,
            options: options,
            depth: 0,
            path: [],
            nodeCount: &nodeCount,
            nextElementID: &nextElementID
        )
    }

    @MainActor
    private static func gatherFocusedElement(pid: Int32, maxValueLength: Int) -> FocusedElementInfo? {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &value
        ) == .success, let value else { return nil }

        let element = value as! AXUIElement
        let rawValue = axStringAttribute(element, kAXValueAttribute)
        let truncated = rawValue.map {
            $0.count > maxValueLength ? String($0.prefix(maxValueLength)) + "..." : $0
        }
        return FocusedElementInfo(
            role: axStringAttribute(element, kAXRoleAttribute) ?? "AXUnknown",
            label: axStringAttribute(element, kAXTitleAttribute)
                ?? axStringAttribute(element, kAXDescriptionAttribute),
            value: truncated,
            frame: CodableRect(axFrame(element) ?? .zero)
        )
    }

    @MainActor
    private static func buildAXNode(
        from element: AXUIElement,
        options: Options,
        depth: Int,
        path: [Int],
        nodeCount: inout Int,
        nextElementID: inout Int
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

        let frame = CodableRect(axFrame(element) ?? .zero)
        let isEnabled = axBoolAttribute(element, kAXEnabledAttribute) ?? true
        var actions = axActionNames(element).sorted()
        if axIsAttributeSettable(element, kAXValueAttribute), !actions.contains("AXSetValue") {
            actions.append("AXSetValue")
        }
        let elementID: Int?
        if !actions.isEmpty {
            elementID = nextElementID
            nextElementID += 1
        } else {
            elementID = nil
        }

        // Get children if within depth limit
        let children: [AXNode]?
        if depth < options.maxDepth {
            if let childArray = axChildren(element) {
                children = childArray.enumerated().compactMap { index, child in
                    buildAXNode(
                        from: child,
                        options: options,
                        depth: depth + 1,
                        path: path + [index],
                        nodeCount: &nodeCount,
                        nextElementID: &nextElementID
                    )
                }
            } else {
                children = []
            }
        } else {
            // Pruned subtree: nil if children exist but were skipped, [] otherwise.
            if let arr = axChildren(element), !arr.isEmpty {
                children = nil
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
            children: children,
            elementID: elementID,
            path: path,
            actions: actions
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

        // Keyboard input source
        if let inputSource = keyboardInputSource {
            lines.append("Keyboard input source: \(inputSource.localizedName) (\(inputSource.id))")
        }

        if let focusedElement {
            let label = focusedElement.label.map { " \"\($0)\"" } ?? ""
            lines.append("Focused element: \(focusedElement.role)\(label)")
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
        var parts: [String] = []
        if let elementID {
            parts.append("[#\(elementID)]")
        }
        parts.append(role)

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

        if !actions.isEmpty {
            parts.append("actions=[\(actions.joined(separator: ","))]")
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


    /// Returns the actionable node with the given step-local identifier.
    public func node(withID id: Int) -> AXNode? {
        if elementID == id { return self }
        for child in children ?? [] {
            if let match = child.node(withID: id) { return match }
        }
        return nil
    }
}

extension ScreenContext {
    /// A deterministic summary used to detect meaningful UI changes between actions.
    public var stateFingerprint: String {
        var lines: [String] = []
        if let app = frontmostApp {
            lines.append("app:\(app.pid):\(app.bundleIdentifier ?? app.name)")
        }
        focusedWindowAXTree?.appendFingerprint(to: &lines)
        return lines.joined(separator: "\n")
    }

    /// Number of elements that can be targeted by an element-ID action.
    public var actionableElementCount: Int {
        focusedWindowAXTree?.actionableElementCount ?? 0
    }
}

private extension AXNode {
    var actionableElementCount: Int {
        (elementID == nil ? 0 : 1) + (children ?? []).reduce(0) { $0 + $1.actionableElementCount }
    }

    func appendFingerprint(to lines: inout [String]) {
        lines.append("\(path):\(role):\(label ?? ""):\(value ?? ""):\(isEnabled):\(Int(frame.x)),\(Int(frame.y)),\(Int(frame.width)),\(Int(frame.height))")
        for child in children ?? [] { child.appendFingerprint(to: &lines) }
    }
}

extension ScreenContextProvider {
    /// Resolves a step-local element ID against the current live AX hierarchy.
    /// Returns `nil` if the hierarchy changed or the resolved element no longer
    /// matches the observed role and label.
    @MainActor
    public static func resolveElement(id: Int, in context: ScreenContext) -> AXUIElement? {
        guard let observed = context.focusedWindowAXTree?.node(withID: id),
              let pid = context.frontmostApp?.pid,
              NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return nil }

        let app = AXUIElementCreateApplication(pid)
        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        ) == .success, let windowValue else { return nil }

        var current = windowValue as! AXUIElement
        for index in observed.path {
            guard let children = axChildren(current), children.indices.contains(index) else { return nil }
            current = children[index]
        }

        let currentRole = axStringAttribute(current, kAXRoleAttribute) ?? "AXUnknown"
        let currentLabel = axStringAttribute(current, kAXTitleAttribute)
            ?? axStringAttribute(current, kAXDescriptionAttribute)
        guard currentRole == observed.role, currentLabel == observed.label else { return nil }

        if observed.frame.width > 0 || observed.frame.height > 0 {
            guard let currentFrame = axFrame(current),
                  abs(currentFrame.minX - observed.frame.cgRect.minX) <= 2,
                  abs(currentFrame.minY - observed.frame.cgRect.minY) <= 2,
                  abs(currentFrame.width - observed.frame.cgRect.width) <= 2,
                  abs(currentFrame.height - observed.frame.cgRect.height) <= 2 else {
                return nil
            }
        }
        return current
    }
}
