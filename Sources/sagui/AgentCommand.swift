import ArgumentParser
import Foundation
import FoundationModels
import SwiftAutoGUI

/// Run an AI agent that observes the screen and executes actions to achieve a goal.
///
/// The agent takes screenshots, sends them to a vision-capable LLM, and executes
/// the returned actions in a loop until the goal is achieved or the iteration limit is reached.
///
/// ## Usage
///
/// ```bash
/// sagui agent "Open Safari and search for Swift" --provider openai
/// sagui agent "Click the trash icon" --model gpt-5.6-sol --provider openai --max-iterations 15
/// ```
struct AgentCommand: AsyncParsableCommand {
    enum Provider: String, CaseIterable, ExpressibleByArgument {
        case onDevice = "on-device"
        case pcc
        case openAI = "openai"
    }

    enum VisionMode: String, CaseIterable, ExpressibleByArgument {
        case always
        case automatic
        case never
    }

    static let defaultModel = AutomationModels.defaultAgentModel

    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Run an AI agent to accomplish a goal using screen observation."
    )

    @Argument(help: "The goal for the agent to accomplish.")
    var goal: String

    @Option(help: "OpenAI API key. Can also be set via OPENAI_API_KEY environment variable.")
    var apiKey: String?

    @Option(help: "Model name for --provider openai.")
    var model: String = Self.defaultModel

    @Option(help: "AI provider: on-device, pcc (requires entitlement), or openai. Cloud providers receive screen content.")
    var provider: Provider = .onDevice

    @Flag(help: "Explicitly fall back to the on-device model if the selected provider is unavailable.")
    var fallbackOnDevice = false

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
        let selectedModel = try Self.makeModel(provider: provider, apiKey: apiKey, name: model)
        let contextOptions: ScreenContextProvider.Options? = noScreenContext ? nil : ScreenContextProvider.Options()
        let agent = Agent(
            model: selectedModel,
            fallbackModel: fallbackOnDevice ? SystemLanguageModel.default : nil,
            maxIterations: maxIterations,
            delayBetweenSteps: delay,
            screenContextOptions: contextOptions,
            visionMode: AgentVisionMode(rawValue: visionMode.rawValue) ?? .always
        )

        print("Agent starting with goal: \"\(goal)\"")
        if provider == .openAI { print("Model: \(model)") }
        print("Provider: \(provider.rawValue)")
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

    static func makeModel(provider: Provider, apiKey: String?, name: String) throws -> any LanguageModel {
        switch provider {
        case .onDevice: return SystemLanguageModel.default
        case .pcc: return PrivateCloudComputeLanguageModel()
        case .openAI:
            let key = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            guard let key, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ValidationError("Provide --api-key or set OPENAI_API_KEY for --provider openai.")
            }
            return AutomationModels.openAI(apiKey: key, model: name)
        }
    }
}
