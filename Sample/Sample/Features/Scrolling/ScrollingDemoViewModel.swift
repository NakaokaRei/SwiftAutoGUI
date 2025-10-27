//
//  ScrollingDemoViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
class ScrollingDemoViewModel: ObservableObject {
    
    func verticalScrollDown() {
        Task {
            _ = await Action.vscroll(clicks: -5).execute()
        }
    }

    func verticalScrollUp() {
        Task {
            _ = await Action.vscroll(clicks: 5).execute()
        }
    }

    func horizontalScrollLeft() {
        Task {
            _ = await Action.hscroll(clicks: 5).execute()
        }
    }

    func horizontalScrollRight() {
        Task {
            _ = await Action.hscroll(clicks: -5).execute()
        }
    }

    // Smooth scrolling methods
    func smoothVerticalScrollDown() {
        Task {
            _ = await Action.smoothVScroll(clicks: -150, duration: 3.0, tweening: .easeInOutQuad).execute()
        }
    }

    func smoothVerticalScrollUp() {
        Task {
            _ = await Action.smoothVScroll(clicks: 150, duration: 3.0, tweening: .easeInOutQuad).execute()
        }
    }

    func smoothHorizontalScrollLeft() {
        Task {
            _ = await Action.smoothHScroll(clicks: 100, duration: 2.5, tweening: .easeInOutQuad).execute()
        }
    }

    func smoothHorizontalScrollRight() {
        Task {
            _ = await Action.smoothHScroll(clicks: -100, duration: 2.5, tweening: .easeInOutQuad).execute()
        }
    }

    func smoothScrollWithBounce() {
        Task {
            _ = await Action.smoothVScroll(clicks: -200, duration: 4.0, tweening: .easeOutBounce).execute()
        }
    }

    func smoothScrollWithElastic() {
        Task {
            _ = await Action.smoothVScroll(clicks: 180, duration: 3.5, tweening: .easeOutElastic).execute()
        }
    }

    func smoothScrollCustomEasing() {
        Task {
            _ = await Action.smoothVScroll(clicks: -120, duration: 3.0, tweening: .custom({ t in
                return t * t * (3 - 2 * t) // Smooth step
            })).execute()
        }
    }
}