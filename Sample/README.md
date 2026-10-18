# Sample app

Open `Sample.xcodeproj` and run the Sample scheme on macOS 27 or later.
When Xcode asks to trust package macros, review and enable the TCA-related macros
before building.

The Agent demo uses The Composable Architecture (TCA), pinned in this directory's
`Package.swift`. The other demos continue to use their existing view models.
The root SwiftAutoGUI package does not depend on TCA.

## Agent demo

`Sources/AgentDemoFeature` contains the view, reducer, and live dependency:

- `AgentDemoFeature` owns input settings, progress, results, and run identity.
- `AgentClient` adapts `SwiftAutoGUI.Agent` callbacks into an ordered async stream.
  Terminating the stream cancels the underlying task. Cancellation is cooperative;
  an already executing system action cannot be undone.
- The view sends actions and binds fields to the store. Leaving the screen stops
  its run. A run uses the settings captured when Start was pressed.
- `AIProviderChoice` is shared with the Browser demo.

Run the feature tests with:

```sh
swift test --package-path Sample
```

Tests replace `AgentClient`; they do not call a model or generate mouse/keyboard
input. CI runs these tests before building the Sample app. The noninteractive
CI build uses `-skipMacroValidation` for the package macros; interactive Xcode
builds retain their normal trust prompts.
