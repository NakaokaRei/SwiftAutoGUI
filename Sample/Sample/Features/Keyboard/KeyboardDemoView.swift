//
//  KeyboardDemoView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

struct KeyboardDemoView: View {
    @StateObject private var viewModel = KeyboardDemoViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard Demo")
                .font(.headline)
            
            Button("Key Shortcut (⌃←)") {
                viewModel.sendKeyShortcut()
            }
            
            Button("Special Key (Volume Up)") {
                viewModel.sendSpecialKeyEvent()
            }
        }
    }
}