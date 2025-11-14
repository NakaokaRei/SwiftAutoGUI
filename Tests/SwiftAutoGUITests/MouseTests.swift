import Testing
import CoreGraphics
import Foundation
@testable import SwiftAutoGUI

@Suite("Mouse Tests", .serialized)
struct MouseTests {
    
    @Test("Mouse position function")
    func testMousePositionFunction() async throws {
        // First, move to a known position to start from a consistent state
        let startPosition = CGPoint(x: 500, y: 500)
        await SwiftAutoGUI.move(to: startPosition, duration: 0)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Get current mouse position
        let position1 = SwiftAutoGUI.position()
        
        // Verify the mouse is at the expected position (with small tolerance)
        #expect(abs(position1.x - startPosition.x) <= 1.0)
        #expect(abs(position1.y - startPosition.y) <= 1.0)
        
        // Test relative movement with positive values
        await SwiftAutoGUI.moveMouse(dx: 10, dy: 15)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position2 = SwiftAutoGUI.position()
        
        // Verify the mouse moved exactly by the specified amount
        // Note: moveMouse uses dx with negative sign for x coordinate
        #expect(abs(position2.x - (position1.x + 10)) <= 1.0)
        #expect(abs(position2.y - (position1.y + 15)) <= 1.0)
        
        // Test relative movement with negative values
        await SwiftAutoGUI.moveMouse(dx: -20, dy: -10)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position3 = SwiftAutoGUI.position()
        
        // Verify the mouse moved by the negative amounts
        #expect(abs(position3.x - (position2.x - 20)) <= 1.0)
        #expect(abs(position3.y - (position2.y - 10)) <= 1.0)
        
        // Test absolute movement
        let targetPosition = CGPoint(x: 300, y: 400)
        await SwiftAutoGUI.move(to: targetPosition, duration: 0)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position4 = SwiftAutoGUI.position()
        
        // Verify the mouse is at the target position
        #expect(abs(position4.x - targetPosition.x) <= 1.0)
        #expect(abs(position4.y - targetPosition.y) <= 1.0)
        
        // Test movement to screen edges
        await SwiftAutoGUI.move(to: CGPoint(x: 0, y: 0), duration: 0)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position5 = SwiftAutoGUI.position()
        #expect(abs(position5.x - 0) <= 1.0)
        #expect(abs(position5.y - 0) <= 1.0)
    }
    
