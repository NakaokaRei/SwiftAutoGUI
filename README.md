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

```bash
sagui --version
sagui key list
sagui key shortcut return
sagui mouse click --x 100 --y 200
sagui mouse click --right --x 100 --y 200
```

## Optional Chromium CDP backend

> Quick start: [Browser Agent guide](Documentation/BrowserAgent.md)

`SwiftAutoGUIBrowser` adds semantic automation for an existing Chrome, Edge,
or other Chromium debugging session. It is a separate product, so applications
that use only native macOS automation do not acquire browser-specific code.

Add the optional product to the client target:

```swift
.target(
    name: "MyProject",
    dependencies: [
        .product(name: "SwiftAutoGUI", package: "SwiftAutoGUI"),
        .product(name: "SwiftAutoGUIBrowser", package: "SwiftAutoGUI")
    ]
)
```

Start Chromium with a dedicated profile and a loopback debugging port. Chrome
136 and later do not honor remote debugging against the default profile.

```bash
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/swift-auto-gui-browser-profile
```

Connect with an explicit navigation allowlist:

```swift
import SwiftAutoGUI
import SwiftAutoGUIBrowser

let browser = try await BrowserSession.connect(
    endpoint: URL(string: "http://127.0.0.1:9222")!,
    securityPolicy: BrowserSecurityPolicy(
        allowedDomains: ["example.com", "*.example.org"]
    )
)

let observation = try await browser.observe()
print(observation.formattedContext)

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
let browserAgent = Agent(
    backend: OpenAIVisionBackend(apiKey: apiKey),
    automationBackend: browser
)
```

The browser Agent is intentionally browser-only: native app, window, AX-label,
and coordinate mouse actions fail as unsupported instead of falling back to
Accessibility or CGEvent. Stale DOM elements also fail safely without clicking
a saved coordinate. Cross-origin navigation and downloads require a
`BrowserActionAuthorizing` implementation; without one they are denied.

The `sagui` CLI supports deterministic CDP commands as well as the browser-only Agent:

```bash
sagui browser tabs
sagui browser observe --tab-id TARGET_ID
sagui browser click --tab-id TARGET_ID --role link --name "Issues" --domain github.com
sagui browser agent "Open issue 118" --domain github.com --allow-cross-origin
```


# Example Usage

For complete API and module documentation, see the [SwiftAutoGUI DocC site](https://nakaokarei.github.io/SwiftAutoGUI/documentation/).

## AI Agent

SwiftAutoGUI includes an Agent that can autonomously observe the screen, reason about what it sees, and execute actions in a loop until a goal is achieved. This follows the **ReAct** (Observe → Think → Act) pattern using a vision-capable LLM.

```swift
import SwiftAutoGUI

let backend = OpenAIVisionBackend(apiKey: "sk-...", model: "gpt-5.6-sol")
let agent = Agent(
    backend: backend,
    maxIterations: 15,
    visionMode: .automatic
)

let result = try await agent.run(goal: "Open Safari and search for Swift")
print("Completed: \(result.completed), Steps: \(result.iterationsUsed)")
```

The CLI prints the effective reasoning effort when it starts and the model-provided
reasoning summary for every agent step:

```bash
sagui agent "Open Safari and search for Swift" --reasoning-effort low
sagui agent "Press the Save button" --vision-mode automatic
```

`--reasoning-effort` accepts `none`, `low`, `medium`, `high`, `xhigh`, or `max`.
It defaults to `low` for GPT-5.6 models. The per-step `Reasoning:` line is the
agent's concise explanation of its chosen actions, not the model's hidden chain of thought.

When screen context is enabled, actionable Accessibility elements receive step-local
identifiers such as `[#12]`. The agent can target these identifiers directly, resolves
them again immediately before execution, and rejects stale elements safely. Each action
returns a structured result describing the execution method, failure, UI change, and
focus change. If an action changes the UI, the remaining batch is stopped and the agent
observes the new state before continuing.

`--vision-mode` accepts `always`, `automatic`, or `never`. `automatic` omits the
screenshot when actionable Accessibility elements are available; `always` preserves
the original behavior and remains the default.

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

SwiftAutoGUI ships as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin so Claude can control native macOS applications and Chromium pages through the `sagui` CLI.

## Install from the marketplace

Inside Claude Code:

```text
/plugin marketplace add NakaokaRei/SwiftAutoGUI
/plugin install swift-auto-gui@swift-auto-gui
```

This installs two skills:

- `macos-control`, invoked as `/swift-auto-gui:macos-control`, controls native macOS UI.
- `browser-control`, invoked as `/swift-auto-gui:browser-control`, controls Chromium pages through CDP without native input fallback.

The skills walk Claude through installing or updating the `sagui` binary when needed.

## Permissions

Grant the application running Claude Code (Terminal.app, iTerm, etc.) both:

- **Accessibility** — System Settings → Privacy & Security → Accessibility
- **Screen Recording** — System Settings → Privacy & Security → Screen Recording

These permissions are required for `macos-control`; browser-only CDP actions do not require them.

For full details, see the [`macos-control`](plugins/swift-auto-gui/skills/macos-control/SKILL.md) and [`browser-control`](plugins/swift-auto-gui/skills/browser-control/SKILL.md) skill definitions.

# Contributors

- [NakaokaRei](https://github.com/NakaokaRei)

<!-- CREATED_BY_LEADYOU_README_GENERATOR -->

# License
MIT license. See the [LICENSE file](/LICENSE) for details.
