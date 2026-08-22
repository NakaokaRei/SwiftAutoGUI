# SwiftAutoGUI Browser Agent

Browser Agent controls web pages in a Chromium browser with remote debugging enabled. It uses the
Chrome DevTools Protocol (CDP) and is intentionally browser-only: it does not control native macOS
interfaces such as Finder or System Settings, and it never falls back to Accessibility or CGEvent.

## 1. Start Chromium

Use a dedicated profile and expose the debugging port only on the loopback interface:

```bash
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/swift-auto-gui-browser-profile
```

To use the standard Google Chrome installation instead, replace the executable path with:

```text
/Applications/Google Chrome.app/Contents/MacOS/Google Chrome
```

## 2. Try it in the Sample app

1. Open `Sample/Sample.xcodeproj` in Xcode.
2. Run the **Sample** scheme.
3. Open the **Browser CDP** tab.
4. Enter `http://127.0.0.1:9222` as the endpoint.
5. Enter the page hosts that the Agent may access under **Domains**, such as `github.com`.
6. Select **Connect**, then choose the target browser tab.
7. Enter an OpenAI API key and a goal.
8. Select **Run Agent**.

The Sample app permits cross-origin navigation only when the destination is in the domain allowlist.
It rejects navigation outside the allowlist and rejects all downloads. The API key is read from the
text field or the `OPENAI_API_KEY` environment variable and is never stored in source code.

## 3. Try it with sagui

Direct commands do not use the OpenAI API. List tabs, observe a semantic element map, and perform
known actions with an explicit tab target:

```bash
sagui browser tabs
sagui browser observe --tab-id TARGET_ID

sagui browser click \
  --tab-id TARGET_ID \
  --role link \
  --name "Issues" \
  --domain github.com

sagui browser set-value "SwiftAutoGUI" \
  --tab-id TARGET_ID \
  --role searchbox \
  --name "Search"
```

Other direct commands include `activate-tab`, `open`, `type`, `key`, and `scroll`. Element actions
always require the exact semantic role and accessible name from a fresh observation. Add
`--element-id` only to disambiguate duplicate role/name pairs.

To run the AI Agent:

```bash
export OPENAI_API_KEY="your-key-in-your-shell"

sagui browser agent "Open issue 118" \
  --domain github.com \
  --allow-cross-origin
```

To start from a specific tab:

```bash
sagui browser agent "Open the Issues page" \
  --domain github.com \
  --tab-id TARGET_ID
```

- Repeat `--domain` to allow multiple hosts.
- Without `--allow-cross-origin`, cross-origin navigation is rejected even when its destination is
  in the allowlist.
- Downloads are always rejected.
- The default endpoint is `http://127.0.0.1:9222`.

## 4. Use the Swift API

```swift
import Foundation
import SwiftAutoGUI
import SwiftAutoGUIBrowser

struct Authorizer: BrowserActionAuthorizing {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool {
        switch request {
        case .crossOriginNavigation: true
        case .download: false
        }
    }
}

let browser = try await BrowserSession.connect(
    endpoint: URL(string: "http://127.0.0.1:9222")!,
    securityPolicy: BrowserSecurityPolicy(
        allowedDomains: ["github.com"]
    ),
    authorizer: Authorizer()
)

let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
let llm = OpenAIVisionBackend(apiKey: apiKey)
let agent = Agent(
    backend: llm,
    screenContextOptions: nil,
    visionMode: .automatic,
    automationBackend: browser
)

let result = try await agent.run(goal: "Open issue 118")
print(result.completed)
await browser.close()
```

For API details, security behavior, element lifetime, and error handling, see the
**Using a Browser Agent** page in the `SwiftAutoGUIBrowser` DocC documentation.
