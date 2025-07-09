//
//  TextTypingView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct TextTypingView: View {
    @StateObject private var viewModel = TextTypingViewModel()
    @FocusState private var isTargetFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text Typing Demo")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Enter text to type:")
                    .font(.caption)
                TextField("Type your message here...", text: $viewModel.textToType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Target Text Field (click button to auto-focus and type here):")
                    .font(.caption)
                TextField("Text will appear here...", text: $viewModel.targetTextField)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(viewModel.isTargetFieldFocused ? Color.blue.opacity(0.1) : Color.clear)
                    .focused($isTargetFieldFocused)
                    .onChange(of: viewModel.isTargetFieldFocused) { newValue in
                        isTargetFieldFocused = newValue
                    }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Typing Speed: \(String(format: "%.1f", viewModel.typingSpeed))s interval")
                    .font(.caption)
                Slider(value: $viewModel.typingSpeed, in: 0.0...1.0, step: 0.1)
                    .frame(maxWidth: 200)
            }
            
            Button("Type Custom Text") {
                viewModel.typeCustomText()
            }
            .disabled(viewModel.textToType.isEmpty)
            
            Button("Focus Target Field & Type") {
                viewModel.focusAndTypeInTargetField()
            }
            .disabled(viewModel.textToType.isEmpty)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            
            HStack {
                Button("\"Hello, World!\"") {
                    viewModel.typeText("Hello, World!")
                }
                
                Button("\"Test123!@#\"") {
                    viewModel.typeText("Test123!@#")
                }
            }
            
            HStack {
                Button("\"The quick brown fox...\"") {
                    viewModel.typeText("The quick brown fox jumps over the lazy dog")
                }
                
                Button("Multi-line Text") {
                    viewModel.typeText("Line 1\nLine 2\nLine 3")
                }
            }
            
            if !viewModel.typingStatus.isEmpty {
                Text(viewModel.typingStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}