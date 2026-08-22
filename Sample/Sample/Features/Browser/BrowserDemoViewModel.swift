import Foundation
import SwiftAutoGUI
import SwiftAutoGUIBrowser
import SwiftUI

@MainActor
@Observable
final class BrowserDemoViewModel {
    var endpoint = "http://127.0.0.1:9222"
    var allowedDomains = "example.com"
    var selectedTabID = ""
    var selectedElementID = 1
    var replacementText = ""
    var agentGoal = "Find the SwiftAutoGUI repository and open its Issues page"
    var openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    var openAIModel = OpenAIVisionBackend.defaultModel
    var maxAgentIterations = 12
    var agentDelay = 0.8

    private(set) var tabs: [BrowserTab] = []
    private(set) var observation: BrowserObservation?
    private(set) var statusMessage = "Start Chromium with remote debugging, then connect."
    private(set) var isConnected = false
    private(set) var isWorking = false
    private(set) var isAgentRunning = false
    private(set) var agentCompleted: Bool?
    private(set) var agentError: String?
    private(set) var agentSteps: [AgentStepDisplay] = []

    @ObservationIgnored private var session: BrowserSession?
    @ObservationIgnored private var agentTask: Task<Void, Never>?

    struct AgentStepDisplay: Identifiable {
        let id = UUID()
        let number: Int
        let reasoning: String
        let actions: String
    }

    static let availableModels = [
        "gpt-5.6-sol",
        "gpt-5.6-terra",
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-4o",
        "gpt-4o-mini",
    ]

    let sampleAgentGoals = [
        "Open the Issues page for this repository",
        "Find issue 118 and open it",
        "Search this page for BrowserSession",
    ]

    var formattedOutput: String {
        observation?.formattedContext ?? ""
    }

