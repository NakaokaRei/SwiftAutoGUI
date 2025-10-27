import Foundation
import AppKit

/// Represents an automation action that can be executed.
///
/// The `Action` enum provides a declarative way to define and execute automation sequences.
/// Instead of calling SwiftAutoGUI methods directly, you can create actions and execute them
/// using the `execute()` method.
///
/// ## Overview
///
/// Actions allow you to:
/// - Build complex automation sequences declaratively
/// - Execute actions asynchronously with proper timing
/// - Compose and reuse action sequences
///
/// ## Example Usage
///
/// ```swift
/// // Single action
/// await Action.leftClick.execute()
///
/// // Multiple actions in sequence
/// let actions: [Action] = [
///     .move(to: CGPoint(x: 100, y: 100)),
///     .wait(0.5),
///     .leftClick,
///     .write("Hello, World!")
/// ]
/// await actions.execute()
///
/// // Using convenience methods
/// await Action.copy().execute()
/// await Action.paste().execute()
/// ```
///
/// ## Topics
///
/// ### Keyboard Actions
/// - ``keyDown(_:)``
/// - ``keyUp(_:)``
/// - ``write(_:interval:)``
/// - ``keyShortcut(_:)``
///
/// ### Mouse Movement Actions
/// - ``move(to:)``
/// - ``moveSmooth(to:duration:tweening:fps:)``
/// - ``moveMouse(dx:dy:)``
///
/// ### Mouse Click Actions
/// - ``leftClick``
/// - ``rightClick``
/// - ``doubleClick(button:)``
/// - ``doubleClickAt(position:button:)``
/// - ``tripleClick(button:)``
/// - ``tripleClickAt(position:button:)``
///
/// ### Dragging Actions
/// - ``drag(from:to:)``
///
/// ### Scrolling Actions
/// - ``vscroll(clicks:)``
/// - ``hscroll(clicks:)``
/// - ``smoothVScroll(clicks:duration:tweening:fps:)``
/// - ``smoothHScroll(clicks:duration:tweening:fps:)``
///
/// ### Screenshot Actions
/// - ``screenshot``
/// - ``screenshotRegion(_:)``
/// - ``screenshotToFile(filename:region:)``
///
/// ### Screen Information Actions
/// - ``getScreenSize``
/// - ``getPixel(x:y:)``
///
/// ### Image Recognition Actions
/// - ``locateOnScreen(_:grayscale:confidence:region:)``
/// - ``locateCenterOnScreen(_:grayscale:confidence:region:)``
/// - ``locateAllOnScreen(_:grayscale:confidence:region:)``
///
/// ### Dialog Actions
/// - ``alert(_:title:button:)``
/// - ``confirm(_:title:buttons:)``
/// - ``prompt(_:title:defaultAnswer:button:)``
/// - ``password(_:title:defaultAnswer:button:)``
///
/// ### AppleScript Actions
/// - ``executeAppleScript(_:)``
/// - ``executeAppleScriptFile(_:)``
///
/// ### Control Flow Actions
/// - ``wait(_:)``
/// - ``sequence(_:)``
///
/// ### Executing Actions
/// - ``execute()``
///
/// ### Convenience Methods
/// - ``clickAt(_:button:)``
/// - ``typeAndEnter(_:interval:)``
/// - ``commandKey(_:)``
/// - ``save()``
/// - ``copy()``
/// - ``paste()``
/// - ``cut()``
/// - ``selectAll()``
/// - ``undo()``
/// - ``redo()``
public enum Action {
    // MARK: - Keyboard Operations
    
    /// Press down a key.
    case keyDown(Key)
    
    /// Release a key.
    case keyUp(Key)
    
    /// Type text with optional interval between characters.
    case write(String, interval: TimeInterval = 0)
    
    /// Send a keyboard shortcut.
    case keyShortcut([Key])
    
    // MARK: - Mouse Movement
    
    /// Move mouse to absolute position.
    case move(to: CGPoint)
    
    /// Move mouse smoothly to position with animation.
    case moveSmooth(to: CGPoint, duration: TimeInterval, tweening: TweeningFunction = .linear, fps: Double = 60.0)
    
    /// Move mouse by relative offset.
    case moveMouse(dx: CGFloat, dy: CGFloat)
    
    // MARK: - Mouse Clicks
    
    /// Perform a left click.
    case leftClick
    
    /// Perform a right click.
    case rightClick
    
    /// Perform a double click.
    case doubleClick(button: SwiftAutoGUI.MouseButton = .left)
    
    /// Perform a double click at specific position.
    case doubleClickAt(position: CGPoint, button: SwiftAutoGUI.MouseButton = .left)
    
    /// Perform a triple click.
    case tripleClick(button: SwiftAutoGUI.MouseButton = .left)
    
    /// Perform a triple click at specific position.
    case tripleClickAt(position: CGPoint, button: SwiftAutoGUI.MouseButton = .left)
    
    // MARK: - Dragging
    
    /// Drag from one position to another.
    case drag(from: CGPoint, to: CGPoint)
    
