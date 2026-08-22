//
//  DemoTab.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI

enum DemoTab: String, CaseIterable {
    case keyboard
    case keyboardLayout
    case mouse
    case inputObserver
    case textTyping
    case screenshot
    case imageRecognition
    case pixelDetection
    case scrolling
    case dialog
    case appleScript
    case actions
    case aiGeneration
    case screenContext
    case browser
    case agent

    var title: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .keyboardLayout: return "KB Layout"
        case .mouse: return "Mouse"
        case .inputObserver: return "Observer"
        case .textTyping: return "Text Typing"
        case .screenshot: return "Screenshot"
        case .imageRecognition: return "Image Recognition"
        case .pixelDetection: return "Pixel Detection"
        case .scrolling: return "Scrolling"
        case .dialog: return "Dialog"
        case .appleScript: return "AppleScript"
        case .actions: return "Actions"
        case .aiGeneration: return "AI Generation"
        case .screenContext: return "Screen Context"
        case .browser: return "Browser CDP"
        case .agent: return "AI Agent"
        }
    }

    var icon: String {
        switch self {
        case .keyboard: return "keyboard"
        case .keyboardLayout: return "globe"
        case .mouse: return "cursorarrow"
        case .inputObserver: return "waveform.path.ecg"
        case .textTyping: return "text.cursor"
        case .screenshot: return "camera.viewfinder"
        case .imageRecognition: return "eye"
        case .pixelDetection: return "eyedropper"
        case .scrolling: return "arrow.up.and.down"
        case .dialog: return "message"
        case .appleScript: return "applescript"
        case .actions: return "play.circle"
        case .aiGeneration: return "sparkles"
        case .screenContext: return "accessibility"
        case .browser: return "network"
        case .agent: return "brain"
        }
    }
}
