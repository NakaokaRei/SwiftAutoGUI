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
        VStack(alignment: .leading, spacing: 10) {
            Text("Scrolling Demo")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Instant Scrolling Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Instant Scrolling")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Click buttons to scroll instantly by 1 click")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { index in
                        Text("Vertical Content \(index)")
                            .font(.title)
                    }
                    
                    HStack {
                        Button("Scroll Down") {
                            viewModel.verticalScrollDown()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Scroll Up") {
                            viewModel.verticalScrollUp()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 20)
                    
                    ForEach(10..<20) { index in
                        Text("Vertical Content \(index)")
                            .font(.title)
                    }
                }
            }
            .frame(height: 300)
            
            // Smooth Scrolling Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Smooth Scrolling with Tweening")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                Text("Experience smooth, animated scrolling with various easing functions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Smooth Down (EaseInOut)") {
                        viewModel.smoothVerticalScrollDown()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Smooth Up (EaseInOut)") {
                        viewModel.smoothVerticalScrollUp()
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack(spacing: 12) {
                    Button("Bounce Effect") {
                        viewModel.smoothScrollWithBounce()
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    
                    Button("Elastic Effect") {
                        viewModel.smoothScrollWithElastic()
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                Button("Custom Smooth Step") {
                    viewModel.smoothScrollCustomEasing()
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
            .padding(.vertical, 10)
            
            Divider()
            
            Text("Horizontal Scrolling")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0..<10) { index in
                        Text("Horizontal \(index)")
                            .font(.title)
                    }
                    
                    VStack(spacing: 10) {
                        Text("Instant Scroll")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Left") {
                                viewModel.horizontalScrollLeft()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Right") {
                                viewModel.horizontalScrollRight()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Text("Smooth Scroll")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                        
                        HStack {
                            Button("Smooth Left") {
                                viewModel.smoothHorizontalScrollLeft()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Smooth Right") {
                                viewModel.smoothHorizontalScrollRight()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    ForEach(0..<10) { index in
                        Text("Content \(index)")
                            .font(.title)
                    }
                }
            }
        }
    }
}