//
//  ContentView.swift
//  Sample
//
//  Created by NakaokaRei on 2023/01/15.
//

import SwiftUI
import SwiftAutoGUI

struct ContentView: View {
    @State private var screenshotImage: NSImage?
    @State private var pixelColor: NSColor?
    @State private var screenSize: String = ""
    @State private var imageRecognitionResult: String = ""
    @State private var testImagePath: String = ""
    @State private var mousePosition: String = ""
    @State private var textToType: String = ""
    @State private var typingSpeed: Double = 0.0
    @State private var typingStatus: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Existing controls
                Group {
                    ForEach(0..<10) {
                        Text("\($0)").font(.title)
                    }
                    Button("key event") {
                        SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
                    }
                    Button("special key event") {
                        SwiftAutoGUI.keyDown(.soundUp)
                        SwiftAutoGUI.keyUp(.soundUp)
                    }
                    Button("move mouse") {
                        SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
                    }
                    Button("get mouse position") {
                        let pos = SwiftAutoGUI.position()
                        mousePosition = "Mouse at: x=\(Int(pos.x)), y=\(Int(pos.y))"
                    }
                    if !mousePosition.isEmpty {
                        Text(mousePosition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button("click") {
                        SwiftAutoGUI.leftClick()
                    }
                    Button("vscroll -") {
                        SwiftAutoGUI.vscroll(clicks: -1)
                    }
                    Button("vscroll +") {
                        SwiftAutoGUI.vscroll(clicks: 1)
                    }
                }
                
                Divider()
                
                // Text Typing Demo Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Text Typing Demo")
                        .font(.headline)
                    
                    // Text input field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Enter text to type:")
                            .font(.caption)
                        TextField("Type your message here...", text: $textToType)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Typing speed control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Typing Speed: \(String(format: "%.1f", typingSpeed))s interval")
                            .font(.caption)
                        Slider(value: $typingSpeed, in: 0.0...1.0, step: 0.1)
                            .frame(maxWidth: 200)
                    }
                    
                    // Type custom text button
                    Button("Type Custom Text") {
                        typeText(textToType)
                    }
                    .disabled(textToType.isEmpty)
                    
                    // Quick test buttons
                    HStack {
                        Button("\"Hello, World!\"") {
                            typeText("Hello, World!")
                        }
                        
                        Button("\"Test123!@#\"") {
                            typeText("Test123!@#")
                        }
                    }
                    
                    HStack {
                        Button("\"The quick brown fox...\"") {
                            typeText("The quick brown fox jumps over the lazy dog")
                        }
                        
                        Button("Multi-line Text") {
                            typeText("Line 1\nLine 2\nLine 3")
                        }
                    }
                    
                    // Status display
                    if !typingStatus.isEmpty {
                        Text(typingStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Screenshot features
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screenshot Features")
                        .font(.headline)
                    
                    HStack {
                        Button("Take Screenshot") {
                            screenshotImage = SwiftAutoGUI.screenshot()
                        }
                        
                        Button("Screenshot Region (200x200)") {
                            let region = CGRect(x: 100, y: 100, width: 200, height: 200)
                            screenshotImage = SwiftAutoGUI.screenshot(region: region)
                        }
                    }
                    
                    HStack {
                        Button("Save Screenshot to Documents") {
                            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let path = documents.appendingPathComponent("swiftautogui_screenshot.png").path
                            if SwiftAutoGUI.screenshot(imageFilename: path) {
                                print("Screenshot saved to: \(path)")
                                // Open Finder to show the file
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
                            }
                        }
                        
                        Button("Save Region to Documents") {
                            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let path = documents.appendingPathComponent("swiftautogui_region.png").path
                            let region = CGRect(x: 0, y: 0, width: 300, height: 300)
                            if SwiftAutoGUI.screenshot(imageFilename: path, region: region) {
                                print("Region screenshot saved to: \(path)")
                                // Open Finder to show the file
                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
                            }
                        }
                    }
                    
                    HStack {
                        Button("Get Screen Size") {
                            let (width, height) = SwiftAutoGUI.size()
                            screenSize = "Screen: \(Int(width)) x \(Int(height))"
                        }
                        
                        Button("Get Pixel Color at (100, 100)") {
                            pixelColor = SwiftAutoGUI.pixel(x: 100, y: 100)
                        }
                    }
                    
                    // Display results
                    if !screenSize.isEmpty {
                        Text(screenSize)
                            .font(.caption)
                    }
                    
                    if let color = pixelColor {
                        HStack {
                            Text("Pixel color:")
                                .font(.caption)
                            Rectangle()
                                .fill(Color(color))
                                .frame(width: 30, height: 30)
                                .border(Color.black)
                        }
                    }
                    
                    // Display screenshot preview
                    if let image = screenshotImage {
                        Text("Screenshot Preview:")
                            .font(.caption)
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .border(Color.gray)
                    }
                }
                
                Divider()
                
                // Image Recognition features
                VStack(alignment: .leading, spacing: 10) {
                    Text("Image Recognition Features")
                        .font(.headline)
                    
                    Button("Create Test Image") {
                        createTestImageForRecognition()
                    }
                    
                    Button("Locate Test Image on Screen") {
                        locateTestImage()
                    }
                    
                    Button("Locate and Click Test Image") {
                        locateAndClickTestImage()
                    }
                    
                    Button("Find All Test Images") {
                        findAllTestImages()
                    }
                    
                    if !imageRecognitionResult.isEmpty {
                        Text(imageRecognitionResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                ForEach(0..<10) {
                    Text("\($0)").font(.title)
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<10) {
                            Text("\($0)").font(.title)
                        }
                        Button("hscroll -") {
                            SwiftAutoGUI.hscroll(clicks: -1)
                        }
                        Button("hscroll +") {
                            SwiftAutoGUI.hscroll(clicks: 1)
                        }
                        ForEach(0..<10) {
                            Text("\($0)").font(.title)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Image Recognition Helper Functions
    
    private func createTestImageForRecognition() {
        // Create a distinctive test image
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create a distinctive pattern
        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.white.setFill()
        NSRect(x: 20, y: 20, width: 60, height: 60).fill()
        
        NSColor.systemRed.setFill()
        NSRect(x: 30, y: 30, width: 40, height: 40).fill()
        
        NSColor.systemYellow.setFill()
        NSBezierPath(ovalIn: NSRect(x: 40, y: 40, width: 20, height: 20)).fill()
        
        image.unlockFocus()
        
        // Save to Documents directory
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
    
    private func locateTestImage() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for test image on screen..."
        
        // Try to locate the image
        if let foundRect = SwiftAutoGUI.locateOnScreen(testImagePath) {
            imageRecognitionResult = """
                Found test image!
                Location: x=\(Int(foundRect.origin.x)), y=\(Int(foundRect.origin.y))
                Size: \(Int(foundRect.width))x\(Int(foundRect.height))
                """
            
            // Highlight the found area by moving mouse around it
            let centerX = foundRect.midX
            let centerY = foundRect.midY
            
            // Move mouse to center of found image
            SwiftAutoGUI.move(to: CGPoint(x: centerX, y: centerY))
            
            // Draw a rectangle with the mouse
            SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y))
            Thread.sleep(forTimeInterval: 0.2)
            SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x + foundRect.width, y: foundRect.origin.y))
            Thread.sleep(forTimeInterval: 0.2)
            SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x + foundRect.width, y: foundRect.origin.y + foundRect.height))
            Thread.sleep(forTimeInterval: 0.2)
            SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y + foundRect.height))
            Thread.sleep(forTimeInterval: 0.2)
            SwiftAutoGUI.move(to: CGPoint(x: foundRect.origin.x, y: foundRect.origin.y))
            Thread.sleep(forTimeInterval: 0.2)
            SwiftAutoGUI.move(to: CGPoint(x: centerX, y: centerY))
        } else {
            imageRecognitionResult = "Test image not found on screen. Make sure the test image is visible in an app window."
        }
    }
    
    private func locateAndClickTestImage() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for test image to click..."
        
        // Use the new locateCenterOnScreen function
        if let center = SwiftAutoGUI.locateCenterOnScreen(testImagePath) {
            imageRecognitionResult = "Found and clicking test image at: x=\(Int(center.x)), y=\(Int(center.y))"
            
            // Move to center and click
            SwiftAutoGUI.move(to: center)
            Thread.sleep(forTimeInterval: 0.5)
            SwiftAutoGUI.leftClick()
            
            imageRecognitionResult += "\nClicked on the test image!"
        } else {
            imageRecognitionResult = "Test image not found on screen. Make sure the test image is visible in an app window."
        }
    }
    
    private func findAllTestImages() {
        guard !testImagePath.isEmpty else {
            imageRecognitionResult = "Please create a test image first"
            return
        }
        
        imageRecognitionResult = "Searching for all test images..."
        
        // Find all instances of the test image
        let allMatches = SwiftAutoGUI.locateAllOnScreen(testImagePath, confidence: 0.8)
        
        if !allMatches.isEmpty {
            imageRecognitionResult = "Found \(allMatches.count) instances of the test image:\n"
            
            // Show details of each match and highlight them
            for (index, rect) in allMatches.enumerated() {
                imageRecognitionResult += "\n[\(index + 1)] at x=\(Int(rect.origin.x)), y=\(Int(rect.origin.y)), size=\(Int(rect.width))x\(Int(rect.height))"
                
                // Draw a box around each found instance
                let corners = [
                    CGPoint(x: rect.origin.x, y: rect.origin.y),
                    CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y),
                    CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height),
                    CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height),
                    CGPoint(x: rect.origin.x, y: rect.origin.y)
                ]
                
                for i in 0..<corners.count - 1 {
                    SwiftAutoGUI.move(to: corners[i])
                    Thread.sleep(forTimeInterval: 0.1)
                    SwiftAutoGUI.move(to: corners[i + 1])
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            
            // Move to center of the first match
            if let firstMatch = allMatches.first {
                SwiftAutoGUI.move(to: CGPoint(x: firstMatch.midX, y: firstMatch.midY))
            }
            
            imageRecognitionResult += "\n\nHighlighted all \(allMatches.count) matches!"
        } else {
            imageRecognitionResult = "No test images found on screen. Try opening multiple windows with the test image visible."
        }
    }
    
    // MARK: - Text Typing Helper Function
    
    private func typeText(_ text: String) {
        guard !text.isEmpty else {
            typingStatus = "Please enter some text to type"
            return
        }
        
        typingStatus = "Typing: \"\(text)\" (speed: \(String(format: "%.1f", typingSpeed))s interval)"
        
        // Use async/await pattern for delay and typing
        Task {
            await performTyping(text: text)
        }
    }
    
    @MainActor
    private func performTyping(text: String) async {
        // Add a small delay to give user time to switch to target application
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        SwiftAutoGUI.write(text, interval: typingSpeed)
        
        typingStatus = "✅ Completed typing: \"\(text)\""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
