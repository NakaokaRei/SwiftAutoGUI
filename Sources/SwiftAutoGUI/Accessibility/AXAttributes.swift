//
//  AXAttributes.swift
//  SwiftAutoGUI
//

import ApplicationServices
import CoreGraphics
import Foundation

// MARK: - Attribute Helpers

/// Reads a string-valued AX attribute. Returns nil if missing or wrong type.
@MainActor
internal func axStringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    guard result == .success else { return nil }
    return value as? String
}

/// Reads a Bool-valued AX attribute. Returns nil if missing or wrong type.
@MainActor
internal func axBoolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    guard result == .success else { return nil }
    return (value as? NSNumber)?.boolValue
}

/// Reads the children of an AX element. Returns nil if missing or wrong type.
@MainActor
internal func axChildren(_ element: AXUIElement) -> [AXUIElement]? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
    guard result == .success else { return nil }
    return value as? [AXUIElement]
}

/// Reads an arbitrary AX attribute and returns the raw `CFTypeRef`.
@MainActor
internal func axAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    guard result == .success else { return nil }
    return value
}

/// Reads the position + size of an element as a `CGRect` in screen coordinates.
/// Returns nil if either attribute is unavailable.
@MainActor
internal func axFrame(_ element: AXUIElement) -> CGRect? {
    var positionRef: CFTypeRef?
    var sizeRef: CFTypeRef?

    AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef)
    AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef)

    guard let positionRef, let sizeRef else { return nil }

    var position = CGPoint.zero
    var size = CGSize.zero

    let positionValue = positionRef as! AXValue
    let sizeValue = sizeRef as! AXValue

    guard AXValueGetValue(positionValue, .cgPoint, &position),
          AXValueGetValue(sizeValue, .cgSize, &size) else {
        return nil
    }

    return CGRect(origin: position, size: size)
}

/// Returns the action names the element advertises (e.g. `kAXPressAction`).
@MainActor
internal func axActionNames(_ element: AXUIElement) -> [String] {
    var namesRef: CFArray?
    let result = AXUIElementCopyActionNames(element, &namesRef)
    guard result == .success, let names = namesRef as? [String] else { return [] }
    return names
}
