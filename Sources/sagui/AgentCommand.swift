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
/// sagui agent "Click the trash icon" --model gpt-5.6-sol --reasoning-effort low --max-iterations 15
/// ```
struct AgentCommand: AsyncParsableCommand {
    enum ReasoningEffort: String, CaseIterable, ExpressibleByArgument {
        case none
        case low
        case medium
        case high
        case xhigh
        case max
    }

    enum VisionMode: String, CaseIterable, ExpressibleByArgument {
        case always
        case automatic
        case never
    }

    static let defaultModel = OpenAIVisionBackend.defaultModel

    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Run an AI agent to accomplish a goal using screen observation."
    )

    @Argument(help: "The goal for the agent to accomplish.")
    var goal: String

    @Option(help: "OpenAI API key. Can also be set via OPENAI_API_KEY environment variable.")
    var apiKey: String?

    @Option(help: "Vision model to use.")
    var model: String = Self.defaultModel

    @Option(help: "Reasoning effort: none, low, medium, high, xhigh, or max. Defaults to low for GPT-5.6 models.")
    var reasoningEffort: ReasoningEffort?

    @Option(help: "Maximum number of iterations.")
    var maxIterations: Int = 20

    @Option(help: "Delay between steps in seconds.")
    var delay: Double = 1.0

    @Flag(help: "Disable screen context (accessibility tree and window info).")
    var noScreenContext: Bool = false

    @Option(help: "Screenshot mode: always, automatic, or never.")
    var visionMode: VisionMode = .always

    @MainActor
    func run() async throws {
        let key = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        guard let key else {
            throw ValidationError("Provide --api-key or set OPENAI_API_KEY environment variable.")
        }

        let backend = OpenAIVisionBackend(
            apiKey: key,
            model: model,
            reasoningEffort: reasoningEffort?.rawValue
        )
        let contextOptions: ScreenContextProvider.Options? = noScreenContext ? nil : ScreenContextProvider.Options()
        let agent = Agent(
            backend: backend,
            maxIterations: maxIterations,
            delayBetweenSteps: delay,
            screenContextOptions: contextOptions,
            visionMode: AgentVisionMode(rawValue: visionMode.rawValue) ?? .always
        )

        print("Agent starting with goal: \"\(goal)\"")
        print("Model: \(model)")
        print("Reasoning effort: \(effectiveReasoningEffort)")
        print("Max iterations: \(maxIterations), Delay: \(delay)s, Screen context: \(!noScreenContext)")
        print("Vision mode: \(visionMode.rawValue)")
        print("---")

        let result = try await agent.run(goal: goal) { step in
            let timestamp = DateFormatter.localizedString(
                from: step.timestamp, dateStyle: .none, timeStyle: .medium
            )
            let actionSummary = step.actions.map { "\($0)" }.joined(separator: ", ")
            print("[\(timestamp)] Reasoning: \(step.reasoning)")
            print("  Actions: \(actionSummary)")
            for result in step.executionResults {
                let status = result.succeeded ? "succeeded" : "failed"
                let change = result.screenChanged ? ", UI changed" : ""
                let reason = result.failureReason.map { ", \($0)" } ?? ""
                print("  Result: \(status) via \(result.method.rawValue)\(change)\(reason)")
            }
            print("---")
        }

        print("Agent finished.")
        print("Completed: \(result.completed)")
        print("Iterations used: \(result.iterationsUsed)")
    }

    var effectiveReasoningEffort: String {
        if let reasoningEffort {
            return reasoningEffort.rawValue
        }
        if model.hasPrefix("gpt-5.6") {
            return OpenAIVisionBackend.defaultReasoningEffort
        }
        return "model default"
    }
}
