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

### Basic Usage with Actions (Recommended)

The `Action` enum provides a declarative and intuitive way to build automation sequences. This is the **recommended approach** for using SwiftAutoGUI.

#### Quick Start

```swift
import SwiftAutoGUI

// Execute single actions
await Action.leftClick.execute()
await Action.write("Hello!").execute()
await Action.keyShortcut([.command, .s]).execute()  // Save
```

#### Building Action Sequences

```swift
// Define a sequence of actions
let actions: [Action] = [
    .move(to: CGPoint(x: 100, y: 100)),
    .wait(0.5),
    .leftClick,
    .write("Hello, SwiftAutoGUI!"),
    .keyShortcut([.returnKey])
]

// Execute the sequence
await actions.execute()
```

#### Mouse Actions

```swift
// Basic mouse operations
let mouseActions: [Action] = [
    .move(to: CGPoint(x: 200, y: 200)),
    .leftClick,
    .doubleClick(),
    .rightClick,
    .drag(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 300, y: 300))
]
await mouseActions.execute()

// Smooth animations
await Action.moveSmooth(
    to: CGPoint(x: 500, y: 500),
    duration: 2.0,
    tweening: .easeInOutQuad
).execute()

// Scrolling
await Action.vscroll(clicks: -5).execute()  // Scroll down
await Action.hscroll(clicks: 3).execute()   // Scroll right
```

#### Keyboard Actions

```swift
// Text input
await Action.write("Fast typing").execute()
await Action.write("Slow typing", interval: 0.1).execute()  // With delay

// Common shortcuts as convenience methods
await Action.copy().execute()       // Cmd+C
await Action.paste().execute()      // Cmd+V
await Action.cut().execute()        // Cmd+X
await Action.selectAll().execute()  // Cmd+A
await Action.save().execute()       // Cmd+S
await Action.undo().execute()       // Cmd+Z
await Action.redo().execute()       // Cmd+Shift+Z

// Custom shortcuts
await Action.keyShortcut([.command, .option, .n]).execute()
```

#### Complex Automation Example

```swift
// Example: Copy text from one location and paste elsewhere
let copyPasteWorkflow: [Action] = [
    // Navigate to source
    .move(to: CGPoint(x: 100, y: 200)),
    .leftClick,
    Action.selectAll(),
    .wait(0.2),
    Action.copy(),
    
    // Navigate to destination
    .move(to: CGPoint(x: 500, y: 400)),
    .leftClick,
    Action.paste(),
    
    // Save the result
    Action.save()
]

await copyPasteWorkflow.execute()
```

#### Creating Reusable Functions

```swift
// Define reusable action sequences
func fillForm(name: String, email: String) -> [Action] {
    return [
        .move(to: CGPoint(x: 200, y: 150)),
        .leftClick,
        .write(name),
        .keyShortcut([.tab]),
        .write(email),
        .keyShortcut([.tab]),
        .keyShortcut([.returnKey])  // Submit
    ]
}

// Use the function
let formActions = fillForm(name: "John Doe", email: "john@example.com")
await formActions.execute()
```

### Direct Method Calls (Alternative)

While the Action pattern is recommended, you can also use SwiftAutoGUI methods directly for simple operations:

```swift
import SwiftAutoGUI

// Mouse operations
Task {
    await SwiftAutoGUI.move(to: CGPoint(x: 100, y: 200), duration: 0)
    SwiftAutoGUI.leftClick()
    SwiftAutoGUI.vscroll(clicks: 10)
}

// Keyboard operations
Task {
    await SwiftAutoGUI.sendKeyShortcut([.command, .c])
    await SwiftAutoGUI.write("Hello, World!")
}

// Screenshots
if let screenshot = SwiftAutoGUI.screenshot() {
    // Process NSImage
}

// Image recognition
if let location = SwiftAutoGUI.locateOnScreen("button.png") {
    let center = CGPoint(x: location.midX, y: location.midY)
    await SwiftAutoGUI.move(to: center, duration: 0)
    SwiftAutoGUI.leftClick()
}
```

**Note**: Direct method calls require manual handling of async/await and proper sequencing. The Action pattern handles this automatically and provides better readability.

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