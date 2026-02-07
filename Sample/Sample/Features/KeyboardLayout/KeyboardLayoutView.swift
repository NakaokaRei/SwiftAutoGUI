//
//  KeyboardLayoutView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

struct KeyboardLayoutView: View {
    @State private var viewModel = KeyboardLayoutViewModel()
    @FocusState private var isTargetFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard Layout Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Switch between US and JIS keyboard layouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Layout selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Detected Layout", systemImage: "globe")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(viewModel.detectedLayout.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.2))
                        )
                }

                HStack(spacing: 12) {
                    Picker("Layout", selection: $viewModel.selectedLayout) {
                        Text("US").tag(KeyboardLayout.us)
                        Text("JIS").tag(KeyboardLayout.jis)
                    }
                    .pickerStyle(.segmented)

                    Button("Apply") {
                        viewModel.applyLayout()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Auto Detect") {
                        viewModel.resetToAutoDetect()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Mapping comparison table
            VStack(alignment: .leading, spacing: 8) {
                Label("Symbol Key Mapping Comparison", systemImage: "tablecells")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            Text("Char")
                                .frame(width: 50, alignment: .center)
                                .fontWeight(.semibold)
                            Text("US Layout")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(.semibold)
                            Text("JIS Layout")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.15))

                        ForEach(Array(viewModel.comparisonCharacters.enumerated()), id: \.offset) { index, char in
                            let usDesc = viewModel.mappingDescription(for: char, layout: .us)
                            let jisDesc = viewModel.mappingDescription(for: char, layout: .jis)
                            let isDifferent = usDesc != jisDesc

                            HStack(spacing: 0) {
                                Text(String(char))
                                    .frame(width: 50, alignment: .center)
                                    .fontWeight(.medium)
                                    .font(.system(.caption, design: .monospaced))
                                Text(usDesc)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(.caption2, design: .monospaced))
                                Text(jisDesc)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(isDifferent ? .orange : .primary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                index % 2 == 0
                                    ? Color.clear
                                    : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.05))
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .frame(maxHeight: 200)
            }

            Divider()

            // Text typing with layout
            VStack(alignment: .leading, spacing: 12) {
                Label("Type with current layout:", systemImage: "keyboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Enter text with symbols...", text: $viewModel.textToType)
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

                HStack(spacing: 12) {
                    Button("Type Custom Text") {
                        viewModel.typeCustomText()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.textToType.isEmpty)

                    Button("Focus & Type") {
                        viewModel.focusAndTypeInTargetField()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.textToType.isEmpty)
                }

                Text("Quick Actions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button("@[]:^~") {
                        viewModel.typeText("@[]:^~")
                    }
                    .buttonStyle(.bordered)

                    Button("{}|\"'`") {
                        viewModel.typeText("{}|\"'`")
                    }
                    .buttonStyle(.bordered)

                    Button("_=+*&\\") {
                        viewModel.typeText("_=+*&\\")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Status
            if !viewModel.statusMessage.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text(viewModel.statusMessage)
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
