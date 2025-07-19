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
    @Published var isAnimating: Bool = false
    
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
    
    func doubleClick() {
        SwiftAutoGUI.doubleClick()
    }
    
    func tripleClick() {
        SwiftAutoGUI.tripleClick()
    }
    
    // Tweening movement demonstrations
    func performLinearMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 200, y: startPos.y + 100)
                await SwiftAutoGUI.move(to: targetPos, duration: 2.0, tweening: .linear)
            }
        }
    }
    
    func performEaseInOutMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 150, y: startPos.y + 150)
                await SwiftAutoGUI.move(to: targetPos, duration: 1.5, tweening: .easeInOutQuad)
            }
        }
    }
    
    func performElasticMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 250, y: startPos.y - 100)
                await SwiftAutoGUI.move(to: targetPos, duration: 2.0, tweening: .easeOutElastic)
            }
        }
    }
    
    func performBounceMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 200, y: startPos.y - 150)
                await SwiftAutoGUI.move(to: targetPos, duration: 2.0, tweening: .easeOutBounce)
            }
        }
    }
    
    func performCirclePattern() {
        Task {
            await animateMovement {
                let center = SwiftAutoGUI.position()
                let radius: CGFloat = 100
                let steps = 60
                let duration = 3.0
                let stepDuration = duration / Double(steps)
                
                for i in 0...steps {
                    let angle = (Double(i) / Double(steps)) * 2 * Double.pi
                    let x = center.x + radius * cos(angle)
                    let y = center.y + radius * sin(angle)
                    
                    await SwiftAutoGUI.move(to: CGPoint(x: x, y: y), duration: stepDuration, tweening: .easeInOutSine)
                }
            }
        }
    }
    
    func performLowFPSMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 300, y: startPos.y)
                // 24 FPS creates visible stepping effect
                await SwiftAutoGUI.move(to: targetPos, duration: 2.0, tweening: .linear, fps: 24)
            }
        }
    }
    
    func performHighFPSMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 300, y: startPos.y)
                // 120 FPS creates ultra-smooth movement
                await SwiftAutoGUI.move(to: targetPos, duration: 2.0, tweening: .linear, fps: 120)
            }
        }
    }
    
    @MainActor
    private func animateMovement(animation: @escaping () async -> Void) async {
        isAnimating = true
        
        await Task.detached {
            await animation()
        }.value
        
        isAnimating = false
        getMousePosition()
    }
}