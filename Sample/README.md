# Sample app

Open `Sample.xcodeproj` and run the Sample scheme on macOS 27 or later.
When Xcode asks to trust package macros, review and enable the TCA-related macros
before building. CI uses `-skipMacroValidation` for its noninteractive build;
interactive Xcode builds retain their normal trust prompts.

## Structure

Every demo screen is a separate TCA feature module in the Sample-only Swift
package. The root SwiftAutoGUI library has no TCA dependency.

```text
Sample/
  Sample/                         App entry point, tab selection, common UI, assets
  Sources/
    AgentDemoFeature/
    BrowserDemoFeature/
    AIGenerationDemoFeature/
    ActionsDemoFeature/
    AppleScriptFeature/
    DialogDemoFeature/
    ImageRecognitionFeature/
    InputObserverFeature/
    KeyboardDemoFeature/
    KeyboardLayoutFeature/
    MouseControlFeature/
    PixelDetectionFeature/
    ScreenContextFeature/
    ScreenshotFeature/
    ScrollingDemoFeature/
    TextTypingFeature/
    SampleSupport/                Shared provider, automation/file clients, descriptions
  Tests/
    AgentDemoFeatureTests/
    SampleFeatureTests/
```

Each feature owns its view, State, Action, and Reducer. Views send actions and
bind controls to their store. View-local presentation state such as focus and
expanded sections stays in SwiftUI. `ContentView` composes the public feature
views and owns tab selection; there is no application-wide root store.

## Effects and lifetimes

- `AutomationClient` wraps the library's GUI actions. AppKit values are converted
  to image data and color components before entering reducer state.
- `SampleFiles` handles screenshot export and test-image rendering.
- `AgentClient` and `BrowserClient` bridge agent callbacks into ordered streams.
  Terminating a stream cancels its producer task. Run IDs reject stale results.
- `BrowserClient` owns sessions outside reducer state. Disconnecting or leaving
  the screen cancels work and closes the connection. Its domain allowlist and
  download-denial policy apply to both manual actions and agent execution.
- `GenerationClient` keeps executable generated actions on MainActor because the
  library's Action type may contain non-Sendable easing closures. State exposes
  immutable action descriptions; execution uses the captured plan.
- `InputMonitorClient` removes its AppKit monitor when observation ends and
  restores each window's mouse-movement setting.
- `ScreenContextFeature` owns the auto-refresh effect and uses an injectable
  clock. Leaving a screen cancels its effects and clears busy flags.

Long-running operations capture their input settings at start. Cancellation is
cooperative and cannot undo a system action already in progress.

## Tests

```sh
swift test --package-path Sample
```

Tests replace clients and clocks. They do not call a model, connect to a browser,
open dialogs, save files, or generate real mouse/keyboard input. CI runs both
feature test targets before building the Sample app.
