import SwiftUI

struct InputEventObserverView: View {
    @State private var viewModel = InputEventObserverViewModel()
    @State private var leftClickCount = 0
    @State private var contextActionCount = 0
    @State private var text = ""
    @State private var isPointerOverTarget = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            commandExamples

            HStack(alignment: .top, spacing: 16) {
                testControls
                    .frame(maxWidth: 360)
                eventLog
            }
        }
        .onAppear { viewModel.startObserving() }
        .onDisappear { viewModel.stopObserving() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Input Event Observer")
                    .font(.title2.bold())
                Text("Observe the actual NSEvents delivered to the Sample app.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label(
                viewModel.isObserving ? "Observing" : "Stopped",
                systemImage: viewModel.isObserving ? "record.circle.fill" : "stop.circle"
            )
            .foregroundStyle(viewModel.isObserving ? .green : .secondary)
        }
    }

    private var commandExamples: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Try from another Terminal after moving the pointer over Event Target:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(clickCommand)
            Text(rightClickCommand)
            Text("sagui mouse scroll --vertical=-20")
            Text("sagui key down shift  # click the target, then: sagui key up shift")
        }
        .font(.system(.caption, design: .monospaced))
        .textSelection(.enabled)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var testControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                Image(systemName: isPointerOverTarget ? "cursorarrow.click.2" : "cursorarrow.motionlines")
                    .font(.system(size: 30))
                Text("Event Target")
                    .font(.headline)
                Text("Left-click, right-click, or move the pointer here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("left clicks: \(leftClickCount) · context actions: \(contextActionCount)")
                    .font(.caption.monospacedDigit())
                Text(pointerDescription)
                    .font(.caption.monospaced())
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPointerOverTarget ? Color.blue.opacity(0.2) : Color.blue.opacity(0.08))
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.blue.opacity(0.6), lineWidth: 2))
            .onTapGesture { leftClickCount += 1 }
            .onHover { isPointerOverTarget = $0 }
            .contextMenu {
                Button("Record Context Action") {
                    contextActionCount += 1
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Scroll Target")
                    .font(.headline)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(1...20, id: \.self) { row in
                            Text("Observable row \(row)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .frame(height: 100)
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard & Modifiers")
                    .font(.headline)
                TextField("Focus here, then send keys", text: $text)
                    .textFieldStyle(.roundedBorder)
                Text("active modifiers: \(viewModel.currentModifiers)")
                    .font(.caption.monospaced())
            }
        }
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Delivered Events")
                    .font(.headline)
                Spacer()
                Text("down \(downCount) · scroll \(viewModel.eventCounts["scrollWheel", default: 0])")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Clear") { viewModel.clear() }
                    .controlSize(.small)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if viewModel.events.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title)
                            Text("No Events Yet")
                                .font(.headline)
                            Text("Interact with the controls or use sagui.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                    } else {
                        ForEach(viewModel.events) { event in
                            eventRow(event)
                        }
                    }
                }
            }
            .frame(minHeight: 300)
            .padding(8)
            .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }

    private func eventRow(_ event: ObservedInputEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("#\(event.sequence) \(event.name)")
                    .font(.caption.bold().monospaced())
                Spacer()
                if let sourcePID = event.sourcePID {
                    Text("pid \(sourcePID)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
            }
            Text(event.details)
                .font(.caption2.monospaced())
            Text("modifiers: \(event.modifiers)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(eventColor(event.name).opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
    }

    private var downCount: Int {
        viewModel.eventCounts["leftMouseDown", default: 0]
            + viewModel.eventCounts["rightMouseDown", default: 0]
    }

    private var pointerDescription: String {
        guard let point = viewModel.latestPointerPosition else { return "global position: waiting…" }
        return "global position: x=\(Int(point.x)) y=\(Int(point.y))"
    }

    private var clickCommand: String {
        guard let point = viewModel.latestPointerPosition else { return "sagui mouse click --x <x> --y <y>" }
        return "sagui mouse click --x \(Int(point.x)) --y \(Int(point.y))"
    }

    private var rightClickCommand: String {
        guard let point = viewModel.latestPointerPosition else { return "sagui mouse click --right --x <x> --y <y>" }
        return "sagui mouse click --right --x \(Int(point.x)) --y \(Int(point.y))"
    }

    private func eventColor(_ name: String) -> Color {
        switch name {
        case "leftMouseDown", "rightMouseDown": .green
        case "leftMouseUp", "rightMouseUp": .blue
        case "scrollWheel": .orange
        case "flagsChanged", "keyDown", "keyUp": .purple
        default: .gray
        }
    }
}
