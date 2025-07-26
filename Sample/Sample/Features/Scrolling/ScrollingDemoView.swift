//
//  ScrollingDemoView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct ScrollingDemoView: View {
    @StateObject private var viewModel = ScrollingDemoViewModel()
    @State private var scrollPosition: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Scrolling Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test instant and smooth scrolling with various tweening effects")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            // Vertical Scrolling Demo
            VStack(alignment: .leading, spacing: 12) {
                Label("Vertical Scrolling", systemImage: "arrow.up.arrow.down")
                    .font(.headline)
                
                // Large scrollable area with visible content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<50) { index in
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
                                .id(index)
                            }
                        }
                    }
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Control buttons
                VStack(spacing: 16) {
                    // Instant scroll buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instant Scroll (5 clicks)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(action: { viewModel.verticalScrollUp() }) {
                                Label("Up", systemImage: "arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: { viewModel.verticalScrollDown() }) {
                                Label("Down", systemImage: "arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    // Smooth scroll buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smooth Animated Scroll")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(action: { viewModel.smoothVerticalScrollUp() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                    Text("Smooth Up")
                                        .font(.caption)
                                    Text("(3s EaseInOut)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            Button(action: { viewModel.smoothVerticalScrollDown() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title2)
                                    Text("Smooth Down")
                                        .font(.caption)
                                    Text("(3s EaseInOut)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        
                        // Special effects
                        Text("Special Effects")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            Button(action: { viewModel.smoothScrollWithBounce() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrowshape.bounce.down")
                                        .font(.title3)
                                    Text("Bounce")
                                    Text("(4s)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                            
                            Button(action: { viewModel.smoothScrollWithElastic() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrowshape.zigzag.forward")
                                        .font(.title3)
                                    Text("Elastic")
                                    Text("(3.5s)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            
                            Button(action: { viewModel.smoothScrollCustomEasing() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "waveform.path")
                                        .font(.title3)
                                    Text("Smooth")
                                    Text("(3s)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // Horizontal Scrolling Demo
            VStack(alignment: .leading, spacing: 12) {
                Label("Horizontal Scrolling", systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(0..<30) { index in
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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .frame(height: 120)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Horizontal control buttons
                HStack(spacing: 16) {
                    // Instant
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instant")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                    
                    // Smooth
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smooth (2.5s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
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
            
            Spacer()
        }
        .padding()
    }
}