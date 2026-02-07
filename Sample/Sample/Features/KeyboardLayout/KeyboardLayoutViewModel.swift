//
//  KeyboardLayoutViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class KeyboardLayoutViewModel {
    var selectedLayout: KeyboardLayout = SwiftAutoGUI.currentLayout
    var textToType: String = ""
    var typingSpeed: Double = 0.0
    var statusMessage: String = ""
    var targetTextField: String = ""
    var isTargetFieldFocused: Bool = false

    var detectedLayout: KeyboardLayout {
        KeyboardLayout.detect()
    }

    /// Character mapping comparison table data
    var comparisonCharacters: [Character] {
        let chars: [Character] = [
            "@", "[", "]", ":", "^", "\"", "&", "'",
            "(", ")", "=", "~", "`", "+", "*", "_",
            "\\", "{", "}", "|"
        ]
        return chars
    }

    func mappingDescription(for character: Character, layout: KeyboardLayout) -> String {
        guard let mapping = layout.mapping(for: character) else {
            return "-"
        }
        let keyName = mapping.key.rawValue
        if mapping.needsShift {
            return "Shift + .\(keyName)"
        }
        return ".\(keyName)"
    }

    func applyLayout() {
        SwiftAutoGUI.currentLayout = selectedLayout
        statusMessage = "Layout set to \(selectedLayout.rawValue.uppercased())"
    }

    func resetToAutoDetect() {
        SwiftAutoGUI.resetLayoutToAutoDetect()
        selectedLayout = SwiftAutoGUI.currentLayout
        statusMessage = "Reset to auto-detect (detected: \(detectedLayout.rawValue.uppercased()))"
    }

    func typeText(_ text: String) {
        guard !text.isEmpty else {
            statusMessage = "Please enter some text to type"
            return
        }

        statusMessage = "Typing with \(SwiftAutoGUI.currentLayout.rawValue.uppercased()) layout..."

        Task {
            let actions: [Action] = [
                .wait(1.0),
                .write(text, interval: typingSpeed)
            ]
            await actions.execute()
            statusMessage = "Typed: \"\(text)\" with \(SwiftAutoGUI.currentLayout.rawValue.uppercased()) layout"
        }
    }

    func typeCustomText() {
        typeText(textToType)
    }

    func focusAndTypeInTargetField() {
        guard !textToType.isEmpty else {
            statusMessage = "Please enter some text to type"
            return
        }

        targetTextField = ""
        isTargetFieldFocused = true
        statusMessage = "Focusing target field and typing with \(SwiftAutoGUI.currentLayout.rawValue.uppercased()) layout..."

        Task {
            let actions: [Action] = [
                .wait(0.5),
                .selectAll(),
                .wait(0.1),
                .keyDown(.delete),
                .keyUp(.delete),
                .wait(0.1),
                .write(textToType, interval: typingSpeed)
            ]
            await actions.execute()
            statusMessage = "Typed in target field: \"\(textToType)\" with \(SwiftAutoGUI.currentLayout.rawValue.uppercased()) layout"
        }
    }
}
