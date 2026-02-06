//
//  PixelDetectionView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct PixelDetectionView: View {
    @State private var viewModel = PixelDetectionViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pixel Detection")
                .font(.headline)
            
            HStack {
                Button("Get Screen Size") {
                    viewModel.getScreenSize()
                }
                
                Button("Get Pixel Color at (100, 100)") {
                    viewModel.getPixelColor()
                }
            }
            
            if !viewModel.screenSize.isEmpty {
                Text(viewModel.screenSize)
                    .font(.caption)
            }
            
            if let color = viewModel.pixelColor {
                HStack {
                    Text("Pixel color:")
                        .font(.caption)
                    Rectangle()
                        .fill(Color(color))
                        .frame(width: 30, height: 30)
                        .border(Color.black)
                }
            }
        }
    }
}