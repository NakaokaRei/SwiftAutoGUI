//
//  MouseControlView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct MouseControlView: View {
    @State private var viewModel = MouseControlViewModel()
    
    var body: some View {
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
                        viewModel.moveMouse()
                    }
                    
                    Button("Get Mouse Position") {
                        viewModel.getMousePosition()
                    }
                }
                
                if !viewModel.mousePosition.isEmpty {
                    Text(viewModel.mousePosition)
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
                        viewModel.leftClick()
                    }
                    
                    Button("Double Click") {
                        viewModel.doubleClick()
                    }
                    
                    Button("Triple Click") {
                        viewModel.tripleClick()
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
                            viewModel.performLinearMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Moves cursor in a straight line at constant speed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Ease In/Out movements
                    HStack {
                        Button("Ease In-Out (1.5s)") {
                            viewModel.performEaseInOutMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Slow start and end, fast in the middle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Elastic movement
                    HStack {
                        Button("Elastic (2s)") {
                            viewModel.performElasticMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Spring-like movement with overshoot")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Bounce movement
                    HStack {
                        Button("Bounce (2s)") {
                            viewModel.performBounceMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Bounces at the end like a ball")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Circle pattern
                    HStack {
                        Button("Circle Pattern (3s)") {
                            viewModel.performCirclePattern()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Moves in a circular pattern using custom function")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Low FPS demo
                    HStack {
                        Button("Low FPS Move (24fps)") {
                            viewModel.performLowFPSMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Choppy movement with cinematic frame rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // High FPS demo
                    HStack {
                        Button("High FPS Move (120fps)") {
                            viewModel.performHighFPSMove()
                        }
                        .disabled(viewModel.isAnimating)
                        
                        Text("Ultra-smooth movement with high frame rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if viewModel.isAnimating {
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
    }
}