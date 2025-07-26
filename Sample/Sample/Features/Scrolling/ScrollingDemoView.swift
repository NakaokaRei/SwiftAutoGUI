//
//  ScrollingDemoView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct ScrollingDemoView: View {
    @StateObject private var viewModel = ScrollingDemoViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Scrolling Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Click the buttons inside the scrollable areas to test scrolling")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Vertical Scrolling Demo
            VStack(alignment: .leading, spacing: 12) {
                Label("Vertical Scrolling", systemImage: "arrow.up.arrow.down")
                    .font(.headline)
                
                // Large scrollable area with visible content
                ScrollView {
                    VStack(spacing: 20) {
                        // Top section
                        ForEach(0..<10) { index in
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
                        
                        // Control buttons in the middle
                        VStack(spacing: 20) {
                            Text("⬇️ Scroll Control Center ⬇️")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(12)
                            
                            // Instant scroll buttons
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
                            
                            // Smooth scroll buttons
                            VStack(spacing: 12) {
                                Text("Smooth Animated Scroll")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 12) {
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
                                
                                // Special effects
                                Text("Special Effects")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)
                                
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
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.vertical, 40)
                        
                        // Bottom section
                        ForEach(10..<30) { index in
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
            
            Divider()
            
            // Horizontal Scrolling Demo
            VStack(alignment: .leading, spacing: 12) {
                Label("Horizontal Scrolling", systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        // Left content
                        ForEach(0..<10) { index in
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
                        
                        // Control buttons in the middle
                        VStack(spacing: 16) {
                            Text("↔️ Horizontal Controls ↔️")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                            
                            // Instant
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
                            
                            // Smooth
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
                        .padding()
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Right content
                        ForEach(10..<20) { index in
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
            
            Spacer()
        }
        .padding()
    }
}