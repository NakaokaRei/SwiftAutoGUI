//
//  AXAction.swift
//  SwiftAutoGUI
//

import ApplicationServices
import CoreGraphics
import Foundation

/// Low-level wrappers around `AXUIElementPerformAction` and
/// `AXUIElementSetAttributeValue`.
///
/// Use these when you already hold an `AXUIElement` reference (for example,
/// from ``AXSearch/findElement(role:options:scope:)``). For higher-level
/// search-and-act convenience, see the AX methods on ``SwiftAutoGUI``.
///
/// All methods are `@MainActor` because `AXUIElement` is not thread-safe —
/// even concurrent reads can corrupt internal state.
public enum AXAction {

    // MARK: - Perform-action wrappers

    /// Performs `kAXPressAction` (the canonical "click" for a button or link).
    @MainActor
    @discardableResult
    public static func press(_ element: AXUIElement) -> Bool {
        perform(element, kAXPressAction)
    }

    /// Performs `kAXShowMenuAction` (right-click / contextual menu).
    @MainActor
    @discardableResult
    public static func showMenu(_ element: AXUIElement) -> Bool {
        perform(element, kAXShowMenuAction)
    }

    /// Performs `kAXConfirmAction` (e.g. enter/return on a default button).
    @MainActor
    @discardableResult
    public static func confirm(_ element: AXUIElement) -> Bool {
        perform(element, kAXConfirmAction)
    }

    /// Performs `kAXCancelAction` (e.g. escape on a cancel button).
    @MainActor
    @discardableResult
    public static func cancel(_ element: AXUIElement) -> Bool {
        perform(element, kAXCancelAction)
    }

    /// Performs `kAXIncrementAction` (sliders, steppers).
    @MainActor
    @discardableResult
    public static func increment(_ element: AXUIElement) -> Bool {
        perform(element, kAXIncrementAction)
    }

    /// Performs `kAXDecrementAction` (sliders, steppers).
    @MainActor
    @discardableResult
    public static func decrement(_ element: AXUIElement) -> Bool {
        perform(element, kAXDecrementAction)
    }

    /// Performs `kAXPickAction` (selects a menu item).
    @MainActor
    @discardableResult
    public static func pick(_ element: AXUIElement) -> Bool {
        perform(element, kAXPickAction)
    }

    /// Performs `kAXRaiseAction` (brings a window to the front).
    @MainActor
    @discardableResult
    public static func raise(_ element: AXUIElement) -> Bool {
        perform(element, kAXRaiseAction)
    }

    /// Performs an arbitrary AX action by name. Returns true on `.success`.
    @MainActor
    @discardableResult
    public static func perform(_ element: AXUIElement, _ action: String) -> Bool {
        AXUIElementPerformAction(element, action as CFString) == .success
    }

    // MARK: - Set-attribute wrappers

    /// Sets `kAXValueAttribute` to the given string. Use for text fields and
    /// text areas.
    @MainActor
    @discardableResult
    public static func setValue(_ element: AXUIElement, value: String) -> Bool {
        AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, value as CFString) == .success
    }

    /// Sets `kAXFocusedAttribute`. Useful before typing into a text field via
    /// CGEvent-based ``SwiftAutoGUI/write(_:interval:)``.
    @MainActor
    @discardableResult
    public static func setFocused(_ element: AXUIElement, _ focused: Bool = true) -> Bool {
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, focused as CFBoolean) == .success
    }

    /// Sets `kAXPositionAttribute` to move a window.
    @MainActor
    @discardableResult
    public static func setPosition(_ element: AXUIElement, _ point: CGPoint) -> Bool {
        var p = point
        guard let value = AXValueCreate(.cgPoint, &p) else { return false }
        return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value) == .success
    }

    /// Sets `kAXSizeAttribute` to resize a window.
    @MainActor
    @discardableResult
    public static func setSize(_ element: AXUIElement, _ size: CGSize) -> Bool {
        var s = size
        guard let value = AXValueCreate(.cgSize, &s) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value) == .success
    }

    // MARK: - Introspection

    /// Returns the action names this element advertises (e.g. `kAXPressAction`).
    @MainActor
    public static func availableActions(of element: AXUIElement) -> [String] {
        axActionNames(element)
    }

    /// Returns the element's frame (position + size) in screen coordinates.
    /// Origin is the top-left of the main display.
    @MainActor
    public static func frame(of element: AXUIElement) -> CGRect? {
        axFrame(element)
    }

    /// Returns the element's role (e.g. "AXButton").
    @MainActor
    public static func role(of element: AXUIElement) -> String? {
        axStringAttribute(element, kAXRoleAttribute)
    }

    /// Returns the element's label (`kAXTitleAttribute` or `kAXDescriptionAttribute`).
    @MainActor
    public static func label(of element: AXUIElement) -> String? {
        axStringAttribute(element, kAXTitleAttribute)
            ?? axStringAttribute(element, kAXDescriptionAttribute)
    }

    /// Returns the element's current value.
    @MainActor
    public static func value(of element: AXUIElement) -> String? {
        axStringAttribute(element, kAXValueAttribute)
    }

    /// Returns whether the element is enabled.
    @MainActor
    public static func isEnabled(_ element: AXUIElement) -> Bool {
        axBoolAttribute(element, kAXEnabledAttribute) ?? true
    }
}
