import ArgumentParser
import Foundation
import SwiftAutoGUI

/// Run an AI agent that observes the screen and executes actions to achieve a goal.
///
/// The agent takes screenshots, sends them to a vision-capable LLM, and executes
/// the returned actions in a loop until the goal is achieved or the iteration limit is reached.
///
/// ## Usage
///
/// ```bash
/// sagui agent "Open Safari and search for Swift" --api-key sk-...
/// sagui agent "Click the trash icon" --model gpt-4o --max-iterations 15
/// ```
struct AgentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Run an AI agent to accomplish a goal using screen observation."
    )

    @Argument(help: "The goal for the agent to accomplish.")
    var goal: String

    @Option(help: "OpenAI API key. Can also be set via OPENAI_API_KEY environment variable.")
    var apiKey: String?

    @Option(help: "Vision model to use.")
    var model: String = "gpt-5.4"

    @Option(help: "Maximum number of iterations.")
    var maxIterations: Int = 20

    @Option(help: "Delay between steps in seconds.")
    var delay: Double = 1.0

    @Flag(help: "Disable screen context (accessibility tree and window info).")
    var noScreenContext: Bool = false

    @MainActor
    func run() async throws {
        let key = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        guard let key else {
            throw ValidationError("Provide --api-key or set OPENAI_API_KEY environment variable.")
        }

        let backend = OpenAIVisionBackend(apiKey: key, model: model)
        let contextOptions: ScreenContextProvider.Options? = noScreenContext ? nil : ScreenContextProvider.Options()
        let agent = Agent(
            backend: backend,
            maxIterations: maxIterations,
            delayBetweenSteps: delay,
            screenContextOptions: contextOptions
        )

        print("Agent starting with goal: \"\(goal)\"")
        print("Model: \(model), Max iterations: \(maxIterations), Delay: \(delay)s, Screen context: \(!noScreenContext)")
        print("---")

        let result = try await agent.run(goal: goal) { step in
            let timestamp = DateFormatter.localizedString(
                from: step.timestamp, dateStyle: .none, timeStyle: .medium
            )
            let actionSummary = step.actions.map { "\($0)" }.joined(separator: ", ")
            print("[\(timestamp)] \(step.reasoning)")
            print("  Actions: \(actionSummary)")
            print("---")
        }

        print("Agent finished.")
        print("Completed: \(result.completed)")
        print("Iterations used: \(result.iterationsUsed)")
    }
}
