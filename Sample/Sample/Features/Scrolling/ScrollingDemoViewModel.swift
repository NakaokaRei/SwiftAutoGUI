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
        SwiftAutoGUI.vscroll(clicks: -5)
    }
    
    func verticalScrollUp() {
        SwiftAutoGUI.vscroll(clicks: 5)
    }
    
    func horizontalScrollLeft() {
        SwiftAutoGUI.hscroll(clicks: 5)
    }
    
    func horizontalScrollRight() {
        SwiftAutoGUI.hscroll(clicks: -5)
    }
    
    // Smooth scrolling methods
    func smoothVerticalScrollDown() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -150, duration: 3.0, tweening: .easeInOutQuad)
        }
    }
    
    func smoothVerticalScrollUp() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: 150, duration: 3.0, tweening: .easeInOutQuad)
        }
    }
    
    func smoothHorizontalScrollLeft() {
        Task {
            await SwiftAutoGUI.hscroll(clicks: 100, duration: 2.5, tweening: .easeInOutQuad)
        }
    }
    
    func smoothHorizontalScrollRight() {
        Task {
            await SwiftAutoGUI.hscroll(clicks: -100, duration: 2.5, tweening: .easeInOutQuad)
        }
    }
    
    func smoothScrollWithBounce() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -200, duration: 4.0, tweening: .easeOutBounce)
        }
    }
    
    func smoothScrollWithElastic() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: 180, duration: 3.5, tweening: .easeOutElastic)
        }
    }
    
    func smoothScrollCustomEasing() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -120, duration: 3.0, tweening: .custom({ t in
                return t * t * (3 - 2 * t) // Smooth step
            }))
        }
    }
}