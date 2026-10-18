//
//  ScreenContextDemoView.swift
//  Sample
//

import ComposableArchitecture
import SampleSupport
import SwiftAutoGUI
import SwiftUI

public struct ScreenContextDemoView: View {
    public init() {}
    @State private var store = Store(initialState: ScreenContextFeature.State()) {
        ScreenContextFeature()
    }
    @State private var showOptions = false
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
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

                if let context = store.context {
                    HStack(spacing: 12) {
                        badge("\(context.visibleWindows.count) windows", icon: "macwindow")
                        badge("\(store.nodeCount) nodes", icon: "list.bullet.indent")
                        badge("\(store.actionableElementCount) actionable", icon: "scope")
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
                Button(action: { store.send(.gather) }) {
                    Label("Capture", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(store.isLoading)

                Toggle(
                    isOn: Binding(
                        get: { store.autoRefresh },
                        set: { newValue in
                            if newValue {
                                store.send(.startAutoRefresh)
                            } else {
                                store.send(.stopAutoRefresh)
                            }
                        }
                    )
                ) {
                    Label("Auto-refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)

                if store.autoRefresh {
                    Text("every \(String(format: "%.1f", store.refreshInterval))s")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if store.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if store.formattedOutput.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    elementActionObserver
                    contextDisplay
                }
            }
        }
        .onDisappear { store.send(.stop) }
    }

    // MARK: - Options

    @ViewBuilder
    private var optionsContent: some View {
        @Bindable var store = self.store
        HStack(spacing: 24) {
            HStack(spacing: 4) {
                Text("Max depth:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $store.maxDepth, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
            }
            HStack(spacing: 4) {
                Text("Max nodes:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $store.maxNodes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            HStack(spacing: 4) {
                Text("Max value length:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", value: $store.maxValueLength, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
            }
            Toggle(isOn: $store.includeAXTree) {
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

    @ViewBuilder
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

    @ViewBuilder
    private var elementActionObserver: some View {
        @Bindable var store = self.store
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Element Action Observer", systemImage: "scope")
                    .font(.headline)
                Spacer()
                if store.isExecuting { ProgressView().scaleEffect(0.7) }
            }

            Text(
                "Choose a [#N] identifier from the AX tree below. Actions are resolved against the captured hierarchy and rejected if the element became stale."
            )
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text("Element #")
                    .font(.caption)
                TextField("ID", value: $store.selectedElementID, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Button("Press") { store.send(.pressSelectedElement) }
                    .disabled(store.isExecuting)

                Divider().frame(height: 20)

                TextField("Value", text: $store.elementValue)
                    .textFieldStyle(.roundedBorder)
                Button("Set Value") { store.send(.setSelectedElementValue) }
                    .disabled(store.isExecuting)
            }

            Text(store.executionLog)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.3) : Color.gray.opacity(0.06))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.teal.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.teal.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var contextDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Summary cards
            if let context = store.context {
                summaryCards(context)
            }

            // Formatted output
            VStack(alignment: .leading, spacing: 4) {
                Text("Formatted Output (sent to LLM)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(store.formattedOutput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.3) : Color.gray.opacity(0.06))
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
                    ForEach(Array(context.visibleWindows.prefix(5).enumerated()), id: \.offset) {
                        _, window in
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
                        Text("\(store.nodeCount) nodes")
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

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
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
