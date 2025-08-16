# SwiftAutoGUI

<!-- # Badges -->
![SPM is supported](https://img.shields.io/badge/SPM-Supported-orange)
[![Github issues](https://img.shields.io/github/issues/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/issues)
[![Github forks](https://img.shields.io/github/forks/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/network/members)
[![Github stars](https://img.shields.io/github/stars/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/stargazers)
[![Github top language](https://img.shields.io/github/languages/top/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)
[![Github license](https://img.shields.io/github/license/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)

<!-- # Short Description -->

A library for manipulating macOS with Swift, which is used to programmatically control the mouse & keyboard.

This repository is inspired by [pyautogui](https://github.com/asweigart/pyautogui).

# Requirements

- macOS 13.0+
- Swift 5.7+

# Installation

## Swift Package Manager
SwiftAutoGUI is available through [Swift Package Manager](https://www.swift.org/package-manager/).

in `Package.swift` add the following:

```swift
dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/NakaokaRei/SwiftAutoGUI", branch: "master")
],
targets: [
    .target(
        name: "MyProject",
        dependencies: [..., "SwiftAutoGUI"]
    )
    ...
]
```


# Example Usage

If you would like to know more details, please refer to the [DocC Style Document](https://nakaokarei.github.io/SwiftAutoGUI/documentation/swiftautogui/).

## Action Pattern (Recommended)

SwiftAutoGUI provides an intuitive Action pattern for building and executing automation sequences. This is the **recommended way** to use SwiftAutoGUI as it offers better readability and maintainability.

### Basic Usage

```swift
import SwiftAutoGUI

// Execute single actions
await Action.leftClick.execute()
await Action.write("Hello, World!").execute()
await Action.keyShortcut([.command, .a]).execute()  // Select all

// Build and execute action sequences
let actions: [Action] = [
    .move(to: CGPoint(x: 100, y: 100)),
    .wait(0.5),
    .leftClick,
    .write("Hello, SwiftAutoGUI!"),
    .keyShortcut([.returnKey])
]
await actions.execute()
```

### Keyboard Actions

```swift
// Text input and shortcuts
let typingActions: [Action] = [
    .write("Fast typing"),
    .wait(1.0),
    .write("Slow typing", interval: 0.1),  // 0.1 second between characters
    .keyShortcut([.command, .z])  // Undo
]
await typingActions.execute()

// Common shortcuts as convenience methods
await Action.copy().execute()       // Cmd+C
await Action.paste().execute()      // Cmd+V
await Action.cut().execute()        // Cmd+X
await Action.selectAll().execute()  // Cmd+A
await Action.save().execute()       // Cmd+S
await Action.undo().execute()       // Cmd+Z
await Action.redo().execute()       // Cmd+Shift+Z

// Special keys
await Action.keyDown(.soundUp).execute()
await Action.keyUp(.soundUp).execute()
```

### Mouse Actions

```swift
// Mouse movement and clicks
let mouseActions: [Action] = [
    .move(to: CGPoint(x: 200, y: 200)),
    .leftClick,
    .wait(0.5),
    .doubleClick(),
    .wait(0.5),
    .rightClick
]
await mouseActions.execute()

// Smooth animation with tweening
await Action.moveSmooth(
    to: CGPoint(x: 500, y: 500),
    duration: 2.0,
    tweening: .easeInOutQuad
).execute()

// Drag and drop
await Action.drag(
    from: CGPoint(x: 100, y: 100),
    to: CGPoint(x: 300, y: 300)
).execute()

// Scrolling
let scrollActions: [Action] = [
    .vscroll(clicks: -5),  // Scroll down
    .wait(1.0),
    .vscroll(clicks: 5),   // Scroll up
    .hscroll(clicks: 3)    // Scroll right
]
await scrollActions.execute()
```

### Complex Automation Example

```swift
// Example: Copy text from one app and paste to another
let copyPasteWorkflow: [Action] = [
    // Focus on source app
    .move(to: CGPoint(x: 100, y: 200)),
    .leftClick,
    .wait(0.5),
    
    // Select and copy text
    Action.selectAll(),
    .wait(0.2),
    Action.copy(),
    .wait(0.5),
    
    // Switch to destination app (using keyboard shortcut)
    .keyShortcut([.command, .tab]),
    .wait(1.0),
    
    // Paste the text
    .move(to: CGPoint(x: 500, y: 400)),
    .leftClick,
    Action.paste(),
    
    // Save the document
    Action.save()
]

await copyPasteWorkflow.execute()
```

### Creating Reusable Action Sequences

```swift
// Define reusable action sequences
func createLoginSequence(username: String, password: String) -> [Action] {
    return [
        .move(to: CGPoint(x: 400, y: 300)),
        .leftClick,
        .write(username),
        .keyShortcut([.tab]),
        .write(password),
        .keyShortcut([.returnKey])
    ]
}

// Use the sequence
let loginActions = createLoginSequence(
    username: "user@example.com",
    password: "securePassword123"
)
await loginActions.execute()
```

Currently ***only US keyboards*** are supported. Otherwise, it may not work properly.

## Direct Method Calls (Alternative)

While the Action pattern is recommended, you can also call SwiftAutoGUI methods directly for simple operations:

```swift
import SwiftAutoGUI

// Keyboard operations
Task {
    await SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
    await SwiftAutoGUI.write("Hello, World!")
}

// Mouse operations
Task {
    await SwiftAutoGUI.move(to: CGPoint(x: 100, y: 100), duration: 0)
    SwiftAutoGUI.leftClick()
    SwiftAutoGUI.vscroll(clicks: 10)
}
```

## Screenshot
SwiftAutoGUI can take screenshots of the entire screen or specific regions, save them to files, and get pixel colors.

```swift
import SwiftAutoGUI

// Take a screenshot of the entire screen
if let screenshot = SwiftAutoGUI.screenshot() {
    // Use the NSImage object
}

// Take a screenshot of a specific region
let region = CGRect(x: 100, y: 100, width: 200, height: 200)
if let regionScreenshot = SwiftAutoGUI.screenshot(region: region) {
    // Use the NSImage object
}

// Save a screenshot directly to a file
SwiftAutoGUI.screenshot(imageFilename: "screenshot.png")

// Save a region screenshot to a file
SwiftAutoGUI.screenshot(imageFilename: "region.jpg", region: region)

// Get screen size
let (width, height) = SwiftAutoGUI.size()
print("Screen size: \(width)x\(height)")

// Get the color of a specific pixel
if let color = SwiftAutoGUI.pixel(x: 100, y: 200) {
    print("Pixel color: \(color)")
}
```

## Image Recognition
SwiftAutoGUI can locate images on the screen using OpenCV template matching, similar to PyAutoGUI.

```swift
import SwiftAutoGUI

// Locate an image on the screen
if let location = SwiftAutoGUI.locateOnScreen("button.png") {
    print("Found at: \(location)")
    // location is a CGRect with the position and size
    
    // Click at the center of the found image
    let center = CGPoint(x: location.midX, y: location.midY)
    Task {
        await SwiftAutoGUI.move(to: center, duration: 0)
        SwiftAutoGUI.leftClick()
    }
}

// Search with confidence threshold (0.0-1.0)
if let location = SwiftAutoGUI.locateOnScreen("button.png", confidence: 0.9) {
    // Found with 90% confidence
}

// Search in a specific region for better performance
let searchRegion = CGRect(x: 0, y: 0, width: 500, height: 500)
if let location = SwiftAutoGUI.locateOnScreen("button.png", region: searchRegion) {
    // Found within the specified region
}

// Locate and get the center point directly
if let buttonCenter = SwiftAutoGUI.locateCenterOnScreen("button.png") {
    // buttonCenter is a CGPoint with x,y coordinates of the center
    Task {
        await SwiftAutoGUI.move(to: buttonCenter, duration: 0)
        SwiftAutoGUI.leftClick()
    }
}

// locateCenterOnScreen also supports confidence and region parameters
if let center = SwiftAutoGUI.locateCenterOnScreen("target.png", confidence: 0.8, region: searchRegion) {
    // Click at the center of the found image
    Task {
        await SwiftAutoGUI.move(to: center, duration: 0)
        SwiftAutoGUI.leftClick()
    }
}

// Find all occurrences of an image on screen
Task {
    let buttons = SwiftAutoGUI.locateAllOnScreen("button.png")
    print("Found \(buttons.count) buttons")
    for (index, button) in buttons.enumerated() {
        print("Button \(index): \(button)")
        await SwiftAutoGUI.move(to: CGPoint(x: button.midX, y: button.midY), duration: 0)
        SwiftAutoGUI.leftClick()
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// locateAllOnScreen with confidence threshold for flexible matching
let icons = SwiftAutoGUI.locateAllOnScreen("app_icon.png", confidence: 0.85)
for icon in icons {
    // Process each found icon
    print("Found icon at: \(icon)")
}

// Search for multiple matches in a specific region
let topRegion = CGRect(x: 0, y: 0, width: 1920, height: 100)
let menuItems = SwiftAutoGUI.locateAllOnScreen("menu_item.png", region: topRegion)
```


## AppleScript Execution
SwiftAutoGUI can execute AppleScript code to control macOS applications and system features.

```swift
import SwiftAutoGUI

// Execute AppleScript code
let script = """
tell application "Safari"
    activate
    make new document
    set URL of current tab of front window to "https://github.com/NakaokaRei/SwiftAutoGUI"
end tell
"""
try SwiftAutoGUI.executeAppleScript(script)

// Execute and get return value
let systemInfo = """
tell application "System Events"
    return system version of (system info)
end tell
"""
if let version = try SwiftAutoGUI.executeAppleScript(systemInfo) {
    print("macOS version: \(version)")
}

// Control system volume
try SwiftAutoGUI.executeAppleScript("set volume output volume 50")

// Display notification
let notification = """
display notification "Task completed!" with title "SwiftAutoGUI"
"""
try SwiftAutoGUI.executeAppleScript(notification)

// Execute AppleScript from file
try SwiftAutoGUI.executeAppleScriptFile("/path/to/script.applescript")
```

### Important Notes for AppleScript

When using AppleScript functionality in macOS applications, you need to configure the following:

1. **Disable App Sandbox**: In your app's `.entitlements` file, set:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <false/>
   ```
   
2. **Enable Automation Permission**: Add to your `.entitlements` file:
   ```xml
   <key>com.apple.security.automation.apple-events</key>
   <true/>
   ```

3. **Add Usage Description**: In your app's `Info.plist`, add:
   ```xml
   <key>NSAppleEventsUsageDescription</key>
   <string>Your app needs permission to control other applications.</string>
   ```

⚠️ **Note**: Disabling the sandbox reduces your app's security isolation. Only disable it if absolutely necessary for your app's functionality.

# Contributors

- [NakaokaRei](https://github.com/NakaokaRei)

<!-- CREATED_BY_LEADYOU_README_GENERATOR -->

# License
MIT license. See the [LICENSE file](/LICENSE) for details.