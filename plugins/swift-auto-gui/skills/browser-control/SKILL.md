---
name: browser-control
description: Control web pages in an existing Chromium remote-debugging session with the sagui browser-only AI Agent. Use when Claude Code needs to list Chromium tabs or complete a browser task through CDP without controlling native macOS UI, Accessibility, or CGEvent input.
---

# browser-control

Use `sagui browser` to inspect and automate Chromium pages through the Chrome DevTools Protocol
(CDP). Treat this as a browser-only environment: it never falls back to native macOS automation.

## Preflight

Run these checks before browser automation:

```bash
uname -s
command -v sagui
sagui browser --help
```

Stop if the platform is not macOS. If `sagui` is missing, or the installed version has no
`browser` command, ask before installing or upgrading it:

```bash
brew update
brew install NakaokaRei/tap/sagui
# Use this instead when sagui is already installed:
brew upgrade NakaokaRei/tap/sagui
```

Do not claim that Accessibility or Screen Recording permission is required for browser-only CDP
actions. Those permissions apply to native `sagui` commands, not `sagui browser`.

## Connect to Chromium

List tabs on the default loopback endpoint:

```bash
sagui browser tabs
```

If no debugging endpoint is available, ask the user to start a dedicated Chromium profile, or
obtain approval before launching it:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/swift-auto-gui-browser-profile
```

Keep the endpoint on loopback. Do not expose or connect CDP to a LAN or public address. The browser
session does not launch Chromium, manage profiles, bypass login, solve CAPTCHA, or handle 2FA.

Use the target ID printed by `sagui browser tabs` when a specific tab matters. Re-list tabs after a
tab closes, opens, or navigates unexpectedly because target IDs and page observations may become
stale.

## Choose the domain allowlist

Build the narrowest allowlist that satisfies the user's stated goal:

- `github.com` permits exactly `github.com`.
- `'*.github.com'` permits subdomains but not the parent domain; quote wildcards in the shell.
- Repeat `--domain` for multiple hosts.
- Never use a global wildcard, a public suffix such as `com`, or unrelated domains.
- Ask before adding a domain that is not clearly implied by the goal.

An allowlist entry only makes a destination eligible. Cross-origin navigation is still denied
unless `--allow-cross-origin` is present. Use that flag only when the goal requires navigation from
another origin, such as from `chrome://newtab/` to an allowed website. It never permits navigation
outside the allowlist. Downloads remain denied.

## Handle the OpenAI API key

The Agent uses the OpenAI API. Prefer `OPENAI_API_KEY`; never print the value, request it in chat, or
put it in a command with `--api-key`, where it may enter shell history or process listings.

Check only whether the variable exists:

```bash
if [ -n "${OPENAI_API_KEY:-}" ]; then
  echo "OPENAI_API_KEY is configured"
else
  echo "OPENAI_API_KEY is not configured"
fi
```

If it is absent, ask the user to configure it securely in their shell and stop until they confirm.

## Run a browser-only Agent

First list tabs, then run a narrowly scoped goal:

```bash
sagui browser tabs

sagui browser agent \
  "Open issue 118 in the NakaokaRei/SwiftAutoGUI repository" \
  --domain github.com \
  --domain '*.github.com' \
  --allow-cross-origin \
  --tab-id TARGET_ID
```

Omit `--tab-id` when the current active page is the intended starting point. Useful optional
controls include:

```bash
--endpoint http://127.0.0.1:9222
--model gpt-5.6-sol
--reasoning-effort low
--max-iterations 20
--delay 1.0
--vision-mode automatic
```

Use `automatic` as the normal vision mode. The Agent primarily observes semantic DOM and
Accessibility data and re-observes after navigation, DOM changes, stale elements, or action
failures.

Before goals that submit forms, publish content, purchase items, change permissions, delete data,
or otherwise have meaningful external effects, confirm the final consequential action with the
user unless their request already authorized it explicitly.

## Interpret results

- `unsupportedAction`: The model requested a native-only action. Do not retry it through mouse or
  keyboard fallback.
- `staleElement`: The DOM node, frame, loader, or tab changed. List tabs or run a fresh Agent step;
  never click an old coordinate.
- `navigationNotAllowed`: Add the exact destination host only if it belongs to the user's goal.
- `authorizationDenied`: Cross-origin navigation needs explicit `--allow-cross-origin` approval.
- `disconnected`: Chromium exited or its debugging endpoint closed.

Treat `Completed: true` as the Agent's completion report, then verify any important result from its
printed actions or by listing/observing the relevant tab again.

## Native macOS boundary

This Skill controls page content only. It cannot operate Chromium window chrome, permission
dialogs, file pickers implemented as native macOS UI, Finder, System Settings, or other apps. For
those tasks, use the separate `macos-control` Skill in a distinct phase. Do not represent the two
backends as one Agent run and do not silently fall back from CDP to Accessibility or CGEvent.
