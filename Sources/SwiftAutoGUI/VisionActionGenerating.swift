//
//  VisionActionGenerating.swift
//  SwiftAutoGUI
//

import Foundation

// MARK: - VisionActionGenerating Protocol

/// A protocol for backends that generate automation actions from screenshots and natural language goals.
///
/// Unlike ``ActionGenerating`` which only takes text prompts, this protocol accepts
/// screenshots and conversation history, enabling an observe-think-act agent loop.
///
/// ## Example
///
/// ```swift
/// let backend: any VisionActionGenerating = OpenAIVisionBackend(apiKey: "sk-...")
/// let response = try await backend.generateActions(
///     goal: "Open Safari",
///     screenshot: screenshotData,
///     screenSize: CGSize(width: 1920, height: 1080),
///     history: []
/// )
/// ```
public protocol VisionActionGenerating: Sendable {
    /// Whether this backend is currently available.
    var isAvailable: Bool { get }

    /// A human-readable message describing why the backend is unavailable.
    var unavailableReason: String? { get }

    /// Generates actions based on a goal, current screenshot, and previous history.
    ///
    /// - Parameters:
    ///   - goal: The natural language goal to accomplish.
    ///   - screenshot: JPEG-compressed screenshot data of the current screen.
    ///   - screenSize: The screen dimensions in points.
    ///   - history: Previous agent steps for context.
    /// - Returns: An ``AgentResponse`` containing actions, reasoning, and completion status.
    func generateActions(
        goal: String,
        screenshot: Data,
        screenSize: CGSize,
        history: [AgentStep]
    ) async throws -> AgentResponse
}

// MARK: - Agent Types

/// A record of one step in the agent loop.
public struct AgentStep: Sendable {
    /// The actions that were executed in this step.
    public let actions: [BasicAction]

    /// The LLM's reasoning about what it observed and decided.
    public let reasoning: String

    /// When this step occurred.
    public let timestamp: Date

    public init(actions: [BasicAction], reasoning: String, timestamp: Date = Date()) {
        self.actions = actions
        self.reasoning = reasoning
        self.timestamp = timestamp
    }
}

/// The response from a vision backend for one agent iteration.
public struct AgentResponse: Sendable {
    /// The actions to execute.
    public let actions: [BasicAction]

    /// The LLM's reasoning about the current screen state and chosen actions.
    public let reasoning: String

    /// Whether the LLM believes the goal has been achieved.
    public let isDone: Bool

    public init(actions: [BasicAction], reasoning: String, isDone: Bool) {
        self.actions = actions
        self.reasoning = reasoning
        self.isDone = isDone
    }
}

/// The result of a completed agent run.
public struct AgentResult: Sendable {
    /// All steps executed during the agent run.
    public let steps: [AgentStep]

    /// Whether the agent believes it successfully completed the goal.
    public let completed: Bool

    /// The number of iterations used.
    public let iterationsUsed: Int

    public init(steps: [AgentStep], completed: Bool, iterationsUsed: Int) {
        self.steps = steps
        self.completed = completed
        self.iterationsUsed = iterationsUsed
    }
}
