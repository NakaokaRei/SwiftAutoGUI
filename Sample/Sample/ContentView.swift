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
                        Button("Save Screenshot to Desktop") {
                            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                            let path = desktop.appendingPathComponent("swiftautogui_screenshot.png").path
                            if SwiftAutoGUI.screenshot(imageFilename: path) {
                                print("Screenshot saved to: \(path)")
                            }
                        }
                        
                        Button("Save Region to Desktop") {
                            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                            let path = desktop.appendingPathComponent("swiftautogui_region.png").path
                            let region = CGRect(x: 0, y: 0, width: 300, height: 300)
                            if SwiftAutoGUI.screenshot(imageFilename: path, region: region) {
                                print("Region screenshot saved to: \(path)")
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