    // MARK: - Scrolling
    
    /// Vertical scroll.
    case vscroll(clicks: Int)
    
    /// Horizontal scroll.
    case hscroll(clicks: Int)
    
    /// Smooth vertical scroll with animation.
    case smoothVScroll(clicks: Int, duration: TimeInterval, tweening: TweeningFunction = .linear, fps: Double = 60.0)
    
    /// Smooth horizontal scroll with animation.
    case smoothHScroll(clicks: Int, duration: TimeInterval, tweening: TweeningFunction = .linear, fps: Double = 60.0)
    
    // MARK: - Screenshots and Screen Information
    
    /// Take a screenshot of the entire screen.
    case screenshot
    
    /// Take a screenshot of a specific region.
    case screenshotRegion(CGRect)
    
    /// Save a screenshot to a file.
    case screenshotToFile(filename: String, region: CGRect? = nil)
    
    /// Get screen size.
    case getScreenSize
    
    /// Get pixel color at position.
    case getPixel(x: Int, y: Int)
    
    // MARK: - Image Recognition
    
    /// Locate an image on screen.
    case locateOnScreen(String, grayscale: Bool = true, confidence: Double = 0.9, region: CGRect? = nil)
    
    /// Locate center of an image on screen.
    case locateCenterOnScreen(String, grayscale: Bool = true, confidence: Double = 0.9, region: CGRect? = nil)
    
    /// Locate all instances of an image on screen.
    case locateAllOnScreen(String, grayscale: Bool = true, confidence: Double = 0.9, region: CGRect? = nil)
    
    // MARK: - Dialogs
    
    /// Show an alert dialog.
    case alert(String, title: String = "Alert", button: String = "OK")
    
    /// Show a confirm dialog.
    case confirm(String, title: String = "Confirm", buttons: [String] = ["OK", "Cancel"])
    
    /// Show a prompt dialog.
    case prompt(String, title: String = "Prompt", defaultAnswer: String = "", button: String = "OK")
    
    /// Show a password dialog.
    case password(String, title: String = "Password", defaultAnswer: String = "", button: String = "OK")
    
    // MARK: - AppleScript
    
    /// Execute an AppleScript.
    case executeAppleScript(String)
    
    /// Execute an AppleScript from file.
    case executeAppleScriptFile(String)
    
    // MARK: - Control Flow
    
    /// Wait for specified duration.
    case wait(TimeInterval)
    
    /// Execute a sequence of actions.
    case sequence([Action])
    
    // MARK: - Execution Methods
    
