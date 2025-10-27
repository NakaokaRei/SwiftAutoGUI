//
//  TextTypingViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
class TextTypingViewModel: ObservableObject {
    @Published var textToType: String = ""
    @Published var typingSpeed: Double = 0.0
    @Published var typingStatus: String = ""
    @Published var targetTextField: String = ""
    @Published var isTargetFieldFocused: Bool = false
    
    func typeText(_ text: String) {
        guard !text.isEmpty else {
            typingStatus = "Please enter some text to type"
            return
        }
        
        typingStatus = "Typing: \"\(text)\" (speed: \(String(format: "%.1f", typingSpeed))s interval)"
        
        Task {
            await performTyping(text: text)
        }
    }
    
    func typeCustomText() {
        typeText(textToType)
    }
    
    func focusAndTypeInTargetField() {
        guard !textToType.isEmpty else {
            typingStatus = "Please enter some text to type"
            return
        }
        
        targetTextField = ""
        isTargetFieldFocused = true
        typingStatus = "Focusing target field and typing..."
        
        Task {
            await performFocusAndType()
        }
    }
    
    @MainActor
    private func performTyping(text: String) async {
        let actions: [Action] = [
            .wait(1.0),
            .write(text, interval: typingSpeed)
        ]
        await actions.execute()
        typingStatus = "✅ Completed typing: \"\(text)\""
    }
    
    @MainActor
    private func performFocusAndType() async {
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
        typingStatus = "✅ Focused and typed in target field: \"\(textToType)\""
    }
}