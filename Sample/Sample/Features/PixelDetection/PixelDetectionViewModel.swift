//
//  PixelDetectionViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class PixelDetectionViewModel {
    var pixelColor: NSColor?
    var screenSize: String = ""
    
    func getScreenSize() {
        Task {
            if let size = await Action.getScreenSize.execute() as? (CGFloat, CGFloat) {
                screenSize = "Screen: \(Int(size.0)) x \(Int(size.1))"
            }
        }
    }
    
    func getPixelColor() {
        Task {
            pixelColor = await Action.getPixel(x: 100, y: 100).execute() as? NSColor
        }
    }
}