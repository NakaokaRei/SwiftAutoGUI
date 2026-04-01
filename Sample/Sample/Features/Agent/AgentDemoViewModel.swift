//
//  AgentDemoViewModel.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class AgentDemoViewModel {
    var goal: String = ""
    var isRunning = false
    var error: String?

    // MARK: - Backend Settings

    var openAIKey: String = ""
    var openAIModel: String = "gpt-5.4"
    var maxIterations: Int = 20
    var delayBetweenSteps: Double = 1.0

    static let availableModels = [
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-5.4-nano",
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-4.1",
        "gpt-4.1-mini",
    ]

    let sampleGoals: [String] = [
        "Open Safari and search for Swift programming",
        "Open System Settings",
        "Open Finder and create a new folder on Desktop",
        "Open TextEdit and type 'Hello, World!'",
    ]

    // MARK: - Step Tracking

    struct StepDisplay: Identifiable {
        let id = UUID()
        let number: Int
        let reasoning: String
        let actions: String
        let timestamp: Date
    }

    var steps: [StepDisplay] = []
    var completed: Bool?

    private var runTask: Task<Void, Never>?

    // MARK: - Actions

    func startAgent() {
        guard !goal.isEmpty else {
            error = "Please enter a goal"
            return
        }
        guard !openAIKey.isEmpty else {
            error = "Please enter your OpenAI API key"
            return
        }

        isRunning = true
        error = nil
        steps = []
        completed = nil

        runTask = Task {
            do {
                let backend = OpenAIVisionBackend(apiKey: openAIKey, model: openAIModel)
                let agent = Agent(
                    backend: backend,
                    maxIterations: maxIterations,
                    delayBetweenSteps: delayBetweenSteps
                )

                let result = try await agent.run(goal: goal) { [weak self] step in
                    guard let self else { return }
                    Task { @MainActor in
                        let actionSummary = step.actions.map { self.describeAction($0) }.joined(separator: ", ")
                        self.steps.append(StepDisplay(
                            number: self.steps.count + 1,
                            reasoning: step.reasoning,
                            actions: actionSummary,
                            timestamp: step.timestamp
                        ))
                    }
                }

                completed = result.completed
            } catch is CancellationError {
                // Stopped by user
            } catch {
                self.error = String(describing: error)
            }

            isRunning = false
        }
    }

    func stopAgent() {
        runTask?.cancel()
        runTask = nil
    }

    func useSampleGoal(_ sample: String) {
        goal = sample
    }

    func clearResults() {
        steps = []
        completed = nil
        error = nil
    }

    private func describeAction(_ action: BasicAction) -> String {
        switch action {
        case .write(let text): return "write(\"\(text)\")"
        case .move(let x, let y): return "move(\(Int(x)), \(Int(y)))"
        case .leftClick: return "leftClick"
        case .rightClick: return "rightClick"
        case .doubleClick: return "doubleClick"
        case .vscroll(let clicks): return "vscroll(\(clicks))"
        case .hscroll(let clicks): return "hscroll(\(clicks))"
        case .wait(let duration): return "wait(\(duration)s)"
        case .keyShortcut(let keys): return "keyShortcut(\(keys.joined(separator: "+")))"
        case .drag(let fromX, let fromY, let toX, let toY):
            return "drag(\(Int(fromX)),\(Int(fromY))->\(Int(toX)),\(Int(toY)))"
        }
    }
}
