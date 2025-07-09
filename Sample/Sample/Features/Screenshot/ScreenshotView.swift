//
//  ScreenshotView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct ScreenshotView: View {
    @StateObject private var viewModel = ScreenshotViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Screenshot Features")
                .font(.headline)
            
            HStack {
                Button("Take Screenshot") {
                    viewModel.takeScreenshot()
                }
                
                Button("Screenshot Region (200x200)") {
                    viewModel.takeScreenshotRegion()
                }
            }
            
            HStack {
                Button("Save Screenshot to Documents") {
                    viewModel.saveScreenshotToDocuments()
                }
                
                Button("Save Region to Documents") {
                    viewModel.saveRegionToDocuments()
                }
            }
            
            if let image = viewModel.screenshotImage {
                Text("Screenshot Preview:")
                    .font(.caption)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .border(Color.gray)
            }
        }
    }
}