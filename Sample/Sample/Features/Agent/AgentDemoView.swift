//
//  AgentDemoView.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

struct AgentDemoView: View {
    @State private var viewModel = AgentDemoViewModel()
    @State private var showSettings = true
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .font(.title)
                    .foregroundColor(.indigo)
                Text("AI Agent")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()

                if !viewModel.steps.isEmpty || viewModel.isRunning {
                    statusBadge
                }
            }

            // Settings (collapsible)
            DisclosureGroup(isExpanded: $showSettings) {
                settingsContent
                    .padding(.top, 8)
            } label: {
                Text("Settings")
                    .font(.headline)
            }

            // Goal + Controls
            goalAndControls

            // Error
            if let error = viewModel.error {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
            }

            // Steps table
            if !viewModel.steps.isEmpty {
                stepsTable
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            if viewModel.isRunning {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                Text("Step \(viewModel.steps.count + 1)/\(viewModel.maxIterations)")
                    .font(.caption2)
                    .fontWeight(.medium)
            } else if let completed = viewModel.completed {
                Image(systemName: completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(completed ? .green : .orange)
                    .font(.caption)
                Text(completed ? "Done" : "Limit reached")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.12)))
    }

    // MARK: - Settings

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                SecureField("OpenAI API Key", text: $viewModel.openAIKey)
                    .textFieldStyle(.roundedBorder)

                Picker("Model", selection: $viewModel.openAIModel) {
                    ForEach(AgentDemoViewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }

            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Text("Max iterations:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("", value: $viewModel.maxIterations, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
                HStack(spacing: 4) {
                    Text("Delay:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("", value: $viewModel.delayBetweenSteps, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    Text("s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Toggle(isOn: $viewModel.useScreenContext) {
                    Text("Screen context")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.checkbox)
                .help("Send accessibility tree and window info alongside screenshots")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.06))
        )
    }

    // MARK: - Goal + Controls

    private var goalAndControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Goal input row
            HStack(spacing: 8) {
                TextEditor(text: $viewModel.goal)
                    .frame(height: 44)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                if viewModel.isRunning {
                    Button(action: { viewModel.stopAgent() }) {
                        Image(systemName: "stop.fill")
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.red))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        showSettings = false
                        viewModel.startAgent()
                    }) {
                        Image(systemName: "play.fill")
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 8).fill(
                                viewModel.goal.isEmpty || viewModel.openAIKey.isEmpty ? Color.gray : Color.indigo
                            ))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.goal.isEmpty || viewModel.openAIKey.isEmpty)
                }
            }

            // Sample goals
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.sampleGoals, id: \.self) { sample in
                        Button(action: { viewModel.useSampleGoal(sample) }) {
                            Text(sample)
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.indigo.opacity(0.1)))
                                .foregroundColor(.indigo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Steps Table

    private var stepsTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table header
            HStack {
                Text("Steps (\(viewModel.steps.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !viewModel.isRunning {
                    Button("Clear") { viewModel.clearResults() }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, 6)

            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 28, alignment: .center)
                Text("Reasoning")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)
                Text("Actions")
                    .frame(width: 220, alignment: .leading)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))

            // Rows in a fixed-height scrollable area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.steps) { step in
                            stepRow(step)
                                .id(step.id)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 240)
                .onChange(of: viewModel.steps.count) {
                    if let last = viewModel.steps.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.03))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func stepRow(_ step: AgentDemoViewModel.StepDisplay) -> some View {
        HStack(spacing: 0) {
            Text("\(step.number)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.indigo))
                .frame(width: 28)

            Text(step.reasoning)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)

            Text(step.actions)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: 220, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
    }
}

struct AgentDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AgentDemoView()
            .frame(width: 800, height: 600)
    }
}
