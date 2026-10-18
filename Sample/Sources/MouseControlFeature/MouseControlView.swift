//
//  MouseControlView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct MouseControlView: View {
    public init() {}
    @State private var store = Store(initialState: MouseControlFeature.State()) {
        MouseControlFeature()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mouse Control")
                .font(.headline)

            // Basic Movement Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Basic Movement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Button("Move Mouse (+10, +10)") {
                        store.send(.moveMouse)
                    }

                    Button("Get Mouse Position") {
                        store.send(.getMousePosition)
                    }
                }

                if !store.mousePosition.isEmpty {
                    Text(store.mousePosition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Clicking Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Click Actions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Button("Left Click") {
                        store.send(.leftClick)
                    }

                    Button("Double Click") {
                        store.send(.doubleClick)
                    }

                    Button("Triple Click") {
                        store.send(.tripleClick)
                    }
                }
            }

            Divider()

            // Tweening Movement Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Smooth Movement with Tweening")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    // Linear movement
                    HStack {
                        Button("Linear Move (2s)") {
                            store.send(.performLinearMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Moves cursor in a straight line at constant speed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Ease In/Out movements
                    HStack {
                        Button("Ease In-Out (1.5s)") {
                            store.send(.performEaseInOutMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Slow start and end, fast in the middle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Elastic movement
                    HStack {
                        Button("Elastic (2s)") {
                            store.send(.performElasticMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Spring-like movement with overshoot")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Bounce movement
                    HStack {
                        Button("Bounce (2s)") {
                            store.send(.performBounceMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Bounces at the end like a ball")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Circle pattern
                    HStack {
                        Button("Circle Pattern (3s)") {
                            store.send(.performCirclePattern)
                        }
                        .disabled(store.isAnimating)

                        Text("Moves in a circular pattern using custom function")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Low FPS demo
                    HStack {
                        Button("Low FPS Move (24fps)") {
                            store.send(.performLowFPSMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Choppy movement with cinematic frame rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // High FPS demo
                    HStack {
                        Button("High FPS Move (120fps)") {
                            store.send(.performHighFPSMove)
                        }
                        .disabled(store.isAnimating)

                        Text("Ultra-smooth movement with high frame rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if store.isAnimating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Animation in progress...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onDisappear { store.send(.stop) }
    }
}
