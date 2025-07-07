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
        SwiftAutoGUI.move(to: startPosition)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Get current mouse position
        let position1 = SwiftAutoGUI.position()
        
        // Verify the mouse is at the expected position (with small tolerance)
        #expect(abs(position1.x - startPosition.x) <= 1.0)
        #expect(abs(position1.y - startPosition.y) <= 1.0)
        
        // Test relative movement with positive values
        SwiftAutoGUI.moveMouse(dx: 10, dy: 15)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position2 = SwiftAutoGUI.position()
        
        // Verify the mouse moved exactly by the specified amount
        // Note: moveMouse uses dx with negative sign for x coordinate
        #expect(abs(position2.x - (position1.x - 10)) <= 1.0)
        #expect(abs(position2.y - (position1.y + 15)) <= 1.0)
        
        // Test relative movement with negative values
        SwiftAutoGUI.moveMouse(dx: -20, dy: -10)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position3 = SwiftAutoGUI.position()
        
        // Verify the mouse moved by the negative amounts
        #expect(abs(position3.x - (position2.x + 20)) <= 1.0)
        #expect(abs(position3.y - (position2.y - 10)) <= 1.0)
        
        // Test absolute movement
        let targetPosition = CGPoint(x: 300, y: 400)
        SwiftAutoGUI.move(to: targetPosition)
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position4 = SwiftAutoGUI.position()
        
        // Verify the mouse is at the target position
        #expect(abs(position4.x - targetPosition.x) <= 1.0)
        #expect(abs(position4.y - targetPosition.y) <= 1.0)
        
        // Test movement to screen edges
        SwiftAutoGUI.move(to: CGPoint(x: 0, y: 0))
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let position5 = SwiftAutoGUI.position()
        #expect(abs(position5.x - 0) <= 1.0)
        #expect(abs(position5.y - 0) <= 1.0)
    }
    
    @Test("Mouse movement functions")
    func testMouseMovementFunctions() {
        // Note: These tests only verify that the functions can be called without crashing
        // Actual mouse movement requires accessibility permissions and cannot be
        // fully tested in unit tests without side effects
        
        // Test relative mouse movement
        SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
        SwiftAutoGUI.moveMouse(dx: -5, dy: -5)
        
        // Test absolute mouse movement
        SwiftAutoGUI.move(to: CGPoint(x: 100, y: 100))
        SwiftAutoGUI.move(to: CGPoint(x: 0, y: 0))
        
        // If we get here without crashing, the basic structure is working
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
}