# Migrating to macOS 27 language models

Use one Foundation Models session API for on-device Apple Intelligence, Private
Cloud Compute, and an explicitly configured Chat Completions model.

## Requirements and dependency

This breaking release requires **macOS 27**, an Xcode 27 SDK, and Swift tools 6.2.
The previous release line supports macOS 26. Apple Intelligence must be available
and enabled to use Apple's models; merely installing macOS 27 is not sufficient.
The package pins `apple/foundation-models-utilities` to **1.0.0-beta5**. It has no
stable 1.0.0 tag at the time of this migration. Validate upgrades before changing
this pin; the framework and utility have changed between betas.

## Replace model backends

Before:

```swift
let backend = OpenAIVisionBackend(apiKey: key)
let agent = Agent(backend: backend)
let generator = ActionGenerator(backend: FoundationModelsBackend())
```

After:

```swift
import FoundationModels
import SwiftAutoGUI

let agent = Agent(model: AutomationModels.openAI(apiKey: key))
let generator = ActionGenerator(model: SystemLanguageModel.default)
let actions = try await generator.generateActionSequence(from: "Type hello")
```

`ActionGenerating`, `VisionActionGenerating`, and the three legacy model backends
have been removed. Implement custom providers using Apple's `LanguageModel` and
`LanguageModelExecutor`. `AgentDecision` replaces `AgentResponse`, with
`reasoningSummary` holding only a short user-facing explanation. `BasicAction`
already conformed to `Generable`; its schema is now used for every provider.
`AgentStep.reasoning` remains the callback's short explanation, not hidden reasoning.
`BasicAction.keyShortcut(keys:)` now takes `[Key]`, for example
`.keyShortcut(keys: [.command, .space])`. `Key` is `Generable`, so every provider
receives the canonical key names as enum choices, not unrestricted strings.
The Codable wire representation remains an array of canonical strings; unknown
names now fail decoding rather than being silently dropped. Native Agent execution
rejects empty shortcuts and missing Accessibility permission. A successful input
posting result does not prove that the target application handled the shortcut.

`BasicAction.toAction()` now throws: use `try`. Invalid URLs, app names, numeric
parameters, and observation-dependent actions no longer turn into `wait(0)`.
Standalone generation rejects element/tab actions because it has no observation
or browser session. Tagged Codable decoding requires the parameters of the selected
action instead of replacing missing values with zero or empty strings.
Native Agent execution preserves Boolean failures from app and Accessibility actions.
Browser shortcut dispatch supports canonical digit/function/navigation/punctuation
keys and rejects unsupported keys before sending events.

Static `ActionGenerator` helpers remain and use `defaultModel` instead of
`defaultBackend`. Independent action requests always start fresh sessions.

`AgentAutomationBackend` is a different responsibility: observing and executing
native or browser actions. Keep it. Browser navigation policy, element identity,
stale-element checks, and screenshot-optional observations remain in place.

## Session lifecycle, limits, and recovery

Each `Agent.run` owns one session. It sends only the latest observation and actual
execution results; Foundation Models retains the conversation. A new run does not
reuse another run's conversation. Generated actions execute sequentially, with a
cancellation check before each action. A UI change or execution failure stops the
remaining batch. Completion requires a decision with no actions, so a proposed
final action cannot mark a failed or skipped batch as successful.

`AgentHistoryPolicy` keeps up to four completed turns and 12,000 characters by
default. Old images and reasoning entries are removed. These are retention limits,
not an exact universal tokenizer. On-device requests additionally use
`SystemLanguageModel.contextSize` and `tokenCount(for:)`, including instructions,
schema and a response budget when the token-count service supports the input.
The Xcode 27.2 model service can reject token counting for an image that generation
accepts. If counting is unavailable, discard old conversation turns and let the
model enforce its context limit; cancellation still propagates. Old turns are
dropped before the current observation.
The current goal and latest actual results are retained. If a native observation
with a screenshot still exceeds the context limit, retry once without its semantic
screen tree, retaining the image and viewport. Element-ID actions are rejected in
that retry because their IDs were not shown to the model. Browser and text-only
observations are not reduced this way. If the reduced request cannot fit, it fails.
No element IDs or JSON values are partially truncated.

An unfinished decision with no actions triggers one generation using a single-action
schema and fresh history. It does not execute or record an empty step repeatedly.
A completed decision with no actions still ends the run normally.

A context-size error permits one retry with fresh history. Compaction discards
older details; this is not an unlimited memory or a guarantee of task completion.
The application can retain `AgentResult.steps` for audit/UI without resending all
of them as a prompt. Cache reuse and token reporting depend on the provider.

## Explicit fallback and privacy

```swift
let agent = Agent(
    model: PrivateCloudComputeLanguageModel(),
    fallbackModel: SystemLanguageModel.default,
    visionMode: .automatic
)
```

