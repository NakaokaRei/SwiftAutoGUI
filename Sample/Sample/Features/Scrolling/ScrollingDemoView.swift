//
//  ScrollingDemoView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct ScrollingDemoView: View {
    @State private var viewModel = ScrollingDemoViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            verticalScrollingSection
            Divider()
            horizontalScrollingSection
            Spacer()
        }
        .padding()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scrolling Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Click the buttons inside the scrollable areas to test scrolling")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var verticalScrollingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Vertical Scrolling", systemImage: "arrow.up.arrow.down")
                .font(.headline)

            ScrollView {
                VStack(spacing: 20) {
                    verticalScrollTopRows
                    verticalScrollControlCenter
                    verticalScrollBottomRows
                }
            }
            .frame(height: 400)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var verticalScrollTopRows: some View {
        ForEach(0..<10) { index in
            scrollRowView(index: index)
        }
    }

    private var verticalScrollBottomRows: some View {
        ForEach(10..<30) { index in
            scrollRowView(index: index)
        }
    }

    private func scrollRowView(index: Int) -> some View {
        HStack {
            Text("Row \(index)")
                .font(.title2)
                .fontWeight(.medium)

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 30)
                .overlay(
                    Text("\(index)")
                        .foregroundColor(.blue)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear
        )
    }

    private var verticalScrollControlCenter: some View {
        VStack(spacing: 20) {
            Text("⬇️ Scroll Control Center ⬇️")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(12)

            instantScrollButtons
            smoothScrollButtons
        }
        .padding(.vertical, 40)
    }

    private var instantScrollButtons: some View {
        VStack(spacing: 8) {
            Text("Instant Scroll (5 clicks)")
                .font(.caption)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Button(action: { viewModel.verticalScrollUp() }) {
                    Label("Instant Up", systemImage: "arrow.up")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { viewModel.verticalScrollDown() }) {
                    Label("Instant Down", systemImage: "arrow.down")
                        .frame(width: 120)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var smoothScrollButtons: some View {
        VStack(spacing: 12) {
            Text("Smooth Animated Scroll")
                .font(.caption)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                smoothUpButton
                smoothDownButton
            }

            Text("Special Effects")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.top, 8)

            specialEffectsButtons
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var smoothUpButton: some View {
        Button(action: { viewModel.smoothVerticalScrollUp() }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                Text("Smooth Up")
                Text("(3s)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var smoothDownButton: some View {
        Button(action: { viewModel.smoothVerticalScrollDown() }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                Text("Smooth Down")
                Text("(3s)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var specialEffectsButtons: some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.smoothScrollWithBounce() }) {
                VStack(spacing: 2) {
                    Image(systemName: "arrowshape.bounce.down")
                    Text("Bounce")
                        .font(.caption)
                }
                .frame(width: 80)
            }
            .buttonStyle(.bordered)
            .tint(.purple)

            Button(action: { viewModel.smoothScrollWithElastic() }) {
                VStack(spacing: 2) {
                    Image(systemName: "arrowshape.zigzag.forward")
                    Text("Elastic")
                        .font(.caption)
                }
                .frame(width: 80)
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Button(action: { viewModel.smoothScrollCustomEasing() }) {
                VStack(spacing: 2) {
                    Image(systemName: "waveform.path")
                    Text("Smooth")
                        .font(.caption)
                }
                .frame(width: 80)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }

    private var horizontalScrollingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Horizontal Scrolling", systemImage: "arrow.left.arrow.right")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    horizontalLeftContent
                    horizontalControlButtons
                    horizontalRightContent
                }
                .padding()
            }
            .frame(height: 180)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var horizontalLeftContent: some View {
        ForEach(0..<10) { index in
            horizontalItemView(index: index)
        }
    }

    private var horizontalRightContent: some View {
        ForEach(10..<20) { index in
            horizontalItemView(index: index)
        }
    }

    private func horizontalItemView(index: Int) -> some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "square.grid.2x2")
                            .font(.title)
                        Text("Item \(index)")
                            .font(.caption)
                    }
                    .foregroundColor(.indigo)
                )

            Text("Column \(index)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var horizontalControlButtons: some View {
        VStack(spacing: 16) {
            Text("↔️ Horizontal Controls ↔️")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)

            horizontalInstantButtons
            horizontalSmoothButtons
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(12)
    }

    private var horizontalInstantButtons: some View {
        VStack(spacing: 8) {
            Text("Instant")
                .font(.caption2)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                Button(action: { viewModel.horizontalScrollLeft() }) {
                    Label("Left", systemImage: "arrow.left")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(action: { viewModel.horizontalScrollRight() }) {
                    Label("Right", systemImage: "arrow.right")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private var horizontalSmoothButtons: some View {
        VStack(spacing: 8) {
            Text("Smooth (2.5s)")
                .font(.caption2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                Button(action: { viewModel.smoothHorizontalScrollLeft() }) {
                    Label("Smooth Left", systemImage: "arrow.left.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: { viewModel.smoothHorizontalScrollRight() }) {
                    Label("Smooth Right", systemImage: "arrow.right.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}