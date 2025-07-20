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
        Task {
            await SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
        }
    }
    
    func sendSpecialKeyEvent() {
        Task {
            await SwiftAutoGUI.keyDown(.soundUp)
            await SwiftAutoGUI.keyUp(.soundUp)
        }
    }
}