//
//  ActionsDemoViewModel.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/01/16.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
class ActionsDemoViewModel: ObservableObject {
    @Published var executionLog: [String] = []
    @Published var isExecuting = false
    @Published var selectedExample = ActionExample.mouseClick
    
    enum ActionExample: String, CaseIterable {
        case mouseClick = "Mouse Click"
        case typeText = "Type Text"
        case keyboardShortcut = "Keyboard Shortcut"
        case mouseMovement = "Mouse Movement"
        case scrolling = "Scrolling"
        
        var description: String {
            switch self {
            case .mouseClick:
                return "Move mouse and perform clicks"
            case .typeText:
                return "Type text using keyboard"
            case .keyboardShortcut:
                return "Execute keyboard shortcuts"
            case .mouseMovement:
                return "Move mouse to different positions"
            case .scrolling:
                return "Scroll vertically and horizontally"
            }
        }
        
        var actions: [Action] {
            switch self {
            case .mouseClick:
                return [
                    .move(to: CGPoint(x: 400, y: 400)),
                    .wait(0.5),
                    .leftClick,
                    .wait(0.5),
                    .doubleClick(),
                    .wait(0.5),
                    .rightClick
                ]
                
            case .typeText:
                return [
                    .write("Hello, SwiftAutoGUI!", interval: 0.05),
                    .wait(0.5),
                    .keyShortcut([.returnKey]),
                    .write("This is an Action demo.", interval: 0.05)
                ]
                
            case .keyboardShortcut:
                return [
                    Action.selectAll(),
                    .wait(0.3),
                    Action.copy(),
                    .wait(0.3),
                    Action.paste(),
                    .wait(0.3),
                    Action.undo()
                ]
                
            case .mouseMovement:
                return [
                    .move(to: CGPoint(x: 100, y: 100)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 500, y: 100)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 500, y: 500)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 100, y: 500)),
                    .wait(0.5),
                    .move(to: CGPoint(x: 300, y: 300))
                ]
                
            case .scrolling:
                return [
                    .vscroll(clicks: -5),
                    .wait(0.5),
                    .vscroll(clicks: 5),
                    .wait(0.5),
                    .hscroll(clicks: -3),
                    .wait(0.5),
                    .hscroll(clicks: 3)
                ]
            }
        }
    }
    
    func executeActions() async {
        isExecuting = true
        addToLog("Starting action execution...")
        
        for (index, action) in selectedExample.actions.enumerated() {
            addToLog("[\(index + 1)] Executing: \(actionDescription(for: action))")
            _ = await action.execute()
        }
        
        addToLog("Execution completed!")
        isExecuting = false
    }
    
    func clearLog() {
        executionLog.removeAll()
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
        case .move(let to):
            return "Move to: (\(Int(to.x)), \(Int(to.y)))"
        case .moveSmooth(let to, let duration, let tweening, _):
            return "Smooth move to: (\(Int(to.x)), \(Int(to.y))) in \(duration)s (\(tweening))"
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
        case .screenshotRegion(let region):
            return "Screenshot region: \(region)"
        case .screenshotToFile(let filename, let region):
            return "Screenshot to file: \(filename)\(region != nil ? " (region)" : "")"
        case .getScreenSize:
            return "Get screen size"
        case .getPixel(let x, let y):
            return "Get pixel at (\(x), \(y))"
        case .locateOnScreen(_, let grayscale, let confidence, let region):
            return "Locate image (grayscale: \(grayscale), confidence: \(confidence))\(region != nil ? " in region" : "")"
        case .locateCenterOnScreen(_, let grayscale, let confidence, let region):
            return "Locate image center (grayscale: \(grayscale), confidence: \(confidence))\(region != nil ? " in region" : "")"
        case .locateAllOnScreen(_, let grayscale, let confidence, let region):
            return "Locate all images (grayscale: \(grayscale), confidence: \(confidence))\(region != nil ? " in region" : "")"
        case .alert(let text, let title, let button):
            return "Alert: \"\(title)\" - \(text) [\(button)]"
        case .confirm(let text, let title, let buttons):
            return "Confirm: \"\(title)\" - \(text) \(buttons)"
        case .prompt(let text, let title, _, let button):
            return "Prompt: \"\(title)\" - \(text) [\(button)]"
        case .password(let text, let title, _, let button):
            return "Password: \"\(title)\" - \(text) [\(button)]"
        case .executeAppleScript(let script):
            return "Execute AppleScript: \(script.prefix(30))..."
        case .executeAppleScriptFile(let path):
            return "Execute AppleScript file: \(path)"
        case .wait(let interval):
            return "Wait \(interval)s"
        case .sequence(let actions):
            return "Sequence with \(actions.count) actions"
        }
    }
}