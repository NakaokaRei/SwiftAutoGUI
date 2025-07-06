import Testing
import CoreGraphics
@testable import SwiftAutoGUI

@Suite("Mouse Tests")
struct MouseTests {
    
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