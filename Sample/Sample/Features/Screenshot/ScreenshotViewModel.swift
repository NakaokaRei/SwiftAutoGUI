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
        Task {
            screenshotImage = await Action.screenshot.execute() as? NSImage
        }
    }
    
    func takeScreenshotRegion() {
        Task {
            let region = CGRect(x: 100, y: 100, width: 200, height: 200)
            screenshotImage = await Action.screenshotRegion(region).execute() as? NSImage
        }
    }
    
    func saveScreenshotToDocuments() {
        Task {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let path = documents.appendingPathComponent("swiftautogui_screenshot.png").path
            let result = await Action.screenshotToFile(filename: path).execute() as? Bool
            if result == true {
                print("Screenshot saved to: \(path)")
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
            }
        }
    }
    
    func saveRegionToDocuments() {
        Task {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let path = documents.appendingPathComponent("swiftautogui_region.png").path
            let region = CGRect(x: 0, y: 0, width: 300, height: 300)
            let result = await Action.screenshotToFile(filename: path, region: region).execute() as? Bool
            if result == true {
                print("Region screenshot saved to: \(path)")
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: documents.path)
            }
        }
    }
}