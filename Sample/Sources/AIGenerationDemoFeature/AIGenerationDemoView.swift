//
//  AIGenerationDemoView.swift
//  Sample
//

import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

public struct AIGenerationDemoView: View {
    public init() {}
    @State private var store = Store(initialState: AIGenerationDemoFeature.State()) {
        AIGenerationDemoFeature()
    }
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        @Bindable var store = self.store
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

                Picker("Backend", selection: $store.selectedBackend) {
                    ForEach(AIGenerationDemoFeature.Backend.allCases) { backend in
                        Text(backend.rawValue).tag(backend)
                    }
                }
                .pickerStyle(.segmented)

                if store.selectedBackend == .pcc {
                    Text(
                        "Sends prompts to Apple. Requires an eligible, entitled app and available daily quota."
                    )
                    .font(.caption).foregroundStyle(.secondary)
                }
                // OpenAI Settings
                if store.selectedBackend == .openAI {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("OpenAI API Key", text: $store.openAIKey)
                            .textFieldStyle(.roundedBorder)

                        Picker("Model", selection: $store.openAIModel) {
                            ForEach(AIGenerationDemoFeature.availableOpenAIModels, id: \.self) {
                                model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                colorScheme == .dark
                                    ? Color.gray.opacity(0.15) : Color.gray.opacity(0.08))
                    )
                }
            }

            // Input Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Prompt")
                    .font(.headline)

                TextEditor(text: $store.prompt)
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
                            ForEach(AIGenerationDemoFeature.samplePrompts, id: \.self) { sample in
                                Button(action: {
                                    store.send(.useSamplePrompt(sample))
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
                        store.send(.generateActions)
                    }) {
                        HStack {
                            if store.isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(store.isGenerating ? "Generating..." : "Generate Actions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.purple))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isGenerating || store.prompt.isEmpty)
                    .opacity(store.prompt.isEmpty ? 0.5 : 1.0)

                    if !store.generatedActions.isEmpty {
                        Button(action: {
                            store.send(.executeGeneratedActions)
                        }) {
                            HStack {
                                if store.isExecuting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(store.isExecuting ? "Executing..." : "Execute")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isExecuting)
                    }
                }

                // Error Message
                if let error = store.error {
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
            if !store.generatedActions.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Actions (\(store.generatedActions.count))")
                        .font(.headline)

                    ForEach(Array(store.generatedActions.enumerated()), id: \.offset) {
                        index, action in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.purple))

                            Text(action)
                                .font(.caption)

                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    colorScheme == .dark
                                        ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    }
                }
            }

            // Execution Log
            if !store.executionLog.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Execution Log")
                            .font(.headline)
                        Spacer()
                        Button("Clear") { store.send(.clearLog) }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(store.executionLog, id: \.self) { log in
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
                            .fill(
                                colorScheme == .dark
                                    ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
        .onDisappear { store.send(.stop) }
    }
}

struct AIGenerationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AIGenerationDemoView()
            .frame(width: 800, height: 600)
    }
}
