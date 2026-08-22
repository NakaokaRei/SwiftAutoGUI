# Using a Browser Agent

Build an AI Agent that observes and controls only pages in an existing Chromium session.

## Overview

A browser Agent uses two independent backends:

1. A `VisionActionGenerating` backend decides what to do next.
2. A ``BrowserSession`` observes the current page and executes the selected action through CDP.

Passing a ``BrowserSession`` as `automationBackend` makes the Agent browser-only. It does not
switch to Accessibility or CGEvent when an action is unavailable. Element identifiers such as
`[#12]` are valid for one observation only and are verified again before execution.

## 1. Start a dedicated Chromium session

Quit any previous process using port 9222, then start Chromium with a dedicated profile:

```bash
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/swift-auto-gui-browser-profile
```

Keep the debugging endpoint on loopback. A CDP client attached to this profile can inspect and
control its pages.

## 2. Create a domain policy

`allowedDomains` contains page hosts, not the debugging endpoint:

```swift
let policy = BrowserSecurityPolicy(
    allowedDomains: ["github.com", "*.github.com"]
)
```

`github.com` permits the exact host. `*.github.com` permits subdomains but does not include the
parent host. Navigation outside the set is always rejected.

## 3. Decide how cross-origin navigation is authorized

An allowlist entry makes a destination eligible, but cross-origin navigation still requires an
authorizer. The following authorizer approves allowlisted cross-origin navigation and rejects all
downloads:

```swift
import SwiftAutoGUIBrowser

struct NavigationAuthorizer: BrowserActionAuthorizing {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool {
        switch request {
        case .crossOriginNavigation:
            true
        case .download:
            false
        }
    }
}
```

For an interactive application, ask the user before returning `true`. Omit the authorizer when
cross-origin navigation must remain disabled.

## 4. Connect and select a tab

```swift
import Foundation
import SwiftAutoGUIBrowser

let browser = try await BrowserSession.connect(
    endpoint: URL(string: "http://127.0.0.1:9222")!,
    securityPolicy: policy,
    authorizer: NavigationAuthorizer()
)

let tabs = try await browser.listTabs()
for tab in tabs {
    print(tab.id, tab.title, tab.url)
}

if let githubTab = tabs.first(where: { $0.url.contains("github.com") }) {
    try await browser.activateTab(githubTab.id)
}
```

Use `defer` in synchronous wrappers or explicitly call `await browser.close()` when the session is
no longer needed.

## 5. Run the Agent

Keep API keys outside source control. This example reads `OPENAI_API_KEY` from the process
environment:

```swift
import SwiftAutoGUI

guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
    fatalError("Set OPENAI_API_KEY before starting the app")
}

let llm = OpenAIVisionBackend(apiKey: apiKey)
let agent = Agent(
    backend: llm,
    maxIterations: 20,
    delayBetweenSteps: 1,
    screenContextOptions: nil,
    visionMode: .automatic,
    automationBackend: browser
)

let result = try await agent.run(
    goal: "Open issue 118 in the SwiftAutoGUI repository"
) { step in
    print(step.reasoning)
    for execution in step.executionResults {
        print(execution.method, execution.succeeded)
    }
}

print("Completed:", result.completed)
await browser.close()
```

The browser observation tells the model to use semantic actions such as `pressElement`,
`setElementValue`, `openURL`, `activateTab`, and scrolling. Native app, window, coordinate mouse,
and drag actions return `unsupportedAction`.

## Use the Sample app

Open `Sample/Sample.xcodeproj`, run the Sample scheme, and select **Browser CDP**:

1. Enter the loopback endpoint and page domains.
2. Select **Connect** and choose a tab.
3. Enter an API key or launch the app with `OPENAI_API_KEY`.
4. Enter a goal and select **Run Agent**.
5. Inspect each reasoning, action, and CDP execution result in **Agent steps**.

The Sample approves cross-origin navigation within its explicit domain list and denies downloads.

## Use sagui

List available tabs:

```bash
sagui browser tabs --endpoint http://127.0.0.1:9222
```

Run a browser-only Agent:

```bash
export OPENAI_API_KEY="your-key-in-your-shell"

sagui browser agent "Open issue 118" \
  --domain github.com \
  --allow-cross-origin \
  --vision-mode automatic
```

Use repeated `--domain` options for multiple hosts. Use `--tab-id` with an ID printed by
`sagui browser tabs` to choose the initial tab. Without `--allow-cross-origin`, cross-origin
navigation is denied even when its destination is allowlisted. Downloads are always denied.

## Understand failures

- `navigationNotAllowed`: The destination host is not in `allowedDomains`.
- `authorizationDenied`: Cross-origin navigation was not approved by the authorizer.
- `staleElement`: The target, frame, loader, DOM node, or semantic element changed; observe again.
- `unsupportedAction`: The model requested a native-only action in a browser-only session.
- `disconnected`: Chromium exited or the debugging connection closed.

An action failure or page change stops the remaining action batch. The Agent then observes the
new page before deciding what to do next.
