//
//  ImageRecognitionViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class ImageRecognitionViewModel: ObservableObject {
    @Published var imageRecognitionResult: String = ""
    @Published var testImagePath: String = ""
    
    func createTestImageForRecognition() {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.white.setFill()
        NSRect(x: 20, y: 20, width: 60, height: 60).fill()
        
        NSColor.systemRed.setFill()
        NSRect(x: 30, y: 30, width: 40, height: 40).fill()
        
        NSColor.systemYellow.setFill()
        NSBezierPath(ovalIn: NSRect(x: 40, y: 40, width: 20, height: 20)).fill()
        
        image.unlockFocus()
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = documents.appendingPathComponent("test_recognition_image.png").path
        
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: URL(fileURLWithPath: path))
                testImagePath = path
                imageRecognitionResult = "Test image created at: \(path)\nPlease open this image in Preview or another app, then try to locate it."
            } catch {
                imageRecognitionResult = "Failed to create test image: \(error)"
            }
        }
    }
    
    func locateTestImage() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for test image on screen..."
        
        if let foundRect = SwiftAutoGUI.locateOnScreen(testImagePath) {
            imageRecognitionResult = """
                Found test image!
                Location: x=\(Int(foundRect.origin.x)), y=\(Int(foundRect.origin.y))
                Size: \(Int(foundRect.width))x\(Int(foundRect.height))
                """
            
            let centerX = foundRect.midX
            let centerY = foundRect.midY
            
            Task {
                await SwiftAutoGUI.move(to: CGPoint(x: centerX, y: centerY), duration: 0)
                
                await SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y), duration: 0)
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x + foundRect.width, y: foundRect.origin.y), duration: 0)
                try? await Task.sleep(nanoseconds: 200_000_000)
                await SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x + foundRect.width, y: foundRect.origin.y + foundRect.height), duration: 0)
                try? await Task.sleep(nanoseconds: 200_000_000)
                await SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y + foundRect.height), duration: 0)
                try? await Task.sleep(nanoseconds: 200_000_000)
                await SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y), duration: 0)
                try? await Task.sleep(nanoseconds: 200_000_000)
                await SwiftAutoGUI.move(to: CGPoint(x: centerX, y: centerY), duration: 0)
            }
        } else {
            imageRecognitionResult = "Test image not found on screen. Make sure the test image is visible in an app window."
        }
    }
    
    func locateAndClickTestImage() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for test image to click..."
        
        if let center = SwiftAutoGUI.locateCenterOnScreen(testImagePath) {
            imageRecognitionResult = "Found and clicking test image at: x=\(Int(center.x)), y=\(Int(center.y))"
            
            Task {
                await SwiftAutoGUI.move(to: center, duration: 0)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await SwiftAutoGUI.leftClick()
                
                await MainActor.run {
                    imageRecognitionResult += "\nClicked on the test image!"
                }
            }
        } else {
            imageRecognitionResult = "Test image not found on screen. Make sure the test image is visible in an app window."
        }
    }
    
    func findAllTestImages() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for all test images..."
        
        let allMatches = SwiftAutoGUI.locateAllOnScreen(testImagePath, confidence: 0.8)
        
        if !allMatches.isEmpty {
            imageRecognitionResult = "Found \(allMatches.count) instances of the test image:\n"
            
            Task {
                for (index, rect) in allMatches.enumerated() {
                    await MainActor.run {
                        imageRecognitionResult += "\n[\(index + 1)] at x=\(Int(rect.origin.x)), y=\(Int(rect.origin.y)), size=\(Int(rect.width))x\(Int(rect.height))"
                    }
                    
                    let corners = [
                        CGPoint(x: rect.origin.x, y: rect.origin.y),
                        CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y),
                        CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height),
                        CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height),
                        CGPoint(x: rect.origin.x, y: rect.origin.y)
                    ]
                    
                    for i in 0..<corners.count - 1 {
                        await SwiftAutoGUI.move(to: corners[i], duration: 0)
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        await SwiftAutoGUI.move(to: corners[i + 1], duration: 0)
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                }
                
                if let firstMatch = allMatches.first {
                    await SwiftAutoGUI.move(to: CGPoint(x: firstMatch.midX, y: firstMatch.midY), duration: 0)
                }
                
                await MainActor.run {
                    imageRecognitionResult += "\n\nHighlighted all \(allMatches.count) matches!"
                }
            }
        } else {
            imageRecognitionResult = "No test images found on screen. Try opening multiple windows with the test image visible."
        }
    }
}