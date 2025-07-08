import Foundation
import AppKit

/// A Swift library for programmatically controlling the mouse and keyboard on macOS.
///
/// SwiftAutoGUI provides a simple, high-level interface for GUI automation tasks including:
/// - Keyboard input simulation
/// - Mouse movement and clicking
/// - Screenshot capture
/// - Image recognition on screen
///
/// This library is inspired by PyAutoGUI and provides similar functionality for macOS applications.
///
/// ## Topics
///
/// ### Getting Started
/// - ``sendKeyShortcut(_:)``
/// - ``leftClick()``
/// - ``move(to:)``
///
/// ### Keyboard Control
/// - ``keyDown(_:)``
/// - ``keyUp(_:)``
/// - ``write(_:interval:)``
/// - ``Key``
///
/// ### Mouse Control
/// - ``position()``
/// - ``moveMouse(dx:dy:)``
/// - ``rightClick()``
/// - ``leftDragged(to:from:)``
/// - ``vscroll(clicks:)``
/// - ``hscroll(clicks:)``
///
/// ### Screenshots
/// - ``screenshot()``
/// - ``screenshot(region:)``
/// - ``screenshot(imageFilename:region:)``
/// - ``size()``
/// - ``pixel(x:y:)``
///
/// ### Image Recognition
/// - ``locateOnScreen(_:grayscale:confidence:region:)``
/// - ``locateCenterOnScreen(_:grayscale:confidence:region:)``
/// - ``locateAllOnScreen(_:grayscale:confidence:region:)``
public class SwiftAutoGUI {

    // MARK: Key Event

    /// Sends a keyboard shortcut by pressing and releasing multiple keys in sequence.
    ///
    /// This method simulates pressing multiple keys simultaneously, commonly used for keyboard shortcuts.
    /// Keys are pressed in the order provided and released in reverse order.
    ///
    /// - Parameter keys: An array of keys to be pressed together. The order matters for the sequence of key presses.
    ///
    /// - Note: The system may require accessibility permissions for this method to work.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Copy text (Command+C)
    /// SwiftAutoGUI.sendKeyShortcut([.command, .c])
    ///
    /// // Switch virtual desktop (Control+Left Arrow)
    /// SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
    ///
    /// // Take screenshot (Command+Shift+3)
    /// SwiftAutoGUI.sendKeyShortcut([.command, .shift, .three])
    ///
    /// // Open Spotlight (Command+Space)
    /// SwiftAutoGUI.sendKeyShortcut([.command, .space])
    /// ```
    public static func sendKeyShortcut(_ keys: [Key]) {
        for key in keys {
            keyDown(key)
        }
        for key in keys.reversed() {
            keyUp(key)
        }
    }

