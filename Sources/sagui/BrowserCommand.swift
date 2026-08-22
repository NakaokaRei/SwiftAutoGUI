import ArgumentParser
import Foundation
import SwiftAutoGUI
import SwiftAutoGUIBrowser

/// Inspect and automate an existing Chromium remote-debugging session.
struct BrowserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "browser",
        abstract: "Control Chromium pages through the Chrome DevTools Protocol.",
        subcommands: [BrowserTabsCommand.self, BrowserAgentCommand.self]
    )
}

struct BrowserTabsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tabs",
        abstract: "List page tabs exposed by a Chromium debugging endpoint."
    )

    @Option(help: "Loopback Chromium debugging endpoint.")
    var endpoint: String = "http://127.0.0.1:9222"

    func run() async throws {
        let endpointURL = try validatedEndpoint(endpoint)
        let browser = try await BrowserSession.connect(endpoint: endpointURL)
        do {
            let tabs = try await browser.listTabs()
            for tab in tabs {
                print("\(tab.state.rawValue)\t\(tab.id)\t\(tab.title)\t\(tab.url)")
            }
            await browser.close()
        } catch {
            await browser.close()
            throw error
        }
    }
}

struct BrowserAgentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Run an AI Agent that is restricted to Chromium page actions."
    )

    @Argument(help: "The browser goal for the Agent to accomplish.")
    var goal: String

    @Option(help: "Loopback Chromium debugging endpoint.")
    var endpoint: String = "http://127.0.0.1:9222"

    @Option(
        name: .customLong("domain"),
        help: "Allowed page domain. Repeat for multiple domains, for example --domain example.com --domain '*.example.org'."
    )
    var domains: [String] = []

    @Option(help: "Optional CDP target ID to activate before starting.")
    var tabID: String?

    @Flag(help: "Approve cross-origin navigation when its destination is also in --domain. Downloads remain denied.")
    var allowCrossOrigin = false

    @Option(help: "OpenAI API key. Prefer the OPENAI_API_KEY environment variable.")
    var apiKey: String?

    @Option(help: "OpenAI model to use.")
    var model: String = OpenAIVisionBackend.defaultModel

    @Option(help: "Reasoning effort: none, low, medium, high, xhigh, or max.")
    var reasoningEffort: AgentCommand.ReasoningEffort?

    @Option(help: "Maximum number of observe-think-act iterations.")
    var maxIterations = 20

    @Option(help: "Delay between Agent steps in seconds.")
    var delay = 1.0

    @Option(help: "Screenshot mode: always, automatic, or never.")
    var visionMode: AgentCommand.VisionMode = .automatic

    @MainActor
    func run() async throws {
        guard !domains.isEmpty else {
            throw ValidationError("Provide at least one --domain allowlist entry.")
        }
        let key = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        guard let key, !key.isEmpty else {
            throw ValidationError("Set OPENAI_API_KEY or provide --api-key.")
        }

        let endpointURL = try validatedEndpoint(endpoint)
        let domainSet = Set(domains.map { $0.lowercased() })
        let authorizer: (any BrowserActionAuthorizing)? = allowCrossOrigin
            ? SaguiBrowserAuthorizer()
            : nil
        let browser = try await BrowserSession.connect(
            endpoint: endpointURL,
            securityPolicy: BrowserSecurityPolicy(allowedDomains: domainSet),
            authorizer: authorizer
        )

        do {
            if let tabID { try await browser.activateTab(tabID) }

            let backend = OpenAIVisionBackend(
                apiKey: key,
                model: model,
                reasoningEffort: reasoningEffort?.rawValue
            )
            let agent = Agent(
                backend: backend,
                maxIterations: maxIterations,
                delayBetweenSteps: delay,
                screenContextOptions: nil,
                visionMode: AgentVisionMode(rawValue: visionMode.rawValue) ?? .automatic,
                automationBackend: browser
            )

            print("Browser Agent starting with goal: \"\(goal)\"")
            print("Endpoint: \(endpoint)")
            print("Domains: \(domains.joined(separator: ", "))")
            print("Model: \(model), Vision mode: \(visionMode.rawValue)")
            print("Cross-origin: \(allowCrossOrigin ? "allowlisted" : "denied"), Downloads: denied")
            print("---")

            let result = try await agent.run(goal: goal) { step in
                let actionSummary = step.actions.map { String(describing: $0) }.joined(separator: ", ")
                print("Reasoning: \(step.reasoning)")
                print("  Actions: \(actionSummary)")
                for execution in step.executionResults {
                    let status = execution.succeeded ? "succeeded" : "failed"
                    let change = execution.screenChanged ? ", page changed" : ""
                    let reason = execution.failureReason.map { ", \($0)" } ?? ""
                    print("  Result: \(status) via \(execution.method.rawValue)\(change)\(reason)")
                }
                print("---")
            }

            print("Browser Agent finished.")
            print("Completed: \(result.completed)")
            print("Iterations used: \(result.iterationsUsed)")
            await browser.close()
        } catch {
            await browser.close()
            throw error
        }
    }
}

private struct SaguiBrowserAuthorizer: BrowserActionAuthorizing {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool {
        switch request {
        case .crossOriginNavigation: true
        case .download: false
        }
    }
}

private func validatedEndpoint(_ value: String) throws -> URL {
    guard let url = URL(string: value), url.host != nil else {
        throw ValidationError("Invalid --endpoint value: \(value)")
    }
    return url
}
