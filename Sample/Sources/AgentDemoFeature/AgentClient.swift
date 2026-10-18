import ComposableArchitecture
import Foundation
import SwiftAutoGUI

struct AgentClient: Sendable {
    struct Request: Sendable {
        var goal: String
        var provider: AIProviderChoice
        var apiKey: String
        var model: String
        var maxIterations: Int
        var delay: Double
        var useScreenContext: Bool
    }

    enum Event: Equatable, Sendable {
        case step(AgentDemoFeature.StepDisplay)
        case finished(Bool)
    }

    var run: @Sendable (Request) -> AsyncThrowingStream<Event, any Error>
}

extension AgentClient: DependencyKey {
    static let liveValue = Self { request in
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    let agent = Agent(
                        model: request.provider.model(apiKey: request.apiKey, name: request.model),
                        maxIterations: request.maxIterations,
                        delayBetweenSteps: request.delay,
                        screenContextOptions: request.useScreenContext ? .init() : nil
                    )
                    let result = try await agent.run(goal: request.goal) { step in
                        let actions = step.actions.map(Self.describeAction).joined(separator: ", ")
                        let results = step.executionResults.map {
                            "\($0.succeeded ? "✓" : "✗") \($0.method.rawValue)" +
                                ($0.screenChanged ? " (UI changed)" : "")
                        }.joined(separator: ", ")
                        continuation.yield(.step(.init(
                            reasoning: step.reasoning,
                            actions: actions + (results.isEmpty ? "" : "\n" + results),
                            timestamp: step.timestamp
                        )))
                    }
                    try Task.checkCancellation()
                    continuation.yield(.finished(result.completed))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static let testValue = Self { _ in
        AsyncThrowingStream { $0.finish(throwing: Unimplemented()) }
    }
    private struct Unimplemented: Error {}

    private static func describeAction(_ action: BasicAction) -> String {
        switch action {
        case .write(let text): return "write(\"\(text)\")"
        case .move(let x, let y): return "move(\(Int(x)), \(Int(y)))"
        case .leftClick: return "leftClick"
        case .rightClick: return "rightClick"
        case .doubleClick: return "doubleClick"
        case .vscroll(let clicks): return "vscroll(\(clicks))"
        case .hscroll(let clicks): return "hscroll(\(clicks))"
        case .wait(let duration): return "wait(\(duration)s)"
        case .keyShortcut(let keys): return "keyShortcut(\(keys.map(\.rawValue).joined(separator: "+")))"
        case .drag(let fromX, let fromY, let toX, let toY):
            return "drag(\(Int(fromX)),\(Int(fromY))->\(Int(toX)),\(Int(toY)))"
        case .openURL(let url):
            return "openURL(\"\(url)\")"
        case .activateTab(let tabID):
            return "activateTab(\"\(tabID)\")"
        case .activateApp(let name):
            return "activateApp(\"\(name)\")"
        case .quitApp(let name):
            return "quitApp(\"\(name)\")"
        case .getFrontmostApp:
            return "getFrontmostApp"
        case .pressButton(let label, let bundleID):
            return "pressButton(\"\(label)\"\(bundleID.isEmpty ? "" : " in \(bundleID)"))"
        case .pressElement(let elementID):
            return "pressElement(#\(elementID))"
        case .setTextField(let label, let value, let bundleID):
            return "setTextField(label:\"\(label)\", value:\"\(value)\"\(bundleID.isEmpty ? "" : " in \(bundleID)"))"
        case .setElementValue(let elementID, let value):
            return "setElementValue(#\(elementID), value:\"\(value)\")"
        case .selectMenuItem(let path, let bundleID):
            return "selectMenuItem(\(path.joined(separator: " > "))\(bundleID.isEmpty ? "" : " in \(bundleID)"))"
        case .raiseWindow(let title, let bundleID):
            return "raiseWindow(\"\(title)\"\(bundleID.isEmpty ? "" : " in \(bundleID)"))"
        }
    }
}

extension DependencyValues {
    var agentClient: AgentClient {
        get { self[AgentClient.self] }
        set { self[AgentClient.self] = newValue }
    }
}
