//
//  AIGenerationDemoViewModel.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class AIGenerationDemoViewModel {
    var prompt: String = ""
    var generatedActions: [Action] = []
    var executionLog: [String] = []
    var isGenerating = false
    var isExecuting = false
    var error: String?

    // MARK: - Backend Selection

    enum Backend: String, CaseIterable, Identifiable {
        case foundationModels = "Foundation Models"
        case openAI = "OpenAI"

        var id: String { rawValue }
    }

    var selectedBackend: Backend = .foundationModels
    var openAIKey: String = ""
    var openAIModel: String = "gpt-4.1-nano"

    static let availableOpenAIModels = [
        "gpt-4.1-nano",
        "gpt-4.1-mini",
        "gpt-4.1",
        "gpt-5-nano",
        "gpt-5-mini",
        "gpt-5",
    ]

    let samplePrompts: [String] = [
        "Click at 300, 400",
        "Type 'Hello, AI!'",
        "Scroll down 5 clicks",
        "Press Command+C to copy",
        "Move to 200, 200, click, wait 0.5 seconds, then type 'test'"
    ]

    func generateActions() async {
        guard !prompt.isEmpty else {
            error = "Please enter a prompt"
            return
        }

        switch selectedBackend {
        case .foundationModels:
            guard ActionGenerator.isAvailable else {
                error = ActionGenerator.unavailableReason ?? "Model is unavailable."
                addToLog("Model unavailable: \(error!)")
                return
            }
        case .openAI:
            guard !openAIKey.isEmpty else {
                error = "Please enter your OpenAI API key."
                return
            }
        }

        isGenerating = true
        error = nil
        generatedActions = []
        executionLog.removeAll()

        do {
            addToLog("Generating actions from prompt...")
            addToLog("Backend: \(selectedBackend.rawValue)")
            addToLog("Prompt: \"\(prompt)\"")

            let actions: [Action]
            switch selectedBackend {
            case .foundationModels:
                actions = try await ActionGenerator.generateActionSequence(from: prompt)
            case .openAI:
                let generator = ActionGenerator(openAIKey: openAIKey, model: openAIModel)
                actions = try await generator.generateActionSequence(from: prompt)
            }

            if actions.isEmpty {
                error = "Could not generate actions from prompt"
                addToLog("No actions generated")
            } else {
                generatedActions = actions
                addToLog("Generated \(actions.count) action(s)")
                for (index, action) in actions.enumerated() {
                    addToLog("  [\(index + 1)] \(actionDescription(for: action))")
                }
            }
        } catch {
            self.error = error.localizedDescription
            addToLog("Error: \(error.localizedDescription)")
        }

        isGenerating = false
    }

    func executeGeneratedActions() async {
        guard !generatedActions.isEmpty else { return }

        isExecuting = true
        addToLog("--- Executing generated actions ---")

        for (index, action) in generatedActions.enumerated() {
            addToLog("Executing [\(index + 1)]: \(actionDescription(for: action))")
            _ = await action.execute()
        }

        addToLog("Execution completed!")
        isExecuting = false
    }

    func clearLog() {
        executionLog.removeAll()
    }

    func useSamplePrompt(_ sample: String) {
        prompt = sample
    }

    private func addToLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        executionLog.append("[\(timestamp)] \(message)")
    }

    func actionDescription(for action: Action) -> String {
        switch action {
        case .keyDown(let key):
            return "Key Down: \(key)"
        case .keyUp(let key):
            return "Key Up: \(key)"
        case .write(let text, let interval):
            return "Write: \"\(text)\" (interval: \(interval)s)"
        case .keyShortcut(let keys):
            return "Shortcut: \(keys.map { "\($0)" }.joined(separator: "+"))"
        case .move(let point):
            return "Move to: (\(Int(point.x)), \(Int(point.y)))"
        case .moveSmooth(let point, let duration, let tweening, _):
            return "Smooth move to: (\(Int(point.x)), \(Int(point.y))) in \(duration)s (\(tweening))"
        case .moveMouse(let dx, let dy):
            return "Move by: (dx: \(dx), dy: \(dy))"
        case .leftClick:
            return "Left Click"
        case .rightClick:
            return "Right Click"
        case .doubleClick(let button):
            return "Double Click (\(button == .left ? "left" : "right"))"
        case .doubleClickAt(let position, let button):
            return "Double Click at (\(Int(position.x)), \(Int(position.y))) (\(button == .left ? "left" : "right"))"
        case .tripleClick(let button):
            return "Triple Click (\(button == .left ? "left" : "right"))"
        case .tripleClickAt(let position, let button):
            return "Triple Click at (\(Int(position.x)), \(Int(position.y))) (\(button == .left ? "left" : "right"))"
        case .drag(let from, let to):
            return "Drag from (\(Int(from.x)), \(Int(from.y))) to (\(Int(to.x)), \(Int(to.y)))"
        case .vscroll(let clicks):
            return "Vertical scroll: \(clicks) clicks"
        case .hscroll(let clicks):
            return "Horizontal scroll: \(clicks) clicks"
        case .smoothVScroll(let clicks, let duration, let tweening, _):
            return "Smooth V-scroll: \(clicks) clicks in \(duration)s (\(tweening))"
        case .smoothHScroll(let clicks, let duration, let tweening, _):
            return "Smooth H-scroll: \(clicks) clicks in \(duration)s (\(tweening))"
        case .screenshot:
            return "Take screenshot"
        case .screenshotRegion(let rect):
            return "Screenshot region: \(rect)"
        case .screenshotToFile(let filename, _):
            return "Screenshot to file: \(filename)"
        case .getScreenSize:
            return "Get screen size"
        case .getPixel(let x, let y):
            return "Get pixel at (\(x), \(y))"
        case .locateOnScreen(let path, _, _, _):
            return "Locate image: \(path)"
        case .locateCenterOnScreen(let path, _, _, _):
            return "Locate image center: \(path)"
        case .locateAllOnScreen(let path, _, _, _):
            return "Locate all images: \(path)"
        case .alert(let message, _, _):
            return "Alert: \(message)"
        case .confirm(let message, _, _):
            return "Confirm: \(message)"
        case .prompt(let message, _, _, _):
            return "Prompt: \(message)"
        case .password(let message, _, _, _):
            return "Password: \(message)"
        case .executeAppleScript(let script):
            return "Execute AppleScript: \(script.prefix(30))..."
        case .executeAppleScriptFile(let path):
            return "Execute AppleScript file: \(path)"
        case .wait(let duration):
            return "Wait \(duration)s"
        case .sequence(let actions):
            return "Sequence with \(actions.count) actions"
        }
    }
}
