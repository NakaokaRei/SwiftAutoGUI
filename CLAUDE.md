# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftAutoGUI is a Swift library for programmatically controlling the mouse and keyboard on macOS. It's inspired by pyautogui and provides low-level access to system input events through CoreGraphics. It also includes AI-powered action generation from natural language.

## Development Commands

### Build and Test
```bash
swift build                    # Build the package
swift build -c release         # Build in release mode
swift test                     # Run all tests
swift test --parallel          # Run tests in parallel (used in CI)
swift test --filter KeyboardTests  # Run a single test suite
```

### Documentation
```bash
swift package generate-documentation
swift package --disable-sandbox preview-documentation --target SwiftAutoGUI
```

### sagui CLI Tool
```bash
swift run sagui key shortcut command c    # Keyboard shortcut
swift run sagui mouse move --x 100 --y 200  # Mouse movement
swift run sagui screen screenshot --output capture.png  # Screenshot
```

### Sample App
Located at `Sample/Sample.xcodeproj`. Open in Xcode and run (⌘+R).

## Architecture

### Two SPM Targets
- **SwiftAutoGUI** (library) — the core automation library
- **sagui** (executable) — CLI tool wrapping the library via swift-argument-parser

### Core Library (`Sources/SwiftAutoGUI/`)

**Input Control:**
- `SwiftAutoGUI.swift` — Static methods for keyboard events, mouse events (move, click, drag, scroll), screenshots, and screen queries. Uses CoreGraphics CGEvent API.
- `Keycode.swift` — `Key` enum mapping key names to CGKeyCode values and NX_KEYTYPE constants. US keyboard layout only.
- `TweeningFunction.swift` — Easing functions for smooth mouse movement animations.

**AI Action Generation:**
- `Action.swift` — Declarative `Action` enum (move, click, write, scroll, wait, etc.) with `execute()` method.
- `ActionGenerating.swift` — `ActionGenerating` protocol for backends that convert natural language → actions.
- `ActionGenerator.swift` — `BasicAction` (a `@Generable` subset of Action for on-device model) and `ActionGenerator` orchestrator.
- `FoundationModelsBackend.swift` — Default backend using Apple's on-device Foundation Models framework.
- `OpenAIBackend.swift` — Alternative backend using the MacPaw/OpenAI SDK.

**Utilities:**
- `Screenshot.swift` — Screen capture functionality.
- `ImageRecognition.swift` — Image matching using OpenCV.
- `AppleScript.swift` — AppleScript execution helpers.
- `Dialog.swift` — System dialog interactions.

### CLI (`Sources/sagui/`)
Three subcommands: `KeyCommand`, `MouseCommand`, `ScreenCommand`, each in their own file.

## Important Technical Details

- **Platform**: macOS 26.0+, Swift 6.2
- **Permissions**: Requires Accessibility permissions in System Settings
- **Event Posting**: Uses `CGEventTapLocation.cghidEventTap` for event injection
- **Coordinate System**: CGWindow coordinates (origin at top-left)
- **Thread Safety**: `Thread.sleep(0.01)` after events for timing
- **Dependencies**: opencv-spm (image recognition), MacPaw/OpenAI (AI backend), swift-argument-parser (CLI), swift-docc-plugin (docs)

## CI

GitHub Actions workflow (`build.yml`) runs on `macos-26` with four parallel jobs: build, test, docs (xcodebuild docbuild), and sample app build. PRs get automated test result comments.
