//
//  MouseControlViewModel.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import SwiftUI
import SwiftAutoGUI

@MainActor
class MouseControlViewModel: ObservableObject {
    @Published var mousePosition: String = ""
    @Published var isAnimating: Bool = false
    
    func moveMouse() {
        Task {
            _ = await Action.moveMouse(dx: 10, dy: 10).execute()
        }
    }

    func getMousePosition() {
        let pos = SwiftAutoGUI.position()
        mousePosition = "Mouse at: x=\(Int(pos.x)), y=\(Int(pos.y))"
    }

    func leftClick() {
        Task {
            _ = await Action.leftClick.execute()
        }
    }

    func doubleClick() {
        Task {
            _ = await Action.doubleClick().execute()
        }
    }

    func tripleClick() {
        Task {
            _ = await Action.tripleClick().execute()
        }
    }
    
    // Tweening movement demonstrations
    func performLinearMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 200, y: startPos.y + 100)
                _ = await Action.moveSmooth(to: targetPos, duration: 2.0, tweening: .linear).execute()
            }
        }
    }

    func performEaseInOutMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 150, y: startPos.y + 150)
                _ = await Action.moveSmooth(to: targetPos, duration: 1.5, tweening: .easeInOutQuad).execute()
            }
        }
    }

    func performElasticMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 250, y: startPos.y - 100)
                _ = await Action.moveSmooth(to: targetPos, duration: 2.0, tweening: .easeOutElastic).execute()
            }
        }
    }

    func performBounceMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 200, y: startPos.y - 150)
                _ = await Action.moveSmooth(to: targetPos, duration: 2.0, tweening: .easeOutBounce).execute()
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

                var actions: [Action] = []
                for i in 0...steps {
                    let angle = (Double(i) / Double(steps)) * 2 * Double.pi
                    let x = center.x + radius * cos(angle)
                    let y = center.y + radius * sin(angle)

                    actions.append(.moveSmooth(to: CGPoint(x: x, y: y), duration: stepDuration, tweening: .easeInOutSine))
                }
                _ = await actions.execute()
            }
        }
    }

    func performLowFPSMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x + 300, y: startPos.y)
                // 24 FPS creates visible stepping effect
                _ = await Action.moveSmooth(to: targetPos, duration: 2.0, tweening: .linear, fps: 24).execute()
            }
        }
    }

    func performHighFPSMove() {
        Task {
            await animateMovement {
                let startPos = SwiftAutoGUI.position()
                let targetPos = CGPoint(x: startPos.x - 300, y: startPos.y)
                // 120 FPS creates ultra-smooth movement
                _ = await Action.moveSmooth(to: targetPos, duration: 2.0, tweening: .linear, fps: 120).execute()
            }
        }
    }
    
    @MainActor
    private func animateMovement(animation: @escaping @MainActor () async -> Void) async {
        isAnimating = true

        await animation()

        isAnimating = false
        getMousePosition()
    }
}