//
//  TextTypingView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct TextTypingView: View {
    @State private var viewModel = TextTypingViewModel()
    @FocusState private var isTargetFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Text Typing Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Automate text input with customizable speed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Enter text to type:", systemImage: "keyboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Type your message here...", text: $viewModel.textToType)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Target Text Field", systemImage: "text.cursor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Text will appear here...", text: $viewModel.targetTextField)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isTargetFieldFocused 
                                ? Color.blue.opacity(0.15) 
                                : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isTargetFieldFocused 
                                ? Color.blue 
                                : Color.blue.opacity(0.3), lineWidth: viewModel.isTargetFieldFocused ? 2 : 1)
                    )
                    .focused($isTargetFieldFocused)
                    .onChange(of: viewModel.isTargetFieldFocused) { newValue in
                        isTargetFieldFocused = newValue
                    }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Typing Speed", systemImage: "speedometer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", viewModel.typingSpeed))s interval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $viewModel.typingSpeed, in: 0.0...1.0, step: 0.1)
                    .tint(.blue)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Type Custom Text") {
                        viewModel.typeCustomText()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.textToType.isEmpty)
                    
                    Button("Focus Target Field & Type") {
                        viewModel.focusAndTypeInTargetField()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.textToType.isEmpty)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("Quick Actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button("Hello, World!") {
                        viewModel.typeText("Hello, World!")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Test123!@#") {
                        viewModel.typeText("Test123!@#")
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack(spacing: 12) {
                    Button("The quick brown fox...") {
                        viewModel.typeText("The quick brown fox jumps over the lazy dog")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Multi-line") {
                        viewModel.typeText("Line 1\nLine 2\nLine 3")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if !viewModel.typingStatus.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text(viewModel.typingStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
    }
}