import ComposableArchitecture
import SampleSupport
import SwiftAutoGUIBrowser
import SwiftUI

public struct BrowserDemoView: View {
    public init() {}
    @State private var store = Store(initialState: BrowserDemoFeature.State()) {
        BrowserDemoFeature()
    }
    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            setupNote
            connectionControls

            if store.isConnected {
                browserControls
                agentControls
                actionControls
            }

            status

            if store.formattedOutput.isEmpty {
                emptyState
            } else {
                selectorMap
            }
        }
        .onDisappear { store.send(.stop) }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: "network")
                .font(.title)
                .foregroundColor(.indigo)
            Text("Chromium CDP")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            if store.isConnected {
                badge("Connected", icon: "checkmark.circle.fill", color: .green)
                badge("\(store.tabs.count) tabs", icon: "rectangle.on.rectangle", color: .indigo)
                badge(
                    "\(store.observation?.elements.count ?? 0) elements", icon: "scope",
                    color: .orange)
            }
        }
    }

    @ViewBuilder
    private var setupNote: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Browser-only demo", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            Text(
                "This tab controls Chromium pages through CDP. It never falls back to macOS Accessibility or CGEvent input."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            Text(
                "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/swiftautogui-cdp-profile"
            )
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
            Text(
                "Use a dedicated profile. Allowlisted cross-origin navigation is approved for this demo; navigation outside the list and all downloads are denied."
            )
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.indigo.opacity(0.08)))
    }

    @ViewBuilder
    private var connectionControls: some View {
        @Bindable var store = self.store
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Endpoint")
                    .font(.caption)
                    .frame(width: 88, alignment: .leading)
                TextField("http://127.0.0.1:9222", text: $store.endpoint)
                    .textFieldStyle(.roundedBorder)
                    .disabled(store.isConnected || store.isAgentRunning)
            }
            HStack(spacing: 8) {
                Text("Domains")
                    .font(.caption)
                    .frame(width: 88, alignment: .leading)
                TextField("example.com, *.example.org", text: $store.allowedDomains)
                    .textFieldStyle(.roundedBorder)
                    .disabled(store.isConnected || store.isAgentRunning)
                if store.isConnected {
                    Button("Disconnect") { store.send(.disconnect) }
                        .disabled(store.isAgentRunning)
                } else {
                    Button("Connect") { store.send(.connect) }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                }
            }
        }
    }

    @ViewBuilder
    private var browserControls: some View {
        HStack(spacing: 8) {
            Text("Tab")
                .font(.caption)
            Picker(
                "Tab",
                selection: Binding(
                    get: { store.selectedTabID },
                    set: { store.send(.selectTab($0)) }
                )
            ) {
                ForEach(store.tabs, id: \.id) { tab in
                    Text(tabLabel(tab)).tag(tab.id)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Button {
                store.send(.refreshTabs)
            } label: {
                Label("Refresh Tabs", systemImage: "arrow.clockwise")
            }
            Button {
                store.send(.capture)
            } label: {
                Label("Observe", systemImage: "eye")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .disabled(store.isWorking || store.isAgentRunning)
    }

    @ViewBuilder
    private var agentControls: some View {
        @Bindable var store = self.store
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Browser AI Agent", systemImage: "brain.head.profile")
                    .font(.headline)
                Spacer()
                if store.isAgentRunning {
                    ProgressView().controlSize(.small)
                    Text("Step \(store.agentSteps.count + 1)/\(store.maxAgentIterations)")
                        .font(.caption2)
                } else if let completed = store.agentCompleted {
                    Label(
                        completed ? "Done" : "Limit reached",
                        systemImage: completed
                            ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .font(.caption2)
                    .foregroundColor(completed ? .green : .orange)
                }
            }

            Text(
                "The Agent observes the selected page, asks the selected model for semantic actions, and executes them only through this CDP session."
            )
            .font(.caption)
            .foregroundColor(.secondary)

            Picker("AI provider", selection: $store.provider) {
                ForEach(AIProviderChoice.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .disabled(store.isAgentRunning)
            Text(store.provider.explanation).font(.caption).foregroundStyle(.secondary)
            if store.provider == .openAI {
                HStack(spacing: 8) {
                    SecureField("OpenAI API Key or OPENAI_API_KEY", text: $store.openAIKey)
                        .textFieldStyle(.roundedBorder)
                    Picker("Model", selection: $store.openAIModel) {
                        ForEach(BrowserDemoFeature.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
                .disabled(store.isAgentRunning)
            }

            HStack(spacing: 8) {
                TextEditor(text: $store.agentGoal)
                    .font(.body)
                    .frame(height: 48)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.045))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.primary.opacity(0.12)))
                    .disabled(store.isAgentRunning)

                if store.isAgentRunning {
                    Button {
                        store.send(.stopAgent)
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button {
                        store.send(.startAgent)
                    } label: {
                        Label("Run Agent", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(
                        store.agentGoal.isEmpty
                            || (store.provider == .openAI && store.openAIKey.isEmpty))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BrowserDemoFeature.sampleAgentGoals, id: \.self) { goal in
                        Button(goal) { store.agentGoal = goal }
                            .buttonStyle(.plain)
                            .font(.caption2)
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.indigo.opacity(0.1)))
                    }
                }
            }
            .disabled(store.isAgentRunning)

            if let error = store.agentError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .textSelection(.enabled)
            }

            if !store.agentSteps.isEmpty {
                HStack {
                    Text("Agent steps")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if !store.isAgentRunning {
                        Button("Clear") { store.send(.clearAgentResult) }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(store.agentSteps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step \(step.number) · \(step.reasoning)")
                                    .font(.caption)
                                Text(step.actions)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if step.id != store.agentSteps.last?.id { Divider() }
                        }
                    }
                    .padding(9)
                }
                .frame(maxHeight: 180)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.indigo.opacity(0.07)))
    }

    @ViewBuilder
    private var actionControls: some View {
        @Bindable var store = self.store
        VStack(alignment: .leading, spacing: 8) {
            Label("Element actions", systemImage: "cursorarrow.click")
                .font(.headline)
            Text(
                "Choose an ID from the latest selector map. If the DOM changes, stale IDs are rejected and the page is observed again."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            HStack(spacing: 8) {
                Text("Element #")
                    .font(.caption)
                TextField("ID", value: $store.selectedElementID, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Button("Click") { store.send(.clickSelectedElement) }

                Divider().frame(height: 20)

                TextField("Replacement text", text: $store.replacementText)
                    .textFieldStyle(.roundedBorder)
                Button("Replace Text") { store.send(.replaceSelectedElementText) }
            }
            .disabled(store.isWorking || store.isAgentRunning || store.observation == nil)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.045)))
    }

    @ViewBuilder
    private var status: some View {
        HStack(spacing: 8) {
            if store.isWorking {
                ProgressView().controlSize(.small)
            }
            Text(store.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe.desk")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Connect and observe a Chromium tab to show its selector map.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var selectorMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Latest selector map", systemImage: "list.number")
                .font(.headline)
            ScrollView([.horizontal, .vertical]) {
                Text(store.formattedOutput)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(10)
            }
            .frame(minHeight: 180, maxHeight: 280)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        colorScheme == .dark ? Color.black.opacity(0.25) : Color.gray.opacity(0.08))
            )
        }
    }

    private func tabLabel(_ tab: BrowserTab) -> String {
        let title = tab.title.isEmpty ? tab.url : tab.title
        return "\(tab.state.rawValue.capitalized) · \(title)"
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