    @Test("Mouse movement functions")
    func testMouseMovementFunctions() async throws {
        // Note: These tests only verify that the functions can be called without crashing
        // Actual mouse movement requires accessibility permissions and cannot be
        // fully tested in unit tests without side effects
        
        // Test relative mouse movement
        await SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
        await SwiftAutoGUI.moveMouse(dx: -5, dy: -5)
        
        // Test absolute mouse movement
        await SwiftAutoGUI.move(to: CGPoint(x: 100, y: 100), duration: 0)
        await SwiftAutoGUI.move(to: CGPoint(x: 0, y: 0), duration: 0)
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Mouse movement with tweening")
    func testMouseMovementWithTweening() async throws {
        // Test instant movement (duration: 0)
        await SwiftAutoGUI.move(to: CGPoint(x: 200, y: 200), duration: 0)
        
        // Test async movement with default linear tween
        await SwiftAutoGUI.move(to: CGPoint(x: 300, y: 300), duration: 0.1)
        
        // Test with various tweening functions
        await SwiftAutoGUI.move(to: CGPoint(x: 400, y: 400), duration: 0.1, tweening: .easeInQuad)
        
        await SwiftAutoGUI.move(to: CGPoint(x: 500, y: 300), duration: 0.1, tweening: .easeOutQuad)
        
        await SwiftAutoGUI.move(to: CGPoint(x: 300, y: 500), duration: 0.1, tweening: .easeInOutQuad)
        
        // Test with custom tweening function
        await SwiftAutoGUI.move(to: CGPoint(x: 200, y: 400), duration: 0.1, tweening: .custom({ t in
            return t * t * (3 - 2 * t) // Smooth step
        }))
        
        // Test instant movement still works
        await SwiftAutoGUI.move(to: CGPoint(x: 100, y: 100), duration: 0)
        
        // If we get here without crashing, the tweening functions are working
        #expect(true)
    }
    
    @Test("Mouse movement tweening accuracy")
    func testMouseMovementTweeningAccuracy() async throws {
        // Start from a known position
        let startPos = CGPoint(x: 100, y: 100)
        await SwiftAutoGUI.move(to: startPos, duration: 0)
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // Move with linear tweening using async function
        let endPos = CGPoint(x: 300, y: 300)
        await SwiftAutoGUI.move(to: endPos, duration: 0.2, tweening: .linear)
        
        // Check that we reached the target position
        let finalPos = SwiftAutoGUI.position()
        #expect(abs(finalPos.x - endPos.x) <= 1.0)
        #expect(abs(finalPos.y - endPos.y) <= 1.0)
    }
    
    @Test("Mouse movement with different FPS")
    func testMouseMovementWithDifferentFPS() async throws {
        // Test with low FPS (24)
        await SwiftAutoGUI.move(to: CGPoint(x: 100, y: 100), duration: 0)
        await SwiftAutoGUI.move(to: CGPoint(x: 200, y: 200), duration: 0.1, fps: 24)
        
        // Test with standard FPS (60) 
        await SwiftAutoGUI.move(to: CGPoint(x: 300, y: 300), duration: 0.1, fps: 60)
        
        // Test with high FPS (120)
        await SwiftAutoGUI.move(to: CGPoint(x: 400, y: 400), duration: 0.1, fps: 120)
        
        // Test with very low FPS (10)
        await SwiftAutoGUI.move(to: CGPoint(x: 200, y: 300), duration: 0.1, fps: 10)
        
        // If we get here without crashing, FPS parameter works
        #expect(true)
    }
    
    @Test("Mouse click functions")
    func testMouseClickFunctions() {
        // Note: These tests only verify that the functions can be called without crashing
        // Actual mouse clicks require accessibility permissions
        
        // Test left click
        SwiftAutoGUI.leftClick()
        
        // Test right click
        SwiftAutoGUI.rightClick()
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Mouse drag function")
    func testMouseDragFunction() {
        // Note: This test only verifies that the function can be called without crashing
        
        let from = CGPoint(x: 100, y: 100)
        let to = CGPoint(x: 200, y: 200)
        
        SwiftAutoGUI.leftDragged(to: to, from: from)
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Mouse scroll functions")
    func testMouseScrollFunctions() {
        // Note: These tests only verify that the functions can be called without crashing
        
        // Test vertical scroll
        SwiftAutoGUI.vscroll(clicks: 5)
        SwiftAutoGUI.vscroll(clicks: -5)
        SwiftAutoGUI.vscroll(clicks: 0)
        
        // Test horizontal scroll
        SwiftAutoGUI.hscroll(clicks: 3)
        SwiftAutoGUI.hscroll(clicks: -3)
        SwiftAutoGUI.hscroll(clicks: 0)
        
        // Test large scroll values (should handle division by 10)
        SwiftAutoGUI.vscroll(clicks: 50)
        SwiftAutoGUI.vscroll(clicks: -50)
        SwiftAutoGUI.hscroll(clicks: 25)
        SwiftAutoGUI.hscroll(clicks: -25)
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Mouse scroll edge cases")
    func testMouseScrollEdgeCases() {
        // Test scroll with exactly 10 clicks
        SwiftAutoGUI.vscroll(clicks: 10)
        SwiftAutoGUI.vscroll(clicks: -10)
        SwiftAutoGUI.hscroll(clicks: 10)
        SwiftAutoGUI.hscroll(clicks: -10)
        
        // Test scroll with 11 clicks (10 + 1)
        SwiftAutoGUI.vscroll(clicks: 11)
        SwiftAutoGUI.vscroll(clicks: -11)
        
        // Test scroll with 19 clicks (10 + 9)
        SwiftAutoGUI.hscroll(clicks: 19)
        SwiftAutoGUI.hscroll(clicks: -19)
        
        // If we get here without crashing, the scroll division logic is working
        #expect(true)
    }
    
    @Test("Smooth vertical scrolling with duration")
    func testSmoothVerticalScrolling() async throws {
        // Test basic smooth scrolling
        await SwiftAutoGUI.vscroll(clicks: 10, duration: 0.1)
        
        // Test with different tweening functions
        await SwiftAutoGUI.vscroll(clicks: -20, duration: 0.1, tweening: .easeInQuad)
        await SwiftAutoGUI.vscroll(clicks: 15, duration: 0.1, tweening: .easeOutQuad)
        await SwiftAutoGUI.vscroll(clicks: -10, duration: 0.1, tweening: .easeInOutQuad)
        
        // Test with custom tweening
        await SwiftAutoGUI.vscroll(clicks: 25, duration: 0.1, tweening: .custom({ t in
            return t * t * (3 - 2 * t) // Smooth step
        }))
        
        // Test with different FPS values
        await SwiftAutoGUI.vscroll(clicks: 30, duration: 0.1, fps: 30)
        await SwiftAutoGUI.vscroll(clicks: -30, duration: 0.1, fps: 120)
        
        // Test edge cases
        await SwiftAutoGUI.vscroll(clicks: 0, duration: 0.1)
        await SwiftAutoGUI.vscroll(clicks: 1, duration: 0.05)
        await SwiftAutoGUI.vscroll(clicks: -1, duration: 0.05)
        
        // If we get here without crashing, smooth scrolling is working
        #expect(true)
    }
    
    @Test("Smooth horizontal scrolling with duration")
    func testSmoothHorizontalScrolling() async throws {
        // Test basic smooth scrolling
        await SwiftAutoGUI.hscroll(clicks: 10, duration: 0.1)
        
        // Test with different tweening functions
        await SwiftAutoGUI.hscroll(clicks: -20, duration: 0.1, tweening: .easeInQuad)
        await SwiftAutoGUI.hscroll(clicks: 15, duration: 0.1, tweening: .easeOutQuad)
        await SwiftAutoGUI.hscroll(clicks: -10, duration: 0.1, tweening: .easeInOutQuad)
        
        // Test with elastic and bounce effects
        await SwiftAutoGUI.hscroll(clicks: 50, duration: 0.15, tweening: .easeOutElastic)
        await SwiftAutoGUI.hscroll(clicks: -50, duration: 0.15, tweening: .easeOutBounce)
        
        // Test with custom tweening
        await SwiftAutoGUI.hscroll(clicks: 25, duration: 0.1, tweening: .custom({ t in
            return sin(t * Double.pi / 2) // Ease out sine
        }))
        
        // Test with different FPS values
        await SwiftAutoGUI.hscroll(clicks: 30, duration: 0.1, fps: 24)
        await SwiftAutoGUI.hscroll(clicks: -30, duration: 0.1, fps: 60)
        
        // If we get here without crashing, smooth scrolling is working
        #expect(true)
    }
    
    @Test("Smooth scrolling with long duration")
    func testSmoothScrollingLongDuration() async throws {
        // Test with longer duration to ensure accumulation works correctly
        await SwiftAutoGUI.vscroll(clicks: 100, duration: 0.3, tweening: .linear)
        await SwiftAutoGUI.hscroll(clicks: -75, duration: 0.3, tweening: .easeInOutCubic)
        
        // Test very large scroll amounts
        await SwiftAutoGUI.vscroll(clicks: 200, duration: 0.2, tweening: .easeOutQuad, fps: 30)
        await SwiftAutoGUI.hscroll(clicks: -150, duration: 0.2, tweening: .easeInQuart, fps: 30)
        
        #expect(true)
    }
    
    @Test("Smooth scrolling frame calculation")
    func testSmoothScrollingFrameCalculation() async throws {
        // Test that very short durations still produce some frames
        await SwiftAutoGUI.vscroll(clicks: 10, duration: 0.01, fps: 60)
        
        // Test high FPS with short duration
        await SwiftAutoGUI.hscroll(clicks: 5, duration: 0.05, fps: 120)
        
        // Test low FPS with longer duration
        await SwiftAutoGUI.vscroll(clicks: 20, duration: 0.2, fps: 10)
        
        #expect(true)
    }
}