---
name: agent-smoke-test
description: Run manual development checks for SwiftAutoGUI AI Agent actions through the local sagui CLI. Use when Claude or Codex needs to test app-control or Accessibility BasicAction generation on macOS.
---

# SwiftAutoGUI Agent Smoke Test

Run examples from the repository root. Always source `~/.zshrc` so the latest
`OPENAI_API_KEY` is available.

Build once:

```bash
swift build --product sagui
```

Search for Swift in Safari:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Search for Swift in Safari." \
  --max-iterations 10 --delay 1
```

Get the frontmost application:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Use exactly one getFrontmostApp action, then mark the goal done." \
  --max-iterations 1 --delay 0
```

Activate Calculator:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Use exactly one activateApp action with app name Calculator, then mark the goal done." \
  --max-iterations 1 --delay 0
```

Press Calculator button 7 with Accessibility:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Calculator is open. Use exactly one pressButton action with label 7 and bundleID com.apple.calculator. Do not use mouse or keyboard actions." \
  --max-iterations 1 --delay 0
```

Set the first TextEdit text field:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "TextEdit has a Save sheet open. Use exactly one setTextField action with an empty label, value SWIFTAUTOGUI_AGENT_TEST, and bundleID com.apple.TextEdit." \
  --max-iterations 1 --delay 0
```

Select a TextEdit menu item:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "TextEdit has a rich-text document open. Use exactly one selectMenuItem action with path [Format, Make Plain Text] and bundleID com.apple.TextEdit." \
  --max-iterations 1 --delay 0
```

Raise a Calculator window:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Use exactly one raiseWindow action with title Calculator and bundleID com.apple.calculator." \
  --max-iterations 1 --delay 0
```

Open a URL:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Use exactly one openURL action with URL https://example.com." \
  --max-iterations 1 --delay 0
```

Quit Calculator:

```bash
source ~/.zshrc && .build/debug/sagui agent \
  "Use exactly one quitApp action with app name Calculator." \
  --max-iterations 1 --delay 0
```

Check the `Actions:` line in each command output to confirm which
`BasicAction` the Agent generated.
