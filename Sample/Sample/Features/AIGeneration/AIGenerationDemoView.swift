//
//  AIGenerationDemoView.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

struct AIGenerationDemoView: View {
    @State private var viewModel = AIGenerationDemoViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("AI Action Generation")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("Generate automation actions from natural language prompts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Backend Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Backend")
                    .font(.headline)

                Picker("Backend", selection: $viewModel.selectedBackend) {
                    ForEach(AIGenerationDemoViewModel.Backend.allCases) { backend in
                        Text(backend.rawValue).tag(backend)
                    }
                }
                .pickerStyle(.segmented)

                // OpenAI Settings
                if viewModel.selectedBackend == .openAI {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("OpenAI API Key", text: $viewModel.openAIKey)
                            .textFieldStyle(.roundedBorder)

                        Picker("Model", selection: $viewModel.openAIModel) {
                            ForEach(AIGenerationDemoViewModel.availableOpenAIModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.08))
                    )
                }
            }

            // Input Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Prompt")
                    .font(.headline)

                TextEditor(text: $viewModel.prompt)
                    .frame(height: 80)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                // Sample Prompts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample Prompts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.samplePrompts, id: \.self) { sample in
                                Button(action: {
                                    viewModel.useSamplePrompt(sample)
                                }) {
                                    Text(sample)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.purple.opacity(0.1)))
                                        .foregroundColor(.purple)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        Task { await viewModel.generateActions() }
                    }) {
                        HStack {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(viewModel.isGenerating ? "Generating..." : "Generate Actions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.purple))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isGenerating || viewModel.prompt.isEmpty)
                    .opacity(viewModel.prompt.isEmpty ? 0.5 : 1.0)

                    if !viewModel.generatedActions.isEmpty {
                        Button(action: {
                            Task { await viewModel.executeGeneratedActions() }
                        }) {
                            HStack {
                                if viewModel.isExecuting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(viewModel.isExecuting ? "Executing..." : "Execute")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isExecuting)
                    }
                }

                // Error Message
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                }
            }

            // Generated Actions
            if !viewModel.generatedActions.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Actions (\(viewModel.generatedActions.count))")
                        .font(.headline)

                    ForEach(Array(viewModel.generatedActions.enumerated()), id: \.offset) { index, action in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.purple))

                            Text(viewModel.actionDescription(for: action))
                                .font(.caption)

                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    }
                }
            }

            // Execution Log
            if !viewModel.executionLog.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Execution Log")
                            .font(.headline)
                        Spacer()
                        Button("Clear") { viewModel.clearLog() }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.executionLog, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
}

struct AIGenerationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AIGenerationDemoView()
            .frame(width: 800, height: 600)
    }
}
