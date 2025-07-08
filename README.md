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

// Send ctrl + ←
SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])

// Send sound up
SwiftAutoGUI.keyDown(.soundUp)
SwiftAutoGUI.keyUp(.soundUp)

// Type text using the async write method
Task {
    // Type text instantly
    await SwiftAutoGUI.write("Hello, World!")
    
    // Type with 0.1 second delay between characters
    await SwiftAutoGUI.write("Slowly typed text", interval: 0.1)
}
```

## Mouse
Similarly, mouse operations can generate basic commands such as mouse movement, clicking, and scrolling by invoking methods of the SwiftAutoGUI class.

```swift
import SwiftAutoGUI

// Move mouse by dx, dy from the current location
SwiftAutoGUI.moveMouse(dx: 10, dy: 10)

// Move the mouse to a specific position
// This parameter is the `CGWindow` coordinate.
SwiftAutoGUI.move(to: CGPointMake(0, 0))

// Click where the mouse is located
SwiftAutoGUI.leftClick() // left
SwiftAutoGUI.rightClick() // right

// Scroll
SwiftAutoGUI.vscroll(clicks: 10) // up
SwiftAutoGUI.vscroll(clicks: -10) // down
SwiftAutoGUI.hscroll(clicks: 10) // left
SwiftAutoGUI.hscroll(clicks: -10) // right
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
    SwiftAutoGUI.move(to: center)
    SwiftAutoGUI.leftClick()
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
    SwiftAutoGUI.move(to: buttonCenter)
    SwiftAutoGUI.leftClick()
}

// locateCenterOnScreen also supports confidence and region parameters
if let center = SwiftAutoGUI.locateCenterOnScreen("target.png", confidence: 0.8, region: searchRegion) {
    // Click at the center of the found image
    SwiftAutoGUI.move(to: center)
    SwiftAutoGUI.leftClick()
}

// Find all occurrences of an image on screen
let buttons = SwiftAutoGUI.locateAllOnScreen("button.png")
print("Found \(buttons.count) buttons")
for (index, button) in buttons.enumerated() {
    print("Button \(index): \(button)")
    SwiftAutoGUI.move(to: CGPoint(x: button.midX, y: button.midY))
    SwiftAutoGUI.leftClick()
    Thread.sleep(forTimeInterval: 0.5)
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

# Contributors

- [NakaokaRei](https://github.com/NakaokaRei)

<!-- CREATED_BY_LEADYOU_README_GENERATOR -->

# License
MIT license. See the [LICENSE file](/LICENSE) for details.