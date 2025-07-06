# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftAutoGUI is a Swift library for programmatically controlling the mouse and keyboard on macOS. It's inspired by pyautogui and provides low-level access to system input events through CoreGraphics.

## Development Commands

### Building the Library
```bash
# Build the Swift package
swift build

# Build in release mode
swift build -c release
```

### Running Tests
```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose
```

### Documentation
```bash
# Generate DocC documentation
swift package generate-documentation

# Preview documentation locally
swift package --disable-sandbox preview-documentation --target SwiftAutoGUI
```

### Package Management
```bash
# Update dependencies
swift package update

# Resolve package versions
swift package resolve
```

## Architecture

The library consists of two main components:

1. **SwiftAutoGUI.swift** - The main class providing static methods for:
   - Keyboard events (key press/release, shortcuts)
   - Mouse events (movement, clicks, dragging, scrolling)
   - Uses CoreGraphics CGEvent API for low-level system event generation

2. **Keycode.swift** - Defines the `Key` enum mapping:
   - Normal keys to CGKeyCode values
   - Special keys (media/function keys) to NX_KEYTYPE constants
   - Currently supports US keyboard layout only

## Important Technical Details

- **Platform**: macOS 12.0+ only
- **Permissions**: Requires accessibility permissions to control input
- **Thread Safety**: Methods include `Thread.sleep(0.01)` after events for timing
- **Coordinate System**: Uses CGWindow coordinates (origin at top-left)
- **Event Posting**: Uses `CGEventTapLocation.cghidEventTap` for event injection

## Package Distribution

- Available via Swift Package Manager and CocoaPods
- SPM: Add as dependency with branch "master"
- CocoaPods: Use pod 'SwiftAutoGUI' in Podfile