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
            
            Text("Vertical Scrolling")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                ForEach(0..<10) { index in
                    Text("Vertical Content \(index)")
                        .font(.title)
                }
            }
            
            HStack {
                Button("Vertical Scroll Down") {
                    viewModel.verticalScrollDown()
                }
                
                Button("Vertical Scroll Up") {
                    viewModel.verticalScrollUp()
                }
            }
            
            Text("Horizontal Scrolling")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0..<10) { index in
                        Text("Horizontal \(index)")
                            .font(.title)
                    }
                    
                    Button("Horizontal Scroll Left") {
                        viewModel.horizontalScrollLeft()
                    }
                    
                    Button("Horizontal Scroll Right") {
                        viewModel.horizontalScrollRight()
                    }
                    
                    ForEach(0..<10) { index in
                        Text("Content \(index)")
                            .font(.title)
                    }
                }
            }
        }
    }
}