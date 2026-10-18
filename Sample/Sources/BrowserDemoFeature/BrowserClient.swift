import ComposableArchitecture
import Foundation
import SampleSupport
import SwiftAutoGUI
import SwiftAutoGUIBrowser

struct BrowserClient: Sendable {
    struct Snapshot: Sendable {
        var tabs: [BrowserTab]
        var observation: BrowserObservation?
        var selectedTabID: String
        var message: String
    }
    struct AgentRequest: Sendable {
        var goal: String
        var provider: AIProviderChoice
        var key: String
        var model: String
        var iterations: Int
        var delay: Double
        var tabID: String
    }
    enum Command: Sendable {
        case refresh, capture
        case select(String)
        case execute(BrowserAction, BrowserObservation)
    }
    enum Event: Sendable {
        case step(BrowserDemoFeature.AgentStepDisplay)
        case finished(Bool, Snapshot)
    }
    var connect: @Sendable (UUID, URL, Set<String>) async throws -> Snapshot
    var close: @Sendable (UUID) async -> Void
    var perform: @Sendable (UUID, String, Command) async throws -> Snapshot
    var run: @Sendable (UUID, AgentRequest) -> AsyncThrowingStream<Event, any Error>
}
extension BrowserClient: DependencyKey {
    static let liveValue: Self = {
        let connections = Connections()
        return Self(
            connect: { id, endpoint, domains in
                let session = try await BrowserSession.connect(
                    endpoint: endpoint,
                    securityPolicy: BrowserSecurityPolicy(allowedDomains: domains),
                    authorizer: SampleBrowserAuthorizer())
                do {
                    try Task.checkCancellation()
                    let snapshot = try await Self.snapshot(
                        session, selected: "", observe: true,
                        message: "Connected. Element IDs are valid only for the latest observation."
                    )
                    try Task.checkCancellation()
                    await connections.insert(session, id: id)
                    // If cancellation raced with insertion, remove the connection before returning.
                    if Task.isCancelled {
                        await connections.close(id)
                        throw CancellationError()
                    }
                    return snapshot
                } catch {
                    await session.close()
                    throw error
                }
            },
            close: { await connections.close($0) },
            perform: { id, selected, command in
                let session = try await connections.get(id)
                switch command {
                case .refresh:
                    return try await snapshot(
                        session, selected: selected, observe: false, message: "Tabs refreshed.")
                case .capture:
                    return try await snapshot(
                        session, selected: selected, observe: true,
                        message: "Captured a new observation.")
                case .select(let tab):
                    try await session.activateTab(tab)
                    return try await snapshot(
                        session, selected: tab, observe: true,
                        message: "Activated the selected tab and captured a new observation.")
                case .execute(let action, let observation):
                    let result = await session.execute(action, against: observation)
                    let tabs = try await session.listTabs()
                    return Snapshot(
                        tabs: tabs, observation: result.observation,
                        selectedTabID: result.observation.tab.id,
                        message: result.succeeded
                            ? "Action completed. The page was observed again automatically."
                            : result.failure?.localizedDescription ?? "The browser action failed.")
                }
            },
            run: { id, request in
                AsyncThrowingStream { continuation in
                    let task = Task { @MainActor in
                        do {
                            let session = try await connections.get(id)
                            let agent = Agent(
                                model: request.provider.model(
                                    apiKey: request.key, name: request.model),
                                maxIterations: request.iterations, delayBetweenSteps: request.delay,
                                screenContextOptions: nil, visionMode: .automatic,
                                automationBackend: session)
                            let result = try await agent.run(goal: request.goal) { step in
                                let actions = step.actions.map(Self.describeAction).joined(
                                    separator: ", ")
                                let executions = step.executionResults.map { execution in
                                    let detail = execution.failureReason.map { ": \($0)" } ?? ""
                                    return
                                        "\(execution.succeeded ? "✓" : "✗") \(execution.method.rawValue)\(detail)"
                                }.joined(separator: ", ")
                                continuation.yield(
                                    .step(
                                        .init(
                                            reasoning: step.reasoning,
                                            actions: actions
                                                + (executions.isEmpty ? "" : "\n" + executions))))
                            }
                            try Task.checkCancellation()
                            let snapshot = try await Self.snapshot(
                                session, selected: request.tabID, observe: true,
                                message: result.completed
                                    ? "Browser AI Agent completed the goal."
                                    : "Browser AI Agent reached its iteration limit.")
                            continuation.yield(.finished(result.completed, snapshot))
                            continuation.finish()
                        } catch { continuation.finish(throwing: error) }
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }()
    static let testValue = Self(
        connect: { _, _, _ in throw Connections.Disconnected() },
        close: { _ in },
        perform: { _, _, _ in throw Connections.Disconnected() },
        run: { _, _ in AsyncThrowingStream { $0.finish(throwing: Connections.Disconnected()) } }
    )
    private static func snapshot(
        _ session: BrowserSession, selected: String, observe: Bool, message: String
    ) async throws -> Snapshot {
        let tabs = try await session.listTabs()
        let tab =
            tabs.contains { $0.id == selected }
            ? selected : tabs.first(where: { $0.state == .active })?.id ?? tabs.first?.id ?? ""
        let observation =
            observe
            ? try await session.observe(tabID: tab.isEmpty ? nil : tab, includeScreenshot: false)
            : nil
        return Snapshot(
            tabs: tabs, observation: observation, selectedTabID: observation?.tab.id ?? tab,
            message: message)
    }
    private static func describeAction(_ action: BasicAction) -> String {
        switch action {
        case .write(let text): "write(\"\(text)\")"
        case .move(let x, let y): "move(\(Int(x)), \(Int(y)))"
        case .leftClick: "leftClick"
        case .rightClick: "rightClick"
        case .doubleClick: "doubleClick"
        case .vscroll(let clicks): "vscroll(\(clicks))"
        case .hscroll(let clicks): "hscroll(\(clicks))"
        case .wait(let duration): "wait(\(duration)s)"
        case .keyShortcut(let keys): "keyShortcut(\(keys.map(\.rawValue).joined(separator: "+")))"
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

private actor Connections {
    var sessions: [UUID: BrowserSession] = [:]
    func insert(_ session: BrowserSession, id: UUID) { sessions[id] = session }
    func get(_ id: UUID) throws -> BrowserSession {
        guard let session = sessions[id] else { throw Disconnected() }
        return session
    }
    func close(_ id: UUID) async {
        let session = sessions.removeValue(forKey: id)
        await session?.close()
    }
    struct Disconnected: Error {}
}
extension DependencyValues {
    var browserClient: BrowserClient {
        get { self[BrowserClient.self] }
        set { self[BrowserClient.self] = newValue }
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
