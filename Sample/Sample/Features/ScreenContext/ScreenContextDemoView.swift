//
//  ScreenContextDemoView.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

struct ScreenContextDemoView: View {
    @State private var viewModel = ScreenContextViewModel()
    @State private var showOptions = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "accessibility")
                    .font(.title)
                    .foregroundColor(.teal)
                Text("Screen Context")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()

                if let context = viewModel.context {
                    HStack(spacing: 12) {
                        badge("\(context.visibleWindows.count) windows", icon: "macwindow")
                        badge("\(viewModel.nodeCount) nodes", icon: "list.bullet.indent")
                    }
                }
            }

            // Options (collapsible)
            DisclosureGroup(isExpanded: $showOptions) {
                optionsContent
                    .padding(.top, 8)
            } label: {
                Text("Options")
                    .font(.headline)
            }

            // Controls
            HStack(spacing: 8) {
                Button(action: { viewModel.gather() }) {
                    Label("Capture", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(viewModel.isLoading)

                Toggle(isOn: Binding(
                    get: { viewModel.autoRefresh },
                    set: { newValue in
                        if newValue {
                            viewModel.startAutoRefresh()
                        } else {
                            viewModel.stopAutoRefresh()
                        }
                    }
                )) {
                    Label("Auto-refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)

                if viewModel.autoRefresh {
                    Text("every \(String(format: "%.1f", viewModel.refreshInterval))s")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if viewModel.formattedOutput.isEmpty {
                emptyState
            } else {
                contextDisplay
            }
        }
    }

    // MARK: - Options

    private var optionsContent: some View {
        HStack(spacing: 24) {
            HStack(spacing: 4) {
                Text("Max depth:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $viewModel.maxDepth, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
            }
            HStack(spacing: 4) {
                Text("Max nodes:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $viewModel.maxNodes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            HStack(spacing: 4) {
                Text("Max value length:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $viewModel.maxValueLength, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
            }
            Toggle(isOn: $viewModel.includeAXTree) {
                Text("AX Tree")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.checkbox)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.06))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Press Capture to gather screen context")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Context Display

    private var contextDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary cards
            if let context = viewModel.context {
                summaryCards(context)
            }

            // Formatted output
            VStack(alignment: .leading, spacing: 4) {
                Text("Formatted Output (sent to LLM)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(viewModel.formattedOutput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Summary Cards

    private func summaryCards(_ context: ScreenContext) -> some View {
        HStack(spacing: 12) {
            // Frontmost app card
            if let app = context.frontmostApp {
                card(title: "Frontmost App") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                        if let bundle = app.bundleIdentifier {
                            Text(bundle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("PID: \(app.pid)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Windows card
            card(title: "Visible Windows (\(context.visibleWindows.count))") {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(context.visibleWindows.prefix(5).enumerated()), id: \.offset) { _, window in
                        HStack(spacing: 4) {
                            Text(window.title ?? "(untitled)")
                                .font(.caption2)
                                .lineLimit(1)
                            Text("- \(window.ownerApp)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if context.visibleWindows.count > 5 {
                        Text("... +\(context.visibleWindows.count - 5) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // AX Tree card
            card(title: "AX Tree") {
                if let tree = context.focusedWindowAXTree {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Root: \(tree.role)")
                            .font(.caption2)
                        if let label = tree.label {
                            Text("\"\(label)\"")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("\(viewModel.nodeCount) nodes")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Not available")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private func badge(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.teal.opacity(0.15)))
        .foregroundColor(.teal)
    }
}

struct ScreenContextDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenContextDemoView()
            .frame(width: 800, height: 600)
    }
}