    /// Execute the action asynchronously.
    ///
    /// This method allows for smooth animations and proper execution of all actions.
    ///
    /// Example:
    /// ```swift
    /// await Action.leftClick.execute()
    /// await Action.moveSmooth(to: CGPoint(x: 100, y: 100), duration: 1.0).execute()
    /// await Action.sequence([.move(to: point), .wait(0.5), .leftClick]).execute()
    /// ```
    @MainActor
    @discardableResult
    public func execute() async -> Any? {
        switch self {
        case .keyDown(let key):
            await SwiftAutoGUI.keyDown(key)
            return nil
            
        case .keyUp(let key):
            await SwiftAutoGUI.keyUp(key)
            return nil
            
        case .write(let text, let interval):
            await SwiftAutoGUI.write(text, interval: interval)
            return nil
            
        case .keyShortcut(let keys):
            await SwiftAutoGUI.sendKeyShortcut(keys)
            return nil
            
        case .move(let to):
            await SwiftAutoGUI.move(to: to, duration: 0)
            return nil
            
        case .moveSmooth(let to, let duration, let tweening, let fps):
            await SwiftAutoGUI.move(to: to, duration: duration, tweening: tweening, fps: fps)
            return nil
            
        case .moveMouse(let dx, let dy):
            await SwiftAutoGUI.moveMouse(dx: dx, dy: dy)
            return nil
            
        case .leftClick:
            SwiftAutoGUI.leftClick()
            return nil
            
        case .rightClick:
            SwiftAutoGUI.rightClick()
            return nil
            
        case .doubleClick(let button):
            await SwiftAutoGUI.doubleClick(button: button)
            return nil
            
        case .doubleClickAt(let position, let button):
            await SwiftAutoGUI.doubleClick(at: position, button: button)
            return nil
            
        case .tripleClick(let button):
            await SwiftAutoGUI.tripleClick(button: button)
            return nil
            
        case .tripleClickAt(let position, let button):
            await SwiftAutoGUI.tripleClick(at: position, button: button)
            return nil
            
        case .drag(let from, let to):
            SwiftAutoGUI.leftDragged(to: to, from: from)
            return nil
            
        case .vscroll(let clicks):
            SwiftAutoGUI.vscroll(clicks: clicks)
            return nil
            
        case .hscroll(let clicks):
            SwiftAutoGUI.hscroll(clicks: clicks)
            return nil
            
        case .smoothVScroll(let clicks, let duration, let tweening, let fps):
            await SwiftAutoGUI.vscroll(clicks: clicks, duration: duration, tweening: tweening, fps: fps)
            return nil
            
        case .smoothHScroll(let clicks, let duration, let tweening, let fps):
            await SwiftAutoGUI.hscroll(clicks: clicks, duration: duration, tweening: tweening, fps: fps)
            return nil
            
        case .screenshot:
            return try? await SwiftAutoGUI.screenshot()

        case .screenshotRegion(let region):
            return try? await SwiftAutoGUI.screenshot(region: region)

        case .screenshotToFile(let filename, let region):
            return try? await SwiftAutoGUI.screenshot(imageFilename: filename, region: region)

        case .getScreenSize:
            return SwiftAutoGUI.size()

        case .getPixel(let x, let y):
            return try? await SwiftAutoGUI.pixel(x: x, y: y)
            
        case .locateOnScreen(let image, let grayscale, let confidence, let region):
            return try? await SwiftAutoGUI.locateOnScreen(image, grayscale: grayscale, confidence: confidence, region: region)

        case .locateCenterOnScreen(let image, let grayscale, let confidence, let region):
            return try? await SwiftAutoGUI.locateCenterOnScreen(image, grayscale: grayscale, confidence: confidence, region: region)

        case .locateAllOnScreen(let image, let grayscale, let confidence, let region):
            return try? await SwiftAutoGUI.locateAllOnScreen(image, grayscale: grayscale, confidence: confidence, region: region)
            
        case .alert(let text, let title, let button):
            return SwiftAutoGUI.alert(text, title: title, button: button)
            
        case .confirm(let text, let title, let buttons):
            return SwiftAutoGUI.confirm(text, title: title, buttons: buttons)
            
        case .prompt(let text, let title, let defaultAnswer, _):
            return SwiftAutoGUI.prompt(text, title: title, default: defaultAnswer)
            
        case .password(let text, let title, let defaultAnswer, _):
            return SwiftAutoGUI.password(text, title: title, default: defaultAnswer)
            
        case .executeAppleScript(let script):
            do {
                return try SwiftAutoGUI.executeAppleScript(script)
            } catch {
                print("AppleScript execution failed: \(error)")
                return nil
            }
            
        case .executeAppleScriptFile(let path):
            do {
                return try SwiftAutoGUI.executeAppleScriptFile(path)
            } catch {
                print("AppleScript file execution failed: \(error)")
                return nil
            }
            
        case .wait(let interval):
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            return nil
            
        case .sequence(let actions):
            var results: [Any?] = []
            for action in actions {
                results.append(await action.execute())
            }
            return results
        }
    }
}

// MARK: - Array Extension

extension Array where Element == Action {
    /// Execute all actions in the array asynchronously.
    ///
    /// Example:
    /// ```swift
    /// let actions: [Action] = [
    ///     .moveSmooth(to: point, duration: 1.0),
    ///     .wait(0.5),
    ///     .leftClick
    /// ]
    /// await actions.execute()
    /// ```
    @MainActor
    @discardableResult
    public func execute() async -> [Any?] {
        var results: [Any?] = []
        for action in self {
            results.append(await action.execute())
        }
        return results
    }
}

// MARK: - Convenience Initializers

extension Action {
    /// Create an action that clicks at a specific position.
    ///
    /// This is a convenience method that moves to the position and then clicks.
    public static func clickAt(_ position: CGPoint, button: SwiftAutoGUI.MouseButton = .left) -> Action {
        return .sequence([
            .move(to: position),
            button == .left ? .leftClick : .rightClick
        ])
    }
    
    /// Create an action that types text and presses Enter.
    public static func typeAndEnter(_ text: String, interval: TimeInterval = 0) -> Action {
        return .sequence([
            .write(text, interval: interval),
            .keyShortcut([.returnKey])
        ])
    }
    
    /// Create an action that performs a keyboard shortcut with Command key.
    public static func commandKey(_ key: Key) -> Action {
        return .keyShortcut([.command, key])
    }
    
    /// Create an action that saves the current document (Command+S).
    public static func save() -> Action {
        return .keyShortcut([.command, .s])
    }
    
    /// Create an action that copies the current selection (Command+C).
    public static func copy() -> Action {
        return .keyShortcut([.command, .c])
    }
    
    /// Create an action that pastes from clipboard (Command+V).
    public static func paste() -> Action {
        return .keyShortcut([.command, .v])
    }
    
    /// Create an action that cuts the current selection (Command+X).
    public static func cut() -> Action {
        return .keyShortcut([.command, .x])
    }
    
    /// Create an action that selects all (Command+A).
    public static func selectAll() -> Action {
        return .keyShortcut([.command, .a])
    }
    
    /// Create an action that undoes the last action (Command+Z).
    public static func undo() -> Action {
        return .keyShortcut([.command, .z])
    }
    
    /// Create an action that redoes the last undone action (Command+Shift+Z).
    public static func redo() -> Action {
        return .keyShortcut([.command, .shift, .z])
    }
}