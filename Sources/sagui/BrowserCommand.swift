import ArgumentParser
import Foundation
import SwiftAutoGUI
import SwiftAutoGUIBrowser

/// Inspect and automate an existing Chromium remote-debugging session.
struct BrowserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "browser",
        abstract: "Control Chromium pages through the Chrome DevTools Protocol.",
        subcommands: [
            BrowserTabsCommand.self,
            BrowserObserveCommand.self,
            BrowserActivateTabCommand.self,
            BrowserOpenCommand.self,
            BrowserClickCommand.self,
            BrowserSetValueCommand.self,
            BrowserTypeCommand.self,
            BrowserKeyCommand.self,
            BrowserScrollCommand.self,
            BrowserAgentCommand.self,
        ]
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

struct BrowserObserveCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "observe",
        abstract: "Print numbered semantic elements from a Chromium page."
    )

    @OptionGroup var target: BrowserTargetOptions

    @Option(help: "Optional path for a JPEG screenshot of the page.")
    var screenshot: String?

    func run() async throws {
        try await withBrowserSession(connection: target.connection, tabID: target.tabID) { browser in
            let observation = try await browser.observe(
                tabID: target.tabID,
                includeScreenshot: screenshot != nil
            )
            print(observation.formattedContext)
            if let screenshot, let data = observation.screenshotJPEGData {
                try data.write(to: URL(fileURLWithPath: screenshot), options: .atomic)
                print("Screenshot: \(screenshot)")
            }
        }
    }
}

struct BrowserActivateTabCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activate-tab",
        abstract: "Activate a Chromium page tab by target ID."
    )

    @Argument(help: "CDP target ID printed by browser tabs.")
    var tabID: String

    @OptionGroup var connection: BrowserConnectionOptions

    func run() async throws {
        try await withBrowserSession(connection: connection, tabID: tabID) { browser in
            let tabs = try await browser.listTabs()
            printTabs(tabs)
        }
    }
}

struct BrowserOpenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Navigate the selected Chromium tab to an allowed URL."
    )

    @Argument(help: "HTTP or HTTPS URL to open.")
    var url: String

    @OptionGroup var target: BrowserTargetOptions

    func run() async throws {
        guard let destination = URL(string: url),
              let scheme = destination.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              destination.host != nil else {
            throw ValidationError("Provide an absolute HTTP or HTTPS URL.")
        }
        try await performBrowserAction(target: target) { _ in .navigate(destination) }
    }
}

struct BrowserClickCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "click",
        abstract: "Click a semantic element in the selected Chromium tab."
    )

    @OptionGroup var target: BrowserTargetOptions
    @OptionGroup var selector: BrowserElementSelector

    func run() async throws {
        try await performBrowserAction(target: target) { observation in
            .click(elementID: try selector.resolve(in: observation).elementID)
        }
    }
}

struct BrowserSetValueCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-value",
        abstract: "Replace the value of an editable semantic element."
    )

    @Argument(help: "Replacement text.")
    var value: String

    @OptionGroup var target: BrowserTargetOptions
    @OptionGroup var selector: BrowserElementSelector

    func run() async throws {
        try await performBrowserAction(target: target) { observation in
            .replaceText(elementID: try selector.resolve(in: observation).elementID, value: value)
        }
    }
}

struct BrowserTypeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "type",
        abstract: "Insert text into the currently focused page element."
    )

    @Argument(help: "Text to insert.")
    var text: String

    @OptionGroup var target: BrowserTargetOptions

    func run() async throws {
        try await performBrowserAction(target: target) { _ in .insertText(text) }
    }
}

struct BrowserKeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "key",
        abstract: "Send a key or key shortcut to the selected Chromium tab."
    )

    @Argument(help: "Key names, for example command a or return.")
    var keys: [String]

    @OptionGroup var target: BrowserTargetOptions

    func run() async throws {
        try await performBrowserAction(target: target) { _ in .keyShortcut(keys) }
    }
}