    func connect() {
        guard !isWorking else { return }
        guard let endpointURL = URL(string: endpoint), endpointURL.host != nil else {
            statusMessage = "Enter a valid HTTP endpoint."
            return
        }

        let domains = Set(
            allowedDomains
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        guard !domains.isEmpty else {
            statusMessage = "Enter at least one allowed page domain."
            return
        }

        isWorking = true
        statusMessage = "Connecting to Chromium…"
        Task {
            do {
                if let currentSession = session {
                    await currentSession.close()
                }
                let newSession = try await BrowserSession.connect(
                    endpoint: endpointURL,
                    securityPolicy: BrowserSecurityPolicy(allowedDomains: domains),
                    authorizer: SampleBrowserAuthorizer()
                )
                session = newSession
                isConnected = true
                try await refresh(using: newSession)
                try await observe(using: newSession)
                statusMessage = "Connected. Element IDs are valid only for the latest observation."
            } catch {
                session = nil
                isConnected = false
                tabs = []
                observation = nil
                statusMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

    func disconnect() {
        stopAgent()
        let currentSession = session
        session = nil
        isConnected = false
        isWorking = false
        tabs = []
        selectedTabID = ""
        observation = nil
        statusMessage = "Disconnected."
        Task { await currentSession?.close() }
    }

    func startAgent() {
        guard let session, isConnected else {
            agentError = "Connect to Chromium first."
            return
        }
        guard !agentGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            agentError = "Enter a browser goal."
            return
        }
        guard !openAIKey.isEmpty else {
            agentError = "Enter an OpenAI API key or launch the app with OPENAI_API_KEY."
            return
        }
        guard !isAgentRunning else { return }

        isAgentRunning = true
        agentCompleted = nil
        agentError = nil
        agentSteps = []
        statusMessage = "Browser AI Agent is running…"

        let goal = agentGoal
        let backend = OpenAIVisionBackend(apiKey: openAIKey, model: openAIModel)
        let agent = Agent(
            backend: backend,
            maxIterations: maxAgentIterations,
            delayBetweenSteps: agentDelay,
            screenContextOptions: nil,
            visionMode: .automatic,
            automationBackend: session
        )

        agentTask = Task {
            do {
                let result = try await agent.run(goal: goal) { [weak self] step in
                    Task { @MainActor in
                        guard let self else { return }
                        let actions = step.actions.map(self.describeAction).joined(separator: ", ")
                        let executions = step.executionResults.map { execution in
                            let state = execution.succeeded ? "✓" : "✗"
                            let detail = execution.failureReason.map { ": \($0)" } ?? ""
                            return "\(state) \(execution.method.rawValue)\(detail)"
                        }.joined(separator: ", ")
                        self.agentSteps.append(
                            AgentStepDisplay(
                                number: self.agentSteps.count + 1,
                                reasoning: step.reasoning,
                                actions: actions + (executions.isEmpty ? "" : "\n\(executions)")
                            )
                        )
                    }
                }
                agentCompleted = result.completed
                statusMessage = result.completed
                    ? "Browser AI Agent completed the goal."
                    : "Browser AI Agent reached its iteration limit."
                try await refresh(using: session)
                try await observe(using: session)
            } catch is CancellationError {
                statusMessage = "Browser AI Agent stopped."
            } catch {
                agentError = error.localizedDescription
                statusMessage = "Browser AI Agent failed."
            }
            isAgentRunning = false
            agentTask = nil
        }
    }

    func stopAgent() {
        agentTask?.cancel()
        statusMessage = "Stopping Browser AI Agent…"
    }

    func clearAgentResult() {
        agentSteps = []
        agentCompleted = nil
        agentError = nil
    }

    func refreshTabs() {
        guard let session, !isWorking, !isAgentRunning else { return }
        run { try await self.refresh(using: session) }
    }

    func selectTab(_ tabID: String) {
        guard let session, !isWorking, !isAgentRunning else { return }
        selectedTabID = tabID
        run {
            try await session.activateTab(tabID)
            try await self.refresh(using: session)
            try await self.observe(using: session)
            self.statusMessage = "Activated the selected tab and captured a new observation."
        }
    }

    func capture() {
        guard let session, !isWorking, !isAgentRunning else { return }
        run {
            try await self.observe(using: session)
            self.statusMessage = "Captured \(self.observation?.elements.count ?? 0) actionable elements."
        }
    }

    func clickSelectedElement() {
        execute(.click(elementID: selectedElementID))
    }

    func replaceSelectedElementText() {
        execute(.replaceText(elementID: selectedElementID, value: replacementText))
    }

    private func execute(_ action: BrowserAction) {
        guard let session, let observation, !isWorking, !isAgentRunning else { return }
        run {
            let result = await session.execute(action, against: observation)
            self.observation = result.observation
            try await self.refresh(using: session)
            if result.succeeded {
                self.statusMessage = "Action completed. The page was observed again automatically."
            } else {
                self.statusMessage = result.failure?.localizedDescription ?? "The browser action failed."
            }
        }
    }

    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        isWorking = true
        Task {
            do {
                try await operation()
            } catch {
                statusMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

    private func refresh(using session: BrowserSession) async throws {
        tabs = try await session.listTabs()
        if !tabs.contains(where: { $0.id == selectedTabID }) {
            selectedTabID = tabs.first(where: { $0.state == .active })?.id ?? tabs.first?.id ?? ""
        }
    }

    private func observe(using session: BrowserSession) async throws {
        observation = try await session.observe(
            tabID: selectedTabID.isEmpty ? nil : selectedTabID,
            includeScreenshot: false
        )
        selectedTabID = observation?.tab.id ?? selectedTabID
    }

    private func describeAction(_ action: BasicAction) -> String {
        switch action {
        case .write(let text): "write(\"\(text)\")"
        case .move(let x, let y): "move(\(Int(x)), \(Int(y)))"
        case .leftClick: "leftClick"
        case .rightClick: "rightClick"
        case .doubleClick: "doubleClick"
        case .vscroll(let clicks): "vscroll(\(clicks))"
        case .hscroll(let clicks): "hscroll(\(clicks))"
        case .wait(let duration): "wait(\(duration)s)"
        case .keyShortcut(let keys): "keyShortcut(\(keys.joined(separator: "+")))"
        case .drag(let fromX, let fromY, let toX, let toY):
            "drag(\(Int(fromX)),\(Int(fromY))->\(Int(toX)),\(Int(toY)))"
        case .openURL(let url): "openURL(\"\(url)\")"
        case .activateTab(let tabID): "activateTab(\"\(tabID)\")"
        case .pressElement(let elementID): "pressElement(#\(elementID))"
        case .setElementValue(let elementID, let value):
            "setElementValue(#\(elementID), value:\"\(value)\")"
        case .activateApp(let name): "activateApp(\"\(name)\")"
        case .quitApp(let name): "quitApp(\"\(name)\")"
        case .getFrontmostApp: "getFrontmostApp"
        case .pressButton(let label, _): "pressButton(\"\(label)\")"
        case .setTextField(let label, let value, _):
            "setTextField(\"\(label)\", \"\(value)\")"
        case .selectMenuItem(let path, _): "selectMenuItem(\(path.joined(separator: " > ")))"
        case .raiseWindow(let title, _): "raiseWindow(\"\(title)\")"
        }
    }
}

/// The domain field is the user's explicit allowlist for this demo. Cross-origin
/// navigation within that allowlist is approved; downloads remain denied.
private struct SampleBrowserAuthorizer: BrowserActionAuthorizing {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool {
        switch request {
        case .crossOriginNavigation: true
        case .download: false
        }
    }
}
