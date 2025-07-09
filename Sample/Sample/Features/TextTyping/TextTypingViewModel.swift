//
//  TextTypingViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

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
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await SwiftAutoGUI.write(text, interval: typingSpeed)
        typingStatus = "✅ Completed typing: \"\(text)\""
    }
    
    @MainActor
    private func performFocusAndType() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        SwiftAutoGUI.sendKeyShortcut([.command, .a])
        try? await Task.sleep(nanoseconds: 100_000_000)
        SwiftAutoGUI.keyDown(.delete)
        SwiftAutoGUI.keyUp(.delete)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await SwiftAutoGUI.write(textToType, interval: typingSpeed)
        typingStatus = "✅ Focused and typed in target field: \"\(textToType)\""
    }
}