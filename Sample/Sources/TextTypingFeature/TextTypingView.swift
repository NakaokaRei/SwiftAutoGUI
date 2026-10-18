//
//  TextTypingView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct TextTypingView: View {
    public init() {}
    @State private var store = Store(initialState: TextTypingFeature.State()) {
        TextTypingFeature()
    }
    @FocusState private var isTargetFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        @Bindable var store = self.store
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

                TextField("Type your message here...", text: $store.textToType)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
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

                TextField("Text will appear here...", text: $store.targetTextField)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                store.isTargetFieldFocused
                                    ? Color.blue.opacity(0.15)
                                    : (colorScheme == .dark
                                        ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                store.isTargetFieldFocused
                                    ? Color.blue
                                    : Color.blue.opacity(0.3),
                                lineWidth: store.isTargetFieldFocused ? 2 : 1)
                    )
                    .focused($isTargetFieldFocused)
                    .onChange(of: store.isTargetFieldFocused) { _, newValue in
                        isTargetFieldFocused = newValue
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Typing Speed", systemImage: "speedometer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(String(format: "%.1f", store.typingSpeed))s interval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $store.typingSpeed, in: 0.0...1.0, step: 0.1)
                    .tint(.blue)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Type Custom Text") {
                        store.send(.typeCustomText)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.textToType.isEmpty)

                    Button("Focus Target Field & Type") {
                        store.send(.focusAndTypeInTargetField)
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.textToType.isEmpty)
                }

                Divider()
                    .padding(.vertical, 4)

                Text("Quick Actions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button("Hello, World!") {
                        store.send(.typeText("Hello, World!"))
                    }
                    .buttonStyle(.bordered)

                    Button("Test123!@#") {
                        store.send(.typeText("Test123!@#"))
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    Button("The quick brown fox...") {
                        store.send(.typeText("The quick brown fox jumps over the lazy dog"))
                    }
                    .buttonStyle(.bordered)

                    Button("Multi-line") {
                        store.send(.typeText("Line 1\nLine 2\nLine 3"))
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !store.typingStatus.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text(store.typingStatus)
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
        .onDisappear { store.send(.stop) }
    }
}
