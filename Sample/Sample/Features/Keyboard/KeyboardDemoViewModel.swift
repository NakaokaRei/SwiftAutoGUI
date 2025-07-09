//
//  KeyboardDemoViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class KeyboardDemoViewModel: ObservableObject {
    
    func sendKeyShortcut() {
        SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
    }
    
    func sendSpecialKeyEvent() {
        SwiftAutoGUI.keyDown(.soundUp)
        SwiftAutoGUI.keyUp(.soundUp)
    }
}