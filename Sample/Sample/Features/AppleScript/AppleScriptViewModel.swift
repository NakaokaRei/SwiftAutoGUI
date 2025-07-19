//
//  AppleScriptViewModel.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/07/19.
//

import Foundation
import SwiftAutoGUI

@MainActor
final class AppleScriptViewModel: ObservableObject {
    @Published var scriptText: String
    @Published var result: String = ""
    @Published var isExecuting: Bool = false
    @Published var errorMessage: String?
    
    init() {
        // Initial sample script
        self.scriptText = """
tell application "Safari"
    activate
    make new document
    set URL of current tab of front window to "https://github.com/NakaokaRei/SwiftAutoGUI"
end tell
"""
    }
    
    func executeScript() {
        isExecuting = true
        errorMessage = nil
        result = ""
        
        Task {
            do {
                print("Executing AppleScript:")
                print(scriptText)
                print("---")
                
                if let output = try SwiftAutoGUI.executeAppleScript(scriptText) {
                    print("Script output: \(output)")
                    await MainActor.run {
                        self.result = output
                        self.isExecuting = false
                    }
                } else {
                    print("Script completed with no output")
                    await MainActor.run {
                        self.result = "Script executed successfully (no output)"
                        self.isExecuting = false
                    }
                }
            } catch let error as SwiftAutoGUI.AppleScriptError {
                print("AppleScript error: \(error)")
                await MainActor.run {
                    self.errorMessage = error.errorDescription
                    self.isExecuting = false
                }
            } catch {
                print("Unexpected error: \(error)")
                await MainActor.run {
                    self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                    self.isExecuting = false
                }
            }
        }
    }
    
    func loadSampleScript(_ sample: SampleScript) {
        scriptText = sample.script
        result = ""
        errorMessage = nil
    }
    
    enum SampleScript: String, CaseIterable {
        case safariSearch = "Safari Search"
        case systemInfo = "System Info"
        case volumeControl = "Volume Control"
        case notification = "Notification"
        case calculator = "Calculator"
        
        var script: String {
            switch self {
            case .safariSearch:
                return """
tell application "Safari"
    activate
    make new document
    set URL of current tab of front window to "https://github.com/NakaokaRei/SwiftAutoGUI"
end tell
"""
            case .systemInfo:
                return """
tell application "System Events"
    set userName to name of current user
    set osVersion to system version of (system info)
    return "User: " & userName & ", macOS: " & osVersion
end tell
"""
            case .volumeControl:
                return """
-- Get current volume
set currentVolume to output volume of (get volume settings)

-- Set volume to 50%
set volume output volume 50

-- Return the previous volume
return "Previous volume was: " & currentVolume & "%"
"""
            case .notification:
                return """
display notification "Hello from SwiftAutoGUI!" with title "AppleScript Demo" subtitle "This is a test notification"
return "Notification sent!"
"""
            case .calculator:
                return """
-- Simple calculation
set result to (25 * 4) + (100 / 2)
return "25 × 4 + 100 ÷ 2 = " & result
"""
            }
        }
    }
}