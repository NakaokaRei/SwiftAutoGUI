//
//  KeyboardDemoViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class KeyboardDemoViewModel {
    
    func sendKeyShortcut() {
        Task {
            _ = await Action.keyShortcut([.control, .leftArrow]).execute()
        }
    }

    func sendSpecialKeyEvent() {
        Task {
            let actions: [Action] = [
                .keyDown(.soundUp),
                .keyUp(.soundUp)
            ]
            _ = await actions.execute()
        }
    }
}