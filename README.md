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
## Keyboard and Mouse Control

See [Keycode.swift](/Sources/SwiftAutoGUI/Keycode.swift) for supported keys.
If it is not a US keyboard, This may not work properly.

```swift
import SwiftAutoGUI

// Send ctrl + ←
SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])

// Send sound up
SwiftAutoGUI.keyDown(.soundUp)
SwiftAutoGUI.keyUp(.soundUp)

// Move mouse by dx, dy from the current location
SwiftAutoGUI.moveMouse(dx: 10, dy: 10)

// Click where the mouse is located
SwiftAutoGUI.leftClick()

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