//
//  DialogDemoView.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/07/12.
//

import SwiftUI
import SwiftAutoGUI

struct DialogDemoView: View {
    @State private var viewModel = DialogDemoViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title and description
            VStack(alignment: .leading, spacing: 8) {
                Label("Dialog Boxes", systemImage: "message")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Display dialog boxes for user interaction during automation")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Alert Demo
            DemoSection(
                title: "Alert Dialog",
                description: "Display a simple alert with a message"
            ) {
                Button("Show Alert") {
                    Task {
                        await viewModel.showAlert()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if let result = viewModel.alertResult {
                    ResultView(label: "Result", value: result)
                }
            }
            
            // Confirm Demo
            DemoSection(
                title: "Confirmation Dialog",
                description: "Ask for user confirmation with custom buttons"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Show Default Confirm") {
                        Task {
                            await viewModel.showDefaultConfirm()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Show Custom Confirm") {
                        Task {
                            await viewModel.showCustomConfirm()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if let result = viewModel.confirmResult {
                        ResultView(label: "Selected", value: result)
                    }
                }
            }
            
            // Prompt Demo
            DemoSection(
                title: "Text Input Dialog",
                description: "Get text input from the user"
            ) {
                Button("Show Prompt") {
                    Task {
                        await viewModel.showPrompt()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if let result = viewModel.promptResult {
                    ResultView(label: "Input", value: result)
                }
            }
            
            // Password Demo
            DemoSection(
                title: "Password Dialog",
                description: "Securely get password input"
            ) {
                Button("Show Password Dialog") {
                    Task {
                        await viewModel.showPassword()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if let result = viewModel.passwordResult {
                    ResultView(label: "Password", value: String(repeating: "•", count: result.count))
                }
            }
            
            Spacer()
        }
    }
}

struct DemoSection<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct ResultView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.2))
                )
        }
    }
}