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

    /// Creates an agent with the specified configuration.
    ///
    /// - Parameters:
    ///   - backend: The vision backend to use for action generation.
    ///   - maxIterations: Maximum loop iterations (default: 20).
    ///   - delayBetweenSteps: Seconds to wait between steps (default: 1.0).
    ///   - screenContextOptions: Options for screen context gathering (default: enabled with defaults).
    ///     Pass `nil` to disable.
    ///   - visionMode: Controls when screenshots are included (default: ``AgentVisionMode/always``).
    public init(
        backend: any VisionActionGenerating,
        maxIterations: Int = 20,
        delayBetweenSteps: TimeInterval = 1.0,
        screenContextOptions: ScreenContextProvider.Options? = ScreenContextProvider.Options(),
        visionMode: AgentVisionMode = .always
    ) {
        self.backend = backend
        self.maxIterations = maxIterations
        self.delayBetweenSteps = delayBetweenSteps
        self.screenContextOptions = screenContextOptions
        self.visionMode = visionMode
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

            // 1. Observe structured screen state first.
            let screenContext: ScreenContext? = screenContextOptions.map { options in
                ScreenContextProvider.gather(options: options)
            }

            let includeScreenshot: Bool
            switch visionMode {
            case .always:
                includeScreenshot = true
            case .automatic:
                includeScreenshot = screenContext?.actionableElementCount == 0
            case .never:
                includeScreenshot = false
            }

            let jpegData: Data?
            if includeScreenshot {
                guard let screenshot = try await SwiftAutoGUI.screenshot(),
                      let data = screenshot.jpegData(compressionFactor: 0.5) else {
                    throw ActionGeneratorError.invalidResponse(detail: "Failed to capture screenshot")
                }
                jpegData = data
            } else {
                jpegData = nil
            }

            let screenSize = SwiftAutoGUI.size()
            let screenCGSize = CGSize(width: screenSize.width, height: screenSize.height)

            // 2. Think: send to backend
            let response = try await backend.generateActions(
                goal: goal,
                screenshot: jpegData,
                screenSize: screenCGSize,
                history: steps,
                screenContext: screenContext
            )

            // 3. Act: execute against the observation used by the model. Stop
            // as soon as the UI changes or an action fails, then re-observe.
            var currentContext = screenContext
            var executedActions: [BasicAction] = []
            var executionResults: [ActionExecutionResult] = []
            for action in response.actions {
                let execution = await AgentActionExecutor.execute(
                    action,
                    in: currentContext,
                    screenContextOptions: screenContextOptions
                )
                executedActions.append(action)
                executionResults.append(execution.result)
                currentContext = execution.screenContext

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
