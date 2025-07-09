//
//  PixelDetectionViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class PixelDetectionViewModel: ObservableObject {
    @Published var pixelColor: NSColor?
    @Published var screenSize: String = ""
    
    func getScreenSize() {
        let (width, height) = SwiftAutoGUI.size()
        screenSize = "Screen: \(Int(width)) x \(Int(height))"
    }
    
    func getPixelColor() {
        pixelColor = SwiftAutoGUI.pixel(x: 100, y: 100)
    }
}