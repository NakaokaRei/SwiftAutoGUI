import Foundation
import FoundationModels

/// Controls when ``Agent`` includes a screenshot in an observation.
public enum AgentVisionMode: String, Sendable, Codable, CaseIterable {
    /// Always capture a screenshot. This preserves the original Agent behavior.
    case always
    /// Omit the screenshot when actionable AX elements are available.
    case automatic
    /// Use structured screen context without a screenshot.
    case never
}

// MARK: - Agent Types

/// A record of one step in the agent loop.
public struct AgentStep: Sendable {
    /// The actions that were executed in this step.
    public let actions: [BasicAction]

    /// A short user-facing decision summary.
    public let reasoning: String

    /// Structured outcomes for the actions that were actually executed.
    public let executionResults: [ActionExecutionResult]

    /// When this step occurred.
    public let timestamp: Date

    public init(
        actions: [BasicAction],
        reasoning: String,
        executionResults: [ActionExecutionResult] = [],
        timestamp: Date = Date()
    ) {
        self.actions = actions
        self.reasoning = reasoning
        self.executionResults = executionResults
        self.timestamp = timestamp
    }
}

/// A structured decision shared by all model providers.
@Generable
public struct AgentDecision: Sendable {
    @Guide(description: "Concrete actions to execute now. If the goal is unfinished, include at least one action. To open an app, use activateApp(name:). An empty array is only for a completed goal.", .maximumCount(3))
    public var actions: [BasicAction]
    @Guide(description: "One short sentence explaining the chosen action.")
    public var reasoningSummary: String
    public var isDone: Bool

    public init(actions: [BasicAction], reasoningSummary: String, isDone: Bool) {
        self.actions = actions
        self.reasoningSummary = reasoningSummary
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
