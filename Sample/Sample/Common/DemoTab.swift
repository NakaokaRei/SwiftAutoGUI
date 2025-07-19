//
//  DemoTab.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

enum DemoTab: String, CaseIterable {
    case keyboard
    case mouse
    case textTyping
    case screenshot
    case imageRecognition
    case pixelDetection
    case scrolling
    case dialog
    case appleScript
    
    var title: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .mouse: return "Mouse"
        case .textTyping: return "Text Typing"
        case .screenshot: return "Screenshot"
        case .imageRecognition: return "Image Recognition"
        case .pixelDetection: return "Pixel Detection"
        case .scrolling: return "Scrolling"
        case .dialog: return "Dialog"
        case .appleScript: return "AppleScript"
        }
    }
    
    var icon: String {
        switch self {
        case .keyboard: return "keyboard"
        case .mouse: return "cursorarrow"
        case .textTyping: return "text.cursor"
        case .screenshot: return "camera.viewfinder"
        case .imageRecognition: return "eye"
        case .pixelDetection: return "eyedropper"
        case .scrolling: return "arrow.up.and.down"
        case .dialog: return "message"
        case .appleScript: return "applescript"
        }
    }
}