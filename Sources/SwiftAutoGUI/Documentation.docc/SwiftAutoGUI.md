# ``SwiftAutoGUI``

A Swift library for programmatically controlling the mouse and keyboard on macOS.

## Overview

SwiftAutoGUI brings GUI automation to Swift, inspired by PyAutoGUI. It provides a simple API for automating mouse movements, clicks, keyboard input, and more on macOS.

## Getting Started

### Installation

#### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/NakaokaRei/SwiftAutoGUI", branch: "master")
]
```

### Basic Usage

#### Mouse Control

```swift
import SwiftAutoGUI

// Move mouse to absolute position
SwiftAutoGUI.moveTo(x: 100, y: 200)

// Move with animation
SwiftAutoGUI.moveTo(x: 300, y: 400, duration: 1.0)

// Click operations
SwiftAutoGUI.click()
SwiftAutoGUI.rightClick()
SwiftAutoGUI.doubleClick()

// Drag
SwiftAutoGUI.dragTo(x: 500, y: 600, duration: 1.0)

// Scroll
SwiftAutoGUI.vscroll(clicks: 10)  // Vertical scroll
SwiftAutoGUI.hscroll(clicks: 5)   // Horizontal scroll
```

#### Keyboard Control

```swift
// Press and release keys
SwiftAutoGUI.keyDown(.space)
SwiftAutoGUI.keyUp(.space)

// Single key press
SwiftAutoGUI.press(.return)

// Type text
SwiftAutoGUI.write("Hello, World!")

// Keyboard shortcuts
SwiftAutoGUI.hotkey(.command, .c)  // Command+C
SwiftAutoGUI.hotkey(.command, .shift, .a)  // Command+Shift+A
```

#### Screenshots

```swift
// Full screen screenshot
if let screenshot = SwiftAutoGUI.screenshot() {
    // Returns NSImage
}

// Region screenshot
let region = CGRect(x: 0, y: 0, width: 500, height: 300)
if let regionShot = SwiftAutoGUI.screenshot(region: region) {
    // Process image
}

// Save to file
SwiftAutoGUI.screenshot(imageFilename: "screenshot.png")
```

#### Image Recognition

```swift
// Locate image on screen
if let location = SwiftAutoGUI.locateOnScreen("button.png") {
    print("Found at: \(location)")
}

// Find center of image
if let center = SwiftAutoGUI.locateCenterOnScreen("button.png") {
    SwiftAutoGUI.click(x: center.x, y: center.y)
}

// Find all occurrences
let allLocations = SwiftAutoGUI.locateAllOnScreen("icon.png")
```

### Using Actions

The `Action` enum provides a declarative way to define automation sequences with async/await support:

```swift
import SwiftAutoGUI

// Single action
await Action.leftClick.execute()

// Move with smooth animation
await Action.moveSmooth(
    to: CGPoint(x: 300, y: 400),
    duration: 1.5,
    tweening: .easeInOutQuad
).execute()

// Execute multiple actions in sequence
let actions: [Action] = [
    .move(to: CGPoint(x: 100, y: 100)),
    .wait(0.5),
    .leftClick,
    .wait(0.2),
    .write("Hello, World!"),
    .wait(0.1),
    .keyShortcut([.command, .a])  // Select all
]
await actions.execute()

// Using sequence action
await Action.sequence([
    .move(to: CGPoint(x: 200, y: 200)),
    .doubleClick(),
    .wait(0.5),
    .write("New text")
]).execute()

// Convenience actions
await Action.copy().execute()        // Command+C
await Action.paste().execute()       // Command+V
await Action.selectAll().execute()   // Command+A
await Action.undo().execute()        // Command+Z

// Click at specific position
await Action.clickAt(CGPoint(x: 150, y: 150)).execute()

// Type and press Enter
await Action.typeAndEnter("search query").execute()

// Smooth scrolling
await Action.smoothVScroll(
    clicks: 10,
    duration: 2.0,
    tweening: .easeInOut
).execute()
```

### Permissions

macOS requires accessibility permissions for GUI automation:

1. Open System Settings
2. Privacy & Security → Accessibility
3. Add your application and grant permission

### Sample App

Try the demo application:

```bash
open Sample/Sample.xcodeproj
# Run in Xcode (⌘+R)
```

The sample app demonstrates all SwiftAutoGUI features with interactive examples.

## Topics

### API Reference

- ``SwiftAutoGUI/SwiftAutoGUI``
- ``Action``
- ``Key``
- ``TweeningFunction``