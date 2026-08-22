//
//  Agent.swift
//  SwiftAutoGUI
//

import AppKit
import Foundation

// MARK: - Agent

/// An autonomous agent that observes the screen and executes actions to achieve a goal.
///
/// The agent runs a loop: take a screenshot, send it to a vision-capable LLM backend,
/// execute the returned actions, and repeat until the goal is achieved or the iteration
/// limit is reached.
///
/// ## Example
///
/// ```swift
/// let backend = OpenAIVisionBackend(apiKey: "sk-...")
/// let agent = Agent(backend: backend, maxIterations: 15)
/// let result = try await agent.run(goal: "Open Safari and search for Swift")
/// print("Completed: \(result.completed), Steps: \(result.iterationsUsed)")
/// ```
///
/// ## Requirements
///
/// - macOS 26.0 or later
/// - Accessibility permissions for mouse/keyboard control
/// - A vision-capable backend (e.g., ``OpenAIVisionBackend``)
public struct Agent: Sendable {

    /// The vision backend used for action generation.
    public let backend: any VisionActionGenerating

    /// Maximum number of observe-think-act iterations.
    public let maxIterations: Int

    /// Delay between steps to allow the screen to update.
    public let delayBetweenSteps: TimeInterval

    /// Options for gathering screen context (accessibility tree, window info).
    /// Set to `nil` to disable screen context gathering entirely.
    public let screenContextOptions: ScreenContextProvider.Options?

    /// Controls whether screenshots accompany structured screen context.
    public let visionMode: AgentVisionMode

    /// The environment used to observe and execute actions.
    public let automationBackend: any AgentAutomationBackend

    /// Creates an agent with the specified configuration.
    ///
    /// - Parameters:
    ///   - backend: The vision backend to use for action generation.
    ///   - maxIterations: Maximum loop iterations (default: 20).
    ///   - delayBetweenSteps: Seconds to wait between steps (default: 1.0).
    ///   - screenContextOptions: Options for screen context gathering (default: enabled with defaults).
    ///     Pass `nil` to disable.
    ///   - visionMode: Controls when screenshots are included (default: ``AgentVisionMode/always``).
    ///   - automationBackend: Optional observation/execution environment. `nil` preserves
    ///     the native Accessibility and CGEvent backend.
    public init(
        backend: any VisionActionGenerating,
        maxIterations: Int = 20,
        delayBetweenSteps: TimeInterval = 1.0,
        screenContextOptions: ScreenContextProvider.Options? = ScreenContextProvider.Options(),
        visionMode: AgentVisionMode = .always,
        automationBackend: (any AgentAutomationBackend)? = nil
    ) {
        self.backend = backend
        self.maxIterations = maxIterations
        self.delayBetweenSteps = delayBetweenSteps
        self.screenContextOptions = screenContextOptions
        self.visionMode = visionMode
        self.automationBackend = automationBackend
            ?? NativeAutomationBackend(screenContextOptions: screenContextOptions)
    }

    /// Runs the agent loop to achieve the given goal.
    ///
    /// - Parameters:
    ///   - goal: A natural language description of the goal.
    ///   - onStep: Optional callback invoked after each step completes.
    /// - Returns: An ``AgentResult`` describing the run outcome.
    @MainActor
    public func run(
        goal: String,
        onStep: (@Sendable (AgentStep) -> Void)? = nil
    ) async throws -> AgentResult {
        guard backend.isAvailable else {
            throw ActionGeneratorError.backendUnavailable(
                reason: backend.unavailableReason ?? "Backend is unavailable."
            )
        }

        var steps: [AgentStep] = []
        var completed = false

        for _ in 0..<maxIterations {
            try Task.checkCancellation()

            // 1. Observe through the selected automation environment.
            let observation = try await automationBackend.observe(visionMode: visionMode)

            // 2. Think: send to backend
            let response = try await backend.generateActions(
                goal: goal,
                screenshot: observation.screenshotJPEGData,
                screenSize: observation.viewportSize,
                history: steps,
                observation: observation
            )

            // 3. Act: execute against the observation used by the model. Stop
            // as soon as the UI changes or an action fails, then re-observe.
            var currentObservation = observation
            var executedActions: [BasicAction] = []
            var executionResults: [ActionExecutionResult] = []
            for action in response.actions {
                let execution = await automationBackend.execute(
                    action,
                    in: currentObservation
                )
                executedActions.append(action)
                executionResults.append(execution.result)
                currentObservation = execution.observation

                if !execution.result.succeeded || execution.result.screenChanged {
                    break
                }
            }

            // 4. Record step
            let step = AgentStep(
                actions: executedActions,
                reasoning: response.reasoning,
                executionResults: executionResults
            )
            steps.append(step)
            onStep?(step)

            // 5. Check completion
            if response.isDone {
                completed = true
                break
            }

            // 6. Wait before next iteration
            if delayBetweenSteps > 0 {
                try await Task.sleep(for: .seconds(delayBetweenSteps))
            }
        }

        return AgentResult(
            steps: steps,
            completed: completed,
            iterationsUsed: steps.count
        )
    }
}
