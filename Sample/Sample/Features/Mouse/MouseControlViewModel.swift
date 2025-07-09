//
//  MouseControlViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class MouseControlViewModel: ObservableObject {
    @Published var mousePosition: String = ""
    
    func moveMouse() {
        SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
    }
    
    func getMousePosition() {
        let pos = SwiftAutoGUI.position()
        mousePosition = "Mouse at: x=\(Int(pos.x)), y=\(Int(pos.y))"
    }
    
    func leftClick() {
        SwiftAutoGUI.leftClick()
    }
}