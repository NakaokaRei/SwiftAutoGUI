//
//  ScrollingDemoViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

class ScrollingDemoViewModel: ObservableObject {
    
    func verticalScrollDown() {
        SwiftAutoGUI.vscroll(clicks: -1)
    }
    
    func verticalScrollUp() {
        SwiftAutoGUI.vscroll(clicks: 1)
    }
    
    func horizontalScrollLeft() {
        SwiftAutoGUI.hscroll(clicks: -1)
    }
    
    func horizontalScrollRight() {
        SwiftAutoGUI.hscroll(clicks: 1)
    }
}