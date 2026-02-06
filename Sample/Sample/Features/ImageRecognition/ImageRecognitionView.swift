//
//  ImageRecognitionView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct ImageRecognitionView: View {
    @State private var viewModel = ImageRecognitionViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Image Recognition Features")
                .font(.headline)
            
            Button("Create Test Image") {
                viewModel.createTestImageForRecognition()
            }
            
            Button("Locate Test Image on Screen") {
                viewModel.locateTestImage()
            }
            
            Button("Locate and Click Test Image") {
                viewModel.locateAndClickTestImage()
            }
            
            Button("Find All Test Images") {
                viewModel.findAllTestImages()
            }
            
            if !viewModel.imageRecognitionResult.isEmpty {
                Text(viewModel.imageRecognitionResult)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}