Fallback is optional and used for model unavailability, missing required
capabilities, and PCC quota/network/service errors. Only generation is retried;
execution is outside that retry loop. A fallback starts with fresh history and
receives the current goal, observation and latest execution results, so a large
PCC transcript is not blindly replayed into an on-device session. The fallback
must pass the same availability, vision (when an image is attached), and guided
generation checks. Cancellation, refusal, and malformed output do not trigger
fallback. If the fallback also fails, return the error.

Passing any cloud model, including as `fallbackModel`, opts into sending the goal,
observations (screenshots and/or semantic content), and execution results to that
provider. There is no automatic transition from on-device to a cloud service.
Do not embed API keys in app binaries or log them. The CLI reads `OPENAI_API_KEY`;
consumer apps own their credential storage and authentication design.

## Private Cloud Compute setup

The consuming application must obtain Apple's managed
`com.apple.developer.private-cloud-compute` entitlement and use an eligible signing
and provisioning configuration. The library cannot grant access. Do not add the
entitlement to the unsigned sample and assume it works.

Apple's documented distribution paths are App Store apps and TestFlight/ad hoc
for testing. Standalone CLI/GitHub/package-manager distribution is not assumed to
qualify. Eligibility includes the Small Business Program and first-time download
limits; check [Apple's current requirements](https://developer.apple.com/private-cloud-compute/).

The sample offers PCC as an explicit selection and surfaces unavailability/errors.
Before running it with PCC, configure your eligible team and entitlement. For a
product UI, inspect `availability` and `quotaUsage` on your PCC model to show quota,
reset time and available upgrade suggestions. Test near/exceeded quota using
Xcode's simulated Foundation Models availability options.

## Chat Completions compatibility

`AutomationModels.openAI` returns `OpenAIChatLanguageModel`, a small
`LanguageModel` executor wrapper around Apple's `ChatCompletionsLanguageModel`. It
converts untyped string `const` discriminators produced by Swift's enum schema to
typed singleton `enum` values. This is a generic schema compatibility transform,
not a second hand-maintained action schema. Direct use of the beta5 adapter fails
OpenAI strict validation for the associated-value `BasicAction` enum.

This
changes the wire protocol from **Responses** to **Chat Completions**. It uses SSE,
Foundation Models image attachments, and the shared generated JSON schema. There
are no provider-specific action schemas or response parsers in SwiftAutoGUI.
Single actions and action arrays use an object envelope to satisfy
[OpenAI's structured-output root schema requirement](https://developers.openai.com/api/docs/guides/structured-outputs).

Supply a base URL: `/v1/chat/completions` is appended unless a `v<digits>` path
segment exists, in which case `/chat/completions` is appended. The adapter accepts
`urlSessionConfiguration` for transport configuration/testing. Apple's adapter advertises vision, tools and reasoning unconditionally. Our
wrapper omits reasoning (the transport cannot configure it) and accepts explicit
`capabilities` when initialized directly. Declarations do not discover remote
support or prove that the selected model implements it. Choose and integration-test a model that
supports the requested image inputs and JSON Schema output. Unsupported endpoint
responses propagate as errors.

The pinned Apple adapter does **not** forward `ContextOptions.reasoningLevel`. The former OpenAI `reasoningEffort` and CLI
`--reasoning-effort` options are removed. PCC callers may use `contextOptions` with
`.light`, `.moderate`, or `.deep`. Unsupported reasoning configuration is rejected on the primary model. On-device fallback omits unsupported reasoning.

## CLI migration

```bash
# Default: on-device, no API key required
sagui agent "Press Save" --vision-mode automatic

# Explicit remote provider, OPENAI_API_KEY read from the environment
sagui agent "Open Safari" --provider openai --model gpt-5.6-sol
sagui browser agent "Open Issues" --domain github.com --provider openai

# Only in an eligible, entitled host
sagui agent "Inspect the screen" --provider pcc --fallback-on-device
```

The same provider selection is available in the sample's action, native Agent,
and browser Agent screens. Selecting OpenAI shows the key/model controls.

## Validation boundaries

Deterministic tests use real `LanguageModelSession` instances with mock
`LanguageModelExecutor`s, fake automation backends, and no real input events.
They cover shared schemas, history, bounded context retries, explicit fallback,
cancellation, browser semantic observations, and execution boundaries.

Live task quality, additional endpoint/model combinations, entitlement-dependent
PCC execution, latency and task completion require opt-in integration tests
on the target hardware and account. Compare with the Foundation Models Instruments
and Evaluations framework before making performance or accuracy claims.

Run generation-only smoke tests explicitly (no actions are executed):

```bash
SWIFTAUTOGUI_RUN_MODEL_TESTS=on-device swift test --filter LiveModelSmokeTests.onDevice
SWIFTAUTOGUI_RUN_MODEL_TESTS=openai swift test --filter LiveModelSmokeTests.openAI
```

The OpenAI test requires `OPENAI_API_KEY` and uses `defaultTextModel`, overridable
with `SWIFTAUTOGUI_TEST_MODEL`. These opt-in tests make billable text/image requests using synthetic input; they
do not capture or transmit the user's screen. `openAIVision` uses the default
Agent model and a generated white tile; `onDeviceVision` exercises the same path
locally.
