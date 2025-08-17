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
            await Action.keyShortcut([.control, .leftArrow]).execute()
        }
    }
    
    func sendSpecialKeyEvent() {
        Task {
            let actions: [Action] = [
                .keyDown(.soundUp),
                .keyUp(.soundUp)
            ]
            await actions.execute()
        }
    }
}