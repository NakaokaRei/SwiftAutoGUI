---
name: swift-auto-gui
description: >
  Control macOS GUI applications via mouse automation, keyboard input, screenshots,
  image recognition, and AppleScript execution. Use when you need to interact with
  macOS app UIs, take screenshots, click buttons, type text, scroll, drag, or locate
  images on screen.
---

# swift-auto-gui

The `sagui` CLI provides mouse control, keyboard input, screenshot capture, image recognition, and screen queries for macOS automation.

## Prerequisites

- **Accessibility**: Required for mouse and keyboard commands. Enable in System Settings > Privacy & Security > Accessibility.
- **Screen Recording**: Required for screenshot and image recognition commands. Enable in System Settings > Privacy & Security > Screen Recording.

## Coordinates

All coordinates use **CGWindow coordinate system** — logical points with origin at the **top-left of the primary display**.

- x increases to the right
- y increases downward
- Values are in logical points (not pixels)

Use `sagui screen size` to get screen dimensions.

## Commands

### key — Simulate keyboard input

```bash
sagui key shortcut command c             # Keyboard shortcut (Cmd+C)
sagui key shortcut command shift a       # Multi-modifier shortcut
sagui key down shift                     # Press key without releasing
sagui key up shift                       # Release a held key
sagui key type "Hello, World!"           # Type text character by character
sagui key type "slow" --interval 0.1     # Type with delay between keystrokes
```

| Subcommand | Arguments | Optional |
|---|---|---|
| `shortcut` | `<keys...>` (key names) | |
| `down` | `<key>` | |
| `up` | `<key>` | |
| `type` | `<text>` | `--interval <seconds>` (default: 0) |

#### Supported key names

**Modifiers**: `command`, `shift`, `rightShift`, `control`, `rightControl`, `option`, `rightOption`, `capsLock`, `function`

**Letters**: `a`-`z`

**Numbers**: `zero`-`nine`

**Function keys**: `f1`-`f20`

**Arrow keys**: `upArrow`, `downArrow`, `leftArrow`, `rightArrow`

**Navigation**: `home`, `end`, `pageUp`, `pageDown`, `help`

**Special**: `returnKey`, `enter`, `tab`, `space`, `escape`, `delete`, `forwardDelete`

**Keypad**: `keypad0`-`keypad9`, `keypadDecimal`, `keypadMultiply`, `keypadPlus`, `keypadMinus`, `keypadDivide`, `keypadEnter`, `keypadClear`, `keypadEquals`

**Media**: `volumeUp`, `volumeDown`, `mute`, `brightnessUp`, `brightnessDown`

**JIS**: `jisYen`, `jisUnderscore`, `jisEisu`, `jisKana`

### mouse — Control mouse cursor

Coordinates are **screen points** (origin top-left).

```bash
sagui mouse position                                                  # Print current position
sagui mouse move --x 500 --y 300                                      # Move to absolute position
sagui mouse move-relative --dx 50 --dy -30                            # Move relative to current
sagui mouse click                                                     # Left click at current position
sagui mouse click --right                                             # Right click
sagui mouse click --double                                            # Double-click
sagui mouse click --triple                                            # Triple-click
sagui mouse drag --from-x 100 --from-y 100 --to-x 400 --to-y 400    # Drag
sagui mouse scroll --vertical 5                                       # Scroll up
sagui mouse scroll --vertical -3                                      # Scroll down
sagui mouse scroll --horizontal 2                                     # Scroll left
```

| Subcommand | Required | Optional |
|---|---|---|
| `position` | | |
| `move` | `--x`, `--y` | |
| `move-relative` | `--dx`, `--dy` | |
| `click` | | `--right`, `--double`, `--triple` |
| `drag` | `--from-x`, `--from-y`, `--to-x`, `--to-y` | |
| `scroll` | | `--vertical <clicks>`, `--horizontal <clicks>` |

### screen — Screenshots and screen queries

```bash
sagui screen size                                          # Print screen dimensions
sagui screen screenshot                                    # Save screenshot to screenshot.png
sagui screen screenshot --output capture.png               # Save to specific path
sagui screen screenshot --region 0,0,500,500               # Capture specific region
sagui screen pixel --x 100 --y 200                         # Get pixel color (R G B A)
sagui screen locate button.png                             # Find image on screen (X Y W H)
sagui screen locate button.png --confidence 0.8            # Find with lower threshold
sagui screen locate-center button.png                      # Find image center (X Y)
```

| Subcommand | Required | Optional |
|---|---|---|
| `size` | | |
| `screenshot` | | `--output <path>` (default: `screenshot.png`), `--region <x,y,w,h>` |
| `pixel` | `--x`, `--y` | |
| `locate` | `<image-path>` | `--confidence <0.0-1.0>` |
| `locate-center` | `<image-path>` | `--confidence <0.0-1.0>` |

**Image recognition** uses OpenCV template matching. Default confidence threshold is 0.95. Lower it for fuzzy matching.

### agent — AI-powered automation

```bash
sagui agent "Open Safari and search for Swift"                    # Run with on-device model
sagui agent "Click the submit button" --api-key sk-...            # Run with OpenAI
sagui agent "Fill in the form" --model gpt-5.4 --max-iterations 10
```

| Required | Optional |
|---|---|
| `<goal>` (string) | `--api-key <key>` (or `OPENAI_API_KEY` env), `--model <model>` (default: `gpt-5.4`), `--max-iterations <n>` (default: 20), `--delay <seconds>` (default: 1.0), `--no-screen-context` |

## Workflow

### Screenshot + mouse/keyboard interaction

1. `sagui screen size` — get screen dimensions.
2. `sagui screen screenshot --output /tmp/screen.png` — capture current state.
3. Read the screenshot image to identify target coordinates.
4. `sagui mouse move --x <x> --y <y>` and `sagui mouse click` — interact.
5. `sagui key type "text"` or `sagui key shortcut command a` — keyboard input.
6. `sagui screen screenshot --output /tmp/verify.png` — verify result.

### Image-based interaction

1. `sagui screen locate-center target.png` — find element position.
2. `sagui mouse move --x <x> --y <y>` — move to found coordinates.
3. `sagui mouse click` — click the element.

## Notes

- All mouse and keyboard commands require Accessibility permissions.
- Screenshot and image recognition commands require Screen Recording permissions.
- `key type` supports any Unicode character. Use `key shortcut` with modifier keys for keyboard shortcuts.
- Scroll: positive vertical = up, negative = down; positive horizontal = left, negative = right.
- Image recognition confidence defaults to 0.95; lower for fuzzy matching (e.g., 0.8).
- Supported screenshot formats: PNG, JPG/JPEG, GIF, BMP, TIFF (detected from file extension).
