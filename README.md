# SwiftAutoGUI

<!-- # Badges -->
![SPM is supported](https://img.shields.io/badge/SPM-Supported-orange)
[![Github issues](https://img.shields.io/github/issues/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/issues)
[![Github forks](https://img.shields.io/github/forks/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/network/members)
[![Github stars](https://img.shields.io/github/stars/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/stargazers)
[![Github top language](https://img.shields.io/github/languages/top/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)
[![Github license](https://img.shields.io/github/license/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)

<!-- # Short Description -->

Used to programmatically control the mouse & keyboard.
A library for manipulating macOS with Swift.

This repository is implemented with reference to [pyautogui](https://github.com/asweigart/pyautogui).

# Installation
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

# Contributors

- [NakaokaRei](https://github.com/NakaokaRei)

<!-- CREATED_BY_LEADYOU_README_GENERATOR -->

# License
MIT license. See the [LICENSE file](/LICENSE) for details.