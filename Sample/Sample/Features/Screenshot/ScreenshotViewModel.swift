//
//  ScreenshotViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class ScreenshotViewModel: ObservableObject {
    @Published var screenshotImage: NSImage?
    
    func takeScreenshot() {
        screenshotImage = SwiftAutoGUI.screenshot()
    }
    
    func takeScreenshotRegion() {
        let region = CGRect(x: 100, y: 100, width: 200, height: 200)
        screenshotImage = SwiftAutoGUI.screenshot(region: region)
    }
    
    func saveScreenshotToDocuments() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = documents.appendingPathComponent("swiftautogui_screenshot.png").path
        if SwiftAutoGUI.screenshot(imageFilename: path) {
            print("Screenshot saved to: \(path)")
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
        }
    }
    
    func saveRegionToDocuments() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = documents.appendingPathComponent("swiftautogui_region.png").path
        let region = CGRect(x: 0, y: 0, width: 300, height: 300)
        if SwiftAutoGUI.screenshot(imageFilename: path, region: region) {
            print("Region screenshot saved to: \(path)")
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
        }
    }
}