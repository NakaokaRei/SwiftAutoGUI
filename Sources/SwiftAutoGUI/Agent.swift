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

    /// Creates an agent with the specified configuration.
    ///
    /// - Parameters:
    ///   - backend: The vision backend to use for action generation.
    ///   - maxIterations: Maximum loop iterations (default: 20).
    ///   - delayBetweenSteps: Seconds to wait between steps (default: 1.0).
    public init(
        backend: any VisionActionGenerating,
        maxIterations: Int = 20,
        delayBetweenSteps: TimeInterval = 1.0
    ) {
        self.backend = backend
        self.maxIterations = maxIterations
        self.delayBetweenSteps = delayBetweenSteps
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

            // 1. Observe: take screenshot
            guard let screenshot = try await SwiftAutoGUI.screenshot(),
                  let jpegData = screenshot.jpegData(compressionFactor: 0.5) else {
                throw ActionGeneratorError.invalidResponse(detail: "Failed to capture screenshot")
            }

            let screenSize = SwiftAutoGUI.size()
            let screenCGSize = CGSize(width: screenSize.width, height: screenSize.height)

            // 2. Think: send to backend
            let response = try await backend.generateActions(
                goal: goal,
                screenshot: jpegData,
                screenSize: screenCGSize,
                history: steps
            )

            // 3. Act: execute actions
            let actions = response.actions.map { $0.toAction() }
            await actions.execute()

            // 4. Record step
            let step = AgentStep(
                actions: response.actions,
                reasoning: response.reasoning
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
