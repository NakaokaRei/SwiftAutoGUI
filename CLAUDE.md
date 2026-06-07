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
scripts/build-metallib.sh       # Rebuild the bundled Metal shader library
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

- `Core/` — Main `SwiftAutoGUI` namespace and low-level mouse/keyboard operations.
- `Input/` — Key codes, keyboard layouts, and tweening functions.
- `Accessibility/` — Accessibility element lookup, attributes, actions, and matching types.
- `Actions/` — Declarative actions and agent orchestration.
- `AI/` — Action-generation protocols, model backends, and screen context.
- `Screen/` — Screen capture and image-recognition integration.
- `System/` — AppleScript and system-dialog helpers.
- `Documentation.docc/` — DocC catalog for the library.

The separate `ImageRecognition` target provides GPU template matching using
normalized cross-correlation.

### CLI (`Sources/sagui/`)
Three subcommands: `KeyCommand`, `MouseCommand`, `ScreenCommand`, each in their own file.

## Important Technical Details

- **Platform**: macOS 26.0+, Swift 6.2
- **Permissions**: Requires Accessibility permissions in System Settings
- **Event Posting**: Uses `CGEventTapLocation.cghidEventTap` for event injection
- **Coordinate System**: CGWindow coordinates (origin at top-left)
- **Thread Safety**: `Thread.sleep(0.01)` after events for timing
- **Dependencies**: swift-argument-parser (CLI), swift-docc-plugin (docs)

## CI

GitHub Actions workflow (`build.yml`) runs on `macos-26` with four parallel jobs: build, test, docs (xcodebuild docbuild), and sample app build. PRs get automated test result comments.

## Releases

When tagging a new SwiftAutoGUI version (e.g. `0.22.0`):

1. Bump `plugins/swift-auto-gui/.claude-plugin/plugin.json` `version` to match the new git tag.
2. Then create the git tag.

The Claude Code plugin version is intentionally kept in sync with the library tag — if `plugin.json` `version` doesn't change between releases, existing marketplace users won't receive plugin updates (Claude Code caches by version string).