    /// Simulates pressing down a key without releasing it.
    ///
    /// Use this method for holding down a key, useful for gaming, continuous scrolling,
    /// or creating custom key combinations. Remember to call ``keyUp(_:)`` to release the key.
    ///
    /// - Parameter key: The key to press down. See ``Key`` for available options.
    ///
    /// - Important: Always pair with ``keyUp(_:)`` to avoid stuck keys.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Hold down shift for multiple capital letters
    /// SwiftAutoGUI.keyDown(.shift)
    /// SwiftAutoGUI.keyDown(.h)
    /// SwiftAutoGUI.keyUp(.h)
    /// SwiftAutoGUI.keyDown(.i)
    /// SwiftAutoGUI.keyUp(.i)
    /// SwiftAutoGUI.keyUp(.shift)
    ///
    /// // Trigger media key
    /// SwiftAutoGUI.keyDown(.soundUp)
    /// SwiftAutoGUI.keyUp(.soundUp)
    /// ```
    public static func keyDown(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: true)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: true)
        }
    }

    /// Simulates releasing a previously pressed key.
    ///
    /// This method releases a key that was pressed using ``keyDown(_:)``.
    /// It's essential to release keys to prevent them from being stuck in a pressed state.
    ///
    /// - Parameter key: The key to release. Must match a previously pressed key.
    ///
    /// - Important: Every ``keyDown(_:)`` should have a corresponding ``keyUp(_:)``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Type a single character
    /// SwiftAutoGUI.keyDown(.a)
    /// SwiftAutoGUI.keyUp(.a)
    ///
    /// // Release modifier key
    /// SwiftAutoGUI.keyDown(.command)
    /// // ... perform other actions ...
    /// SwiftAutoGUI.keyUp(.command)
    /// ```
    public static func keyUp(_ key: Key) {
        if let normalKeycode = key.normalKeycode {
            normalKeyEvent(normalKeycode, down: false)
        } else if let specialKeycode = key.specialKeycode {
            specialKeyEvent(specialKeycode, down: false)
        }
    }

    /// Press a key and release it
    ///
    /// - Parameter key: The key to be pressed and released. The details of Key is in  `normalKeycode` of ``Key``
    private static func normalKeyEvent(_ key: CGKeyCode, down: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
        event?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Press a special key and release it
    ///
    /// - Parameter key: The key to be pressed and released. The details of Key is in  `specialKeycode` of ``Key``
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

    /// Types a text string with optional delay between keystrokes.
    ///
    /// This method types each character of the provided string sequentially,
    /// automatically handling uppercase letters and special characters by using
    /// the shift key when necessary.
    ///
    /// - Parameters:
    ///   - text: The string to type
    ///   - interval: Delay between each keystroke in seconds (default: 0)
    ///
    /// - Note: This method only supports basic ASCII characters and may not work
    ///         correctly with complex Unicode characters or emoji.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Type text instantly
    /// SwiftAutoGUI.write("Hello, World!")
    ///
    /// // Type with 0.1 second delay between characters
    /// SwiftAutoGUI.write("Slowly typed text", interval: 0.1)
    ///
    /// // Type in a text field
    /// SwiftAutoGUI.click(x: 100, y: 200)  // Click on text field
    /// SwiftAutoGUI.write("user@example.com")
    /// ```
    public static func write(_ text: String, interval: TimeInterval = 0) {
        for char in text {
            if let key = characterToKey(char) {
                let isUppercase = char.isUppercase
                let needsShift = isUppercase || shiftCharacters.contains(char)
                
                if needsShift {
                    keyDown(.shift)
                }
                
                keyDown(key)
                keyUp(key)
                
                if needsShift {
                    keyUp(.shift)
                }
                
                if interval > 0 {
                    Thread.sleep(forTimeInterval: interval)
                }
            }
        }
    }
    
    /// Maps a character to its corresponding Key enum case.
    ///
    /// - Parameter char: The character to map
    /// - Returns: The corresponding Key enum case, or nil if not supported
    private static func characterToKey(_ char: Character) -> Key? {
        switch char.lowercased().first {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case " ": return .space
        case "\t": return .tab
        case "\n": return .returnKey
        case "\r": return .returnKey
        case "=": return .equals
        case "-": return .minus
        case ";": return .semicolon
        case "'": return .apostrophe
        case ",": return .comma
        case ".": return .period
        case "/": return .forwardSlash
        case "\\": return .backslash
        case "`": return .grave
        case "[": return .leftBracket
        case "]": return .rightBracket
        case "!": return .one      // Shift+1
        case "@": return .two      // Shift+2
        case "#": return .three    // Shift+3
        case "$": return .four     // Shift+4
        case "%": return .five     // Shift+5
        case "^": return .six      // Shift+6
        case "&": return .seven    // Shift+7
        case "*": return .eight    // Shift+8
        case "(": return .nine     // Shift+9
        case ")": return .zero     // Shift+0
        case "_": return .minus    // Shift+-
        case "+": return .equals   // Shift+=
        case "{": return .leftBracket  // Shift+[
        case "}": return .rightBracket // Shift+]
        case "|": return .backslash    // Shift+\
        case ":": return .semicolon    // Shift+;
        case "\"": return .apostrophe  // Shift+'
        case "<": return .comma        // Shift+,
        case ">": return .period       // Shift+.
        case "?": return .forwardSlash // Shift+/
        case "~": return .grave        // Shift+`
        default: return nil
        }
    }
    
    /// Set of characters that require the shift key to be pressed.
    private static let shiftCharacters: Set<Character> = [
        "!", "@", "#", "$", "%", "^", "&", "*", "(", ")",
        "_", "+", "{", "}", "|", ":", "\"", "<", ">", "?", "~"
    ]

    // MARK: Mouse Event

    /// Returns the current position of the mouse cursor.
    ///
    /// This method returns the current mouse cursor coordinates in the CGWindow coordinate system
    /// where (0,0) is the top-left corner of the main screen.
    ///
    /// - Returns: A `CGPoint` containing the current x and y coordinates of the mouse cursor.
    ///
    /// - Note: The returned coordinates use the CGWindow coordinate system (origin at top-left),
    ///         not the NSView coordinate system (origin at bottom-left).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Get current mouse position
    /// let currentPos = SwiftAutoGUI.position()
    /// print("Mouse is at: \(currentPos.x), \(currentPos.y)")
    ///
    /// // Save position, move, then return
    /// let savedPos = SwiftAutoGUI.position()
    /// SwiftAutoGUI.move(to: CGPoint(x: 100, y: 200))
    /// // ... perform actions ...
    /// SwiftAutoGUI.move(to: savedPos)
    ///
    /// // Check if mouse is in specific region
    /// let pos = SwiftAutoGUI.position()
    /// if pos.x < 100 && pos.y < 100 {
    ///     print("Mouse is in top-left corner")
    /// }
    /// ```
    public static func position() -> CGPoint {
        var mouseLoc = NSEvent.mouseLocation
        // Convert from NSView coordinates (origin bottom-left) to CGWindow coordinates (origin top-left)
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y
        return mouseLoc
    }

    /// Moves the mouse cursor relative to its current position.
    ///
    /// This method moves the mouse by the specified distances from wherever it currently is.
    /// Positive values move right/down, negative values move left/up.
    ///
    /// - Parameters:
    ///   - dx: Horizontal distance to move (positive = right, negative = left)
    ///   - dy: Vertical distance to move (positive = down, negative = up)
    ///
    /// - Note: The movement is in logical points, not pixels, so it works correctly on Retina displays.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Move mouse 100 points right and 50 points down
    /// SwiftAutoGUI.moveMouse(dx: 100, dy: 50)
    ///
    /// // Move mouse 50 points left and 25 points up
    /// SwiftAutoGUI.moveMouse(dx: -50, dy: -25)
    ///
    /// // Small adjustment for precision
    /// SwiftAutoGUI.moveMouse(dx: 1, dy: 1)
    /// ```
    public static func moveMouse(dx: CGFloat, dy: CGFloat) {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc.y = NSHeight(NSScreen.screens[0].frame) - mouseLoc.y;
        let newLoc = CGPoint(x: mouseLoc.x-CGFloat(dx), y: mouseLoc.y + CGFloat(dy))
        CGDisplayMoveCursorToPoint(0, newLoc)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Moves the mouse cursor to an absolute position on the screen.
    ///
    /// This method instantly moves the mouse to the specified coordinates using the CGWindow
    /// coordinate system where (0,0) is the top-left corner of the main screen.
    ///
    /// - Parameter to: The target position in CGWindow coordinates (origin at top-left).
    ///
    /// - Note: CGWindow coordinates differ from NSView coordinates which have origin at bottom-left.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Move to top-left corner of screen
    /// SwiftAutoGUI.move(to: CGPoint(x: 0, y: 0))
    ///
    /// // Move to center of a 1920x1080 screen
    /// SwiftAutoGUI.move(to: CGPoint(x: 960, y: 540))
    ///
    /// // Move to specific button location
    /// let buttonLocation = CGPoint(x: 150, y: 300)
    /// SwiftAutoGUI.move(to: buttonLocation)
    /// ```
    public static func move(to: CGPoint) {
        CGDisplayMoveCursorToPoint(0, to)
        Thread.sleep(forTimeInterval: 0.01)
    }

    /// Performs a left mouse button click at the current cursor position.
    ///
    /// This method simulates a complete mouse click (press and release) at wherever
    /// the cursor is currently located. It's the most common mouse interaction.
    ///
    /// - Note: The click happens immediately at the current position without moving the cursor.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Click at current position
    /// SwiftAutoGUI.leftClick()
    ///
    /// // Move and click pattern
    /// SwiftAutoGUI.move(to: CGPoint(x: 100, y: 200))
    /// SwiftAutoGUI.leftClick()
    ///
    /// // Double-click
    /// SwiftAutoGUI.leftClick()
    /// Thread.sleep(forTimeInterval: 0.1)
    /// SwiftAutoGUI.leftClick()
    /// ```
    public static func leftClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        leftClickDown(position: mouseLoc)
        leftClickUp(position: mouseLoc)
    }

    /// Performs a right mouse button click at the current cursor position.
    ///
    /// This method simulates a right-click (press and release) commonly used for
    /// context menus and secondary actions.
    ///
    /// - Note: The click happens immediately at the current position without moving the cursor.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Right-click for context menu
    /// SwiftAutoGUI.rightClick()
    ///
    /// // Right-click on specific element
    /// SwiftAutoGUI.move(to: fileLocation)
    /// SwiftAutoGUI.rightClick()
    ///
    /// // Wait for menu to appear
    /// Thread.sleep(forTimeInterval: 0.5)
    /// ```
    public static func rightClick() {
        var mouseLoc = NSEvent.mouseLocation
        mouseLoc = CGPoint(x: mouseLoc.x, y: NSHeight(NSScreen.screens[0].frame) - mouseLoc.y)
        rightClickDown(position: mouseLoc)
        rightClickUp(position: mouseLoc)
    }

    /// Performs a drag operation by holding the left mouse button from one position to another.
    ///
    /// This method simulates clicking and holding at the start position, dragging to the end position,
    /// and then releasing. Useful for moving files, selecting text, or drawing.
    ///
    /// - Parameters:
    ///   - to: The ending position of the drag operation
    ///   - from: The starting position of the drag operation
    ///
    /// - Note: Both positions use CGWindow coordinates (origin at top-left).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Drag a file from one location to another
    /// let filePos = CGPoint(x: 100, y: 200)
    /// let folderPos = CGPoint(x: 500, y: 200)
    /// SwiftAutoGUI.leftDragged(to: folderPos, from: filePos)
    ///
    /// // Select text by dragging
    /// let textStart = CGPoint(x: 50, y: 100)
    /// let textEnd = CGPoint(x: 300, y: 100)
    /// SwiftAutoGUI.leftDragged(to: textEnd, from: textStart)
    ///
    /// // Draw a line in a graphics application
    /// SwiftAutoGUI.leftDragged(to: CGPoint(x: 200, y: 300), from: CGPoint(x: 100, y: 100))
    /// ```
    public static func leftDragged(to: CGPoint, from: CGPoint) {
        leftClickDown(position: from)
        let source = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: CGEventType.leftMouseDragged,
                            mouseCursorPosition: to, mouseButton: CGMouseButton.left)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
        leftClickUp(position: to)
    }

    /// Scrolls the mouse wheel vertically by the specified number of clicks.
    ///
    /// This method simulates mouse wheel scrolling, useful for navigating documents,
    /// web pages, or any scrollable content. The method handles large scroll amounts
    /// by breaking them into smaller chunks for smoother scrolling.
    ///
    /// - Parameter clicks: Number of scroll clicks. Positive scrolls up, negative scrolls down.
    ///
    /// - Note: One "click" typically scrolls about 3 lines of text, but this varies by application.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Scroll up 5 clicks
    /// SwiftAutoGUI.vscroll(clicks: 5)
    ///
    /// // Scroll down 10 clicks
    /// SwiftAutoGUI.vscroll(clicks: -10)
    ///
    /// // Smooth scroll to top of page
    /// for _ in 0..<20 {
    ///     SwiftAutoGUI.vscroll(clicks: 5)
    ///     Thread.sleep(forTimeInterval: 0.05)
    /// }
    /// ```
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

    /// Scrolls the mouse wheel horizontally by the specified number of clicks.
    ///
    /// This method simulates horizontal mouse wheel scrolling, useful for navigating
    /// wide content like spreadsheets, timelines, or horizontal galleries.
    /// Not all applications support horizontal scrolling.
    ///
    /// - Parameter clicks: Number of scroll clicks. Positive scrolls left, negative scrolls right.
    ///
    /// - Note: Horizontal scrolling requires application support and may not work everywhere.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Scroll left 5 clicks
    /// SwiftAutoGUI.hscroll(clicks: 5)
    ///
    /// // Scroll right 10 clicks
    /// SwiftAutoGUI.hscroll(clicks: -10)
    ///
    /// // Navigate through horizontal tabs
    /// SwiftAutoGUI.hscroll(clicks: -3)
    /// Thread.sleep(forTimeInterval: 0.5)
    /// SwiftAutoGUI.leftClick()
    /// ```
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