struct BrowserScrollCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scroll",
        abstract: "Scroll the selected Chromium page."
    )

    @Option(parsing: .unconditional, help: "Vertical scroll clicks; positive scrolls up and negative scrolls down.")
    var vertical = 0

    @Option(parsing: .unconditional, help: "Horizontal scroll clicks; positive scrolls left and negative scrolls right.")
    var horizontal = 0

    @OptionGroup var target: BrowserTargetOptions

    mutating func validate() throws {
        guard vertical != 0 || horizontal != 0 else {
            throw ValidationError("Provide a non-zero --vertical or --horizontal value.")
        }
    }

    func run() async throws {
        try await performBrowserAction(target: target) { _ in
            .scroll(horizontal: horizontal, vertical: vertical)
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

struct BrowserConnectionOptions: ParsableArguments {
    @Option(help: "Loopback Chromium debugging endpoint.")
    var endpoint: String = "http://127.0.0.1:9222"

    @Option(
        name: .customLong("domain"),
        help: "Allowed page domain. Repeat for multiple domains."
    )
    var domains: [String] = []

    @Flag(help: "Approve cross-origin navigation when its destination is also in --domain.")
    var allowCrossOrigin = false
}

struct BrowserTargetOptions: ParsableArguments {
    @OptionGroup var connection: BrowserConnectionOptions

    @Option(help: "CDP target ID printed by browser tabs.")
    var tabID: String
}

struct BrowserElementSelector: ParsableArguments {
    @Option(help: "Optional step-local element ID used to disambiguate matching role and name values.")
    var elementID: Int?

    @Option(help: "Exact semantic role printed by browser observe.")
    var role: String

    @Option(help: "Exact accessible name printed by browser observe.")
    var name: String

    mutating func validate() throws {
        if let elementID, elementID <= 0 {
            throw ValidationError("--element-id must be greater than zero.")
        }
    }

    func resolve(in observation: BrowserObservation) throws -> BrowserElement {
        if let elementID {
            guard let element = observation.element(withID: elementID),
                  element.role.compare(role, options: .caseInsensitive) == .orderedSame,
                  element.name == name else {
                throw ValidationError(
                    "Element #\(elementID) does not match role \(role) and name \(name) in the current observation."
                )
            }
            return element
        }

        let matches = observation.elements.filter {
            $0.role.compare(role, options: .caseInsensitive) == .orderedSame
                && $0.name == name
        }
        guard matches.count == 1, let element = matches.first else {
            if matches.isEmpty {
                throw ValidationError("No current element matches role \(role) and name \(name).")
            }
            throw ValidationError("Multiple current elements match role \(role) and name \(name); use --element-id.")
        }
        return element
    }
}

private func withBrowserSession<Result>(
    connection: BrowserConnectionOptions,
    tabID: String? = nil,
    operation: (BrowserSession) async throws -> Result
) async throws -> Result {
    let endpointURL = try validatedEndpoint(connection.endpoint)
    let domainSet = Set(connection.domains.map { $0.lowercased() })
    let authorizer: (any BrowserActionAuthorizing)? = connection.allowCrossOrigin
        ? SaguiBrowserAuthorizer()
        : nil
    let browser = try await BrowserSession.connect(
        endpoint: endpointURL,
        securityPolicy: BrowserSecurityPolicy(allowedDomains: domainSet),
        authorizer: authorizer
    )
    do {
        if let tabID { try await browser.activateTab(tabID) }
        let result = try await operation(browser)
        await browser.close()
        return result
    } catch {
        await browser.close()
        throw error
    }
}

private func performBrowserAction(
    target: BrowserTargetOptions,
    action: (BrowserObservation) throws -> BrowserAction
) async throws {
    try await withBrowserSession(connection: target.connection, tabID: target.tabID) { browser in
        let observation = try await browser.observe(tabID: target.tabID)
        let result = await browser.execute(try action(observation), against: observation)
        guard result.succeeded else {
            throw result.failure ?? BrowserError.unsupportedAction("the requested command")
        }
        print("Result: succeeded via cdp")
        if let navigation = result.navigation {
            print("Navigation: \(navigation.fromURL ?? "(none)") -> \(navigation.toURL)")
        }
        for change in result.tabChanges {
            print("Tab: \(change.kind.rawValue) \(change.tabID) \(change.url ?? "")")
        }
        for download in result.downloads {
            print("Download: \(download.state.rawValue) \(download.suggestedFilename ?? download.identifier)")
        }
        print(result.observation.formattedContext)
    }
}

private func printTabs(_ tabs: [BrowserTab]) {
    for tab in tabs {
        print("\(tab.state.rawValue)\t\(tab.id)\t\(tab.title)\t\(tab.url)")
    }
}

private func validatedEndpoint(_ value: String) throws -> URL {
    guard let url = URL(string: value), url.host != nil else {
        throw ValidationError("Invalid --endpoint value: \(value)")
    }
    return url
}
