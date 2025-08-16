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

## Keyboard

By calling a method of the SwiftAutoGUI class as shown below, you can send key input commands to macOS. Supported keys are written in [Keycode.swift](/Sources/SwiftAutoGUI/Keycode.swift).

As shown in the sample below, you can also input shortcuts, such as moving the virtual desktop by sending the command `ctrl + ←`.

Currently ***only US keyboards*** are supported. Otherwise, it may not work properly.

```swift
import SwiftAutoGUI

// Async methods (recommended for non-blocking operations)
Task {
    // Send ctrl + ← using async method
    await SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
    
    // Send sound up using async methods
    await SwiftAutoGUI.keyDown(.soundUp)
    await SwiftAutoGUI.keyUp(.soundUp)
    
    // Type text instantly
    await SwiftAutoGUI.write("Hello, World!")
    
    // Type with 0.1 second delay between characters
    await SwiftAutoGUI.write("Slowly typed text", interval: 0.1)
}

// Synchronous methods are deprecated but still available
// SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
```

## Mouse
Similarly, mouse operations can generate basic commands such as mouse movement, clicking, and scrolling by invoking methods of the SwiftAutoGUI class.

```swift
import SwiftAutoGUI

// Async methods (recommended for non-blocking operations)
Task {
    // Move mouse by dx, dy from the current location
    await SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
    
    // Move the mouse to a specific position instantly
    // This parameter is the `CGWindow` coordinate.
    await SwiftAutoGUI.move(to: CGPointMake(0, 0), duration: 0)
    
    // Move with animation over 2 seconds
    await SwiftAutoGUI.move(to: CGPointMake(500, 500), duration: 2.0, tweening: .easeInOutQuad)
    
    // Double and triple clicks (async)
    await SwiftAutoGUI.doubleClick()
    await SwiftAutoGUI.tripleClick()
}

// Click where the mouse is located (no async needed)
SwiftAutoGUI.leftClick() // left
SwiftAutoGUI.rightClick() // right

// Scroll (no async needed - doesn't use Thread.sleep)
SwiftAutoGUI.vscroll(clicks: 10) // up
SwiftAutoGUI.vscroll(clicks: -10) // down
SwiftAutoGUI.hscroll(clicks: 10) // left
SwiftAutoGUI.hscroll(clicks: -10) // right

// Drag operations (no async needed)
SwiftAutoGUI.leftDragged(to: CGPoint(x: 300, y: 400), from: CGPoint(x: 100, y: 200))
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

## Action Pattern (New!)
SwiftAutoGUI now provides an Action pattern for building and executing automation sequences declaratively.

```swift
import SwiftAutoGUI

// Single action execution
await Action.leftClick.execute()

// Build complex sequences
let actions: [Action] = [
    .move(to: CGPoint(x: 100, y: 100)),
    .wait(0.5),
    .leftClick,
    .write("Hello, SwiftAutoGUI!"),
    .keyShortcut([.returnKey])
]
await actions.execute()

// Use convenience methods for common shortcuts
await Action.copy().execute()
await Action.paste().execute()
await Action.save().execute()

// Create custom sequences
let mySequence = Action.sequence([
    Action.selectAll(),
    .wait(0.2),
    Action.copy(),
    .move(to: CGPoint(x: 500, y: 500)),
    .leftClick,
    Action.paste()
])
await mySequence.execute()

// Mouse actions
let mouseDemo: [Action] = [
    .move(to: CGPoint(x: 100, y: 100)),
    .doubleClick(),
    .drag(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 300, y: 300)),
    .vscroll(clicks: -5),
    .hscroll(clicks: 3)
]
await mouseDemo.execute()

// Smooth animations
await Action.moveSmooth(
    to: CGPoint(x: 500, y: 500), 
    duration: 2.0, 
    tweening: .easeInOutQuad
).execute()
```

The Action pattern makes it easy to:
- Build reusable automation sequences
- Execute actions asynchronously with proper timing
- Create readable and maintainable automation code

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