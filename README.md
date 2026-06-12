# SwiftAutoGUI

<!-- # Badges -->
![SPM is supported](https://img.shields.io/badge/SPM-Supported-orange)
[![Github issues](https://img.shields.io/github/issues/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/issues)
[![Github forks](https://img.shields.io/github/forks/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/network/members)
[![Github stars](https://img.shields.io/github/stars/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/stargazers)
[![Github top language](https://img.shields.io/github/languages/top/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)
[![Github license](https://img.shields.io/github/license/NakaokaRei/SwiftAutoGUI)](https://github.com/NakaokaRei/SwiftAutoGUI/)

<!-- # Short Description -->

A Swift library for macOS automation — mouse, keyboard, screenshots, image recognition, and AI-powered agents.

This repository is inspired by [pyautogui](https://github.com/asweigart/pyautogui).

## Demo

AI Agent that autonomously observes the screen and executes actions to achieve a goal.

`sagui agent "Open Safari and search for Swift"`

<img src="https://github.com/user-attachments/assets/0b501faa-ff8a-4fee-8bf7-9db49bbd6766" alt="Demo: sagui agent" width="900">

# Requirements

- macOS 26.0+
- Swift 6.0+

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

## Homebrew (sagui CLI)

The `sagui` command-line tool is available via the [Homebrew tap](https://github.com/NakaokaRei/homebrew-tap):

```bash
brew install NakaokaRei/tap/sagui
```

After install, grant **Accessibility** permission to your terminal in
System Settings → Privacy & Security → Accessibility.


# Example Usage

If you would like to know more details, please refer to the [DocC Style Document](https://nakaokarei.github.io/SwiftAutoGUI/documentation/swiftautogui/).

## AI Agent

SwiftAutoGUI includes an Agent that can autonomously observe the screen, reason about what it sees, and execute actions in a loop until a goal is achieved. This follows the **ReAct** (Observe → Think → Act) pattern using a vision-capable LLM.

```swift
import SwiftAutoGUI

let backend = OpenAIVisionBackend(apiKey: "sk-...", model: "gpt-4o")
let agent = Agent(backend: backend, maxIterations: 15)

let result = try await agent.run(goal: "Open Safari and search for Swift")
print("Completed: \(result.completed), Steps: \(result.iterationsUsed)")
```

## Basic Usage

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

# Claude Code Plugin

SwiftAutoGUI ships as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin so Claude can control macOS GUI applications via the `sagui` CLI — taking screenshots, clicking buttons, typing text, scrolling, and more.

## Install from the marketplace

Inside Claude Code:

```text
/plugin marketplace add NakaokaRei/SwiftAutoGUI
/plugin install swift-auto-gui@swift-auto-gui
```

This installs the `macos-control` skill, which is invoked as `/swift-auto-gui:macos-control`. The skill walks Claude through installing the `sagui` binary the first time it's needed (Swift 6.2+ toolchain required).

## Permissions

Grant the application running Claude Code (Terminal.app, iTerm, etc.) both:

- **Accessibility** — System Settings → Privacy & Security → Accessibility
- **Screen Recording** — System Settings → Privacy & Security → Screen Recording

For full skill details, see [`plugins/swift-auto-gui/skills/macos-control/SKILL.md`](plugins/swift-auto-gui/skills/macos-control/SKILL.md).

# Star History

<a href="https://www.star-history.com/?repos=NakaokaRei%2FSwiftAutoGUI&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=NakaokaRei/SwiftAutoGUI&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=NakaokaRei/SwiftAutoGUI&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=NakaokaRei/SwiftAutoGUI&type=date&legend=top-left" />
 </picture>
</a>

# Contributors

- [NakaokaRei](https://github.com/NakaokaRei)

<!-- CREATED_BY_LEADYOU_README_GENERATOR -->

# License
MIT license. See the [LICENSE file](/LICENSE) for details.
