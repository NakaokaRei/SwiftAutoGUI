//
//  AXSearch.swift
//  SwiftAutoGUI
//

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Element resolution against the macOS accessibility tree.
///
/// Use these functions to obtain a live ``AXUIElement`` reference that you can
/// pass to ``AXAction``. References become invalid when the UI changes, so try
/// to find-and-act in close succession.
public enum AXSearch {

    // MARK: - App scope resolution

    /// Resolves an ``AXAppScope`` to an application `AXUIElement`. Returns nil
    /// if the app cannot be located.
    @MainActor
    public static func appElement(for scope: AXAppScope) -> AXUIElement? {
        switch scope {
        case .frontmost:
            guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
                return nil
            }
            return AXUIElementCreateApplication(pid)
        case .bundleID(let id):
            guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == id }) else {
                return nil
            }
            return AXUIElementCreateApplication(app.processIdentifier)
        case .pid(let pid):
            return AXUIElementCreateApplication(pid)
        }
    }

    // MARK: - Element search

    /// Finds the first element matching the given role and options.
    ///
    /// - Parameters:
    ///   - role: Required AX role (e.g. "AXButton"). Pass nil to match any role.
    ///   - options: Label/value match strategy and traversal limits.
    ///   - scope: Which application's tree to search.
    @MainActor
    public static func findElement(
        role: String? = nil,
        options: AXMatchOptions = AXMatchOptions(),
        scope: AXAppScope = .frontmost
    ) -> AXUIElement? {
        guard let app = appElement(for: scope) else { return nil }
        var nodeCount = 0
        return findFirst(from: app, role: role, options: options, depth: 0, nodeCount: &nodeCount)
    }

    /// Convenience: find by role and label using the default
    /// case-insensitive contains matcher (or exact equality if requested).
    @MainActor
    public static func findElement(
        role: String? = nil,
        label: String,
        exact: Bool = false,
        scope: AXAppScope = .frontmost
    ) -> AXUIElement? {
        findElement(
            role: role,
            options: .label(label, exact: exact),
            scope: scope
        )
    }

    /// Returns all elements matching the given role and options.
    @MainActor
    public static func findElements(
        role: String? = nil,
        options: AXMatchOptions = AXMatchOptions(),
        scope: AXAppScope = .frontmost
    ) -> [AXUIElement] {
        guard let app = appElement(for: scope) else { return [] }
        var results: [AXUIElement] = []
        var nodeCount = 0
        collectAll(from: app, role: role, options: options, depth: 0, into: &results, nodeCount: &nodeCount)
        return results
    }

    /// Returns the deepest element at a screen point. Wraps
    /// `AXUIElementCopyElementAtPosition`.
    @MainActor
    public static func findElement(at point: CGPoint) -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWide,
            Float(point.x),
            Float(point.y),
            &element
        )
        guard result == .success else { return nil }
        return element
    }

    /// Finds a window in the given app whose title satisfies the matcher.
    @MainActor
    public static func findWindow(
        title: String,
        exact: Bool = false,
        scope: AXAppScope = .frontmost
    ) -> AXUIElement? {
        guard let app = appElement(for: scope) else { return nil }
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            app,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return nil
        }
        let match: AXStringMatch = exact ? .exact(title) : .containsCaseInsensitive(title)
        return windows.first { window in
            match.matches(axStringAttribute(window, kAXTitleAttribute))
        }
    }

    /// Finds a menu item by hierarchical path, e.g. `["File", "Save As…"]`.
    ///
    /// Walks `kAXMenuBarAttribute` and recursively descends through
    /// `kAXChildrenAttribute`. Each path component is matched
    /// case-insensitively against the item's title (use `exact: true` for
    /// strict equality).
    @MainActor
    public static func findMenuItem(
        path: [String],
        exact: Bool = false,
        scope: AXAppScope = .frontmost
    ) -> AXUIElement? {
        guard !path.isEmpty,
              let app = appElement(for: scope),
              let menuBarRef = axAttribute(app, kAXMenuBarAttribute) else {
            return nil
        }
        let menuBar = menuBarRef as! AXUIElement
        return descendMenu(from: menuBar, path: path, exact: exact)
    }

    @MainActor
    private static func descendMenu(
        from element: AXUIElement,
        path: [String],
        exact: Bool
    ) -> AXUIElement? {
        guard let head = path.first else { return element }
        let tail = Array(path.dropFirst())
        let match: AXStringMatch = exact ? .exact(head) : .containsCaseInsensitive(head)

        // The menu bar's direct children are AXMenuBarItem; inside, the visible
        // children are AXMenu nodes whose own children are the AXMenuItems we
        // want to match. Try both shapes so each path component can address
        // either layer.
        let directChildren = axChildren(element) ?? []
        for child in directChildren {
            let title = axStringAttribute(child, kAXTitleAttribute)
            if match.matches(title) {
                if tail.isEmpty { return child }
                // Descend into the child's submenu wrapper if present.
                if let submenuChildren = axChildren(child),
                   let submenu = submenuChildren.first(where: {
                       axStringAttribute($0, kAXRoleAttribute) == "AXMenu"
                   }) ?? submenuChildren.first {
                    if let found = descendMenu(from: submenu, path: tail, exact: exact) {
                        return found
                    }
                }
                if let found = descendMenu(from: child, path: tail, exact: exact) {
                    return found
                }
            }
        }
        return nil
    }

    // MARK: - Tree traversal

    @MainActor
    private static func findFirst(
        from element: AXUIElement,
        role: String?,
        options: AXMatchOptions,
        depth: Int,
        nodeCount: inout Int
    ) -> AXUIElement? {
        guard nodeCount < options.maxNodes else { return nil }
        nodeCount += 1

        if matches(element, role: role, options: options) {
            return element
        }
        guard depth < options.maxDepth, let children = axChildren(element) else {
            return nil
        }
        for child in children {
            if let found = findFirst(
                from: child, role: role, options: options,
                depth: depth + 1, nodeCount: &nodeCount
            ) {
                return found
            }
            if nodeCount >= options.maxNodes { break }
        }
        return nil
    }

    @MainActor
    private static func collectAll(
        from element: AXUIElement,
        role: String?,
        options: AXMatchOptions,
        depth: Int,
        into results: inout [AXUIElement],
        nodeCount: inout Int
    ) {
        guard nodeCount < options.maxNodes else { return }
        nodeCount += 1

        if matches(element, role: role, options: options) {
            results.append(element)
        }
        guard depth < options.maxDepth, let children = axChildren(element) else {
            return
        }
        for child in children {
            collectAll(
                from: child, role: role, options: options,
                depth: depth + 1, into: &results, nodeCount: &nodeCount
            )
            if nodeCount >= options.maxNodes { return }
        }
    }

    @MainActor
    private static func matches(
        _ element: AXUIElement,
        role: String?,
        options: AXMatchOptions
    ) -> Bool {
        if let role {
            guard axStringAttribute(element, kAXRoleAttribute) == role else {
                return false
            }
        }
        if options.requireEnabled {
            let enabled = axBoolAttribute(element, kAXEnabledAttribute) ?? true
            guard enabled else { return false }
        }
        if let labelMatch = options.labelMatch {
            let label = axStringAttribute(element, kAXTitleAttribute)
                ?? axStringAttribute(element, kAXDescriptionAttribute)
            guard labelMatch.matches(label) else { return false }
        }
        if let valueMatch = options.valueMatch {
            let value = axStringAttribute(element, kAXValueAttribute)
            guard valueMatch.matches(value) else { return false }
        }
        return true
    }
}
