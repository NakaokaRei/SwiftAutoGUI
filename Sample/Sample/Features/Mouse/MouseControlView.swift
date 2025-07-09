//
//  MouseControlView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct MouseControlView: View {
    @StateObject private var viewModel = MouseControlViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mouse Control")
                .font(.headline)
            
            Button("Move Mouse (+10, +10)") {
                viewModel.moveMouse()
            }
            
            Button("Get Mouse Position") {
                viewModel.getMousePosition()
            }
            
            if !viewModel.mousePosition.isEmpty {
                Text(viewModel.mousePosition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Left Click") {
                viewModel.leftClick()
            }
        }
    }
}