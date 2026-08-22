# ``SwiftAutoGUIBrowser``

Control an existing Chromium page through the Chrome DevTools Protocol (CDP).

## Overview

SwiftAutoGUIBrowser is an optional, browser-only automation backend. It observes
tabs and page accessibility information, assigns step-local identifiers to
actionable elements, and resolves each identifier again immediately before
execution.

It does not replace SwiftAutoGUI's native Accessibility and CGEvent automation.
An Agent configured with ``BrowserSession`` operates only inside the connected
Chromium browser and reports native-only actions as unsupported.

## Starting Chromium

Start Chrome for Testing, Chrome, Edge, or another compatible Chromium browser
with remote debugging and a dedicated profile. Chrome 136 and later require a
non-default user data directory for this workflow.

```bash
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/swift-auto-gui-browser-profile
```

Do not expose the debugging port to a network interface. A CDP connection has
powerful access to the attached browser profile.

## Connecting

```swift
import SwiftAutoGUI
import SwiftAutoGUIBrowser

let browser = try await BrowserSession.connect(
    endpoint: URL(string: "http://127.0.0.1:9222")!,
    securityPolicy: BrowserSecurityPolicy(
        allowedDomains: ["example.com", "*.example.org"]
    )
)

let tabs = try await browser.listTabs()
let observation = try await browser.observe()
print(observation.formattedContext)

if let button = observation.elements.first {
    let result = await browser.execute(
        .click(elementID: button.elementID),
        against: observation
    )
    print(result.succeeded)
}
```

Pass the session explicitly to use it as an Agent environment:

```swift
let agent = Agent(backend: llm, automationBackend: browser)
```

## Security behavior

- Debugging endpoints are limited to `127.0.0.1`, `localhost`, and `::1` by default.
- Top-level navigation and redirects are restricted to `allowedDomains`.
- A wildcard such as `*.example.com` permits subdomains, but not `example.com` itself.
- Cross-origin navigation and downloads require a ``BrowserActionAuthorizing`` implementation.
- Without an authorizer, those sensitive operations are denied.
- Arbitrary JavaScript evaluation is not exposed.
- A stale page element never falls back to a saved CGEvent coordinate.

## Topics

### Getting started

- <doc:BrowserAgent>

### Browser connection

- ``BrowserSession``
- ``BrowserSecurityPolicy``
- ``BrowserActionAuthorizing``

### Observation and actions

- ``BrowserObservation``
- ``BrowserElement``
- ``BrowserAction``
- ``BrowserActionResult``
