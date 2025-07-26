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
    
    // Smooth scrolling methods
    func smoothVerticalScrollDown() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -50, duration: 2.0, tweening: .easeInOutQuad)
        }
    }
    
    func smoothVerticalScrollUp() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: 50, duration: 2.0, tweening: .easeInOutQuad)
        }
    }
    
    func smoothHorizontalScrollLeft() {
        Task {
            await SwiftAutoGUI.hscroll(clicks: 50, duration: 1.5, tweening: .easeInOutQuad)
        }
    }
    
    func smoothHorizontalScrollRight() {
        Task {
            await SwiftAutoGUI.hscroll(clicks: -50, duration: 1.5, tweening: .easeInOutQuad)
        }
    }
    
    func smoothScrollWithBounce() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -100, duration: 3.0, tweening: .easeOutBounce)
        }
    }
    
    func smoothScrollWithElastic() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: 80, duration: 2.5, tweening: .easeOutElastic)
        }
    }
    
    func smoothScrollCustomEasing() {
        Task {
            await SwiftAutoGUI.vscroll(clicks: -60, duration: 2.0, tweening: .custom({ t in
                return t * t * (3 - 2 * t) // Smooth step
            }))
        }
    }
}