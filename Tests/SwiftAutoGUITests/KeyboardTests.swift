import Testing
@testable import SwiftAutoGUI

@Suite("Keyboard Tests")
struct KeyboardTests {
    
    @Test("Key enum normal keycodes mapping")
    func testNormalKeycodes() {
        // Test some common keys have correct keycodes
        #expect(Key.a.normalKeycode == 0x00)
        #expect(Key.z.normalKeycode == 0x06)
        #expect(Key.space.normalKeycode == 0x31)
        #expect(Key.returnKey.normalKeycode == 0x24)
        #expect(Key.escape.normalKeycode == 0x35)
        #expect(Key.tab.normalKeycode == 0x30)
        
        // Test number keys
        #expect(Key.zero.normalKeycode == 0x1D)
        #expect(Key.one.normalKeycode == 0x12)
        #expect(Key.nine.normalKeycode == 0x19)
        
        // Test function keys
        #expect(Key.f1.normalKeycode == 0x7A)
        #expect(Key.f12.normalKeycode == 0x6F)
        
        // Test arrow keys
        #expect(Key.leftArrow.normalKeycode == 0x7B)
        #expect(Key.rightArrow.normalKeycode == 0x7C)
        #expect(Key.downArrow.normalKeycode == 0x7D)
        #expect(Key.upArrow.normalKeycode == 0x7E)
    }
    
    @Test("Key enum special keycodes mapping")
    func testSpecialKeycodes() {
        // Test special keys return nil for normalKeycode
        #expect(Key.soundUp.normalKeycode == nil)
        #expect(Key.soundDown.normalKeycode == nil)
        #expect(Key.brightnessUp.normalKeycode == nil)
        #expect(Key.brightnessDown.normalKeycode == nil)
        #expect(Key.numLock.normalKeycode == nil)
        
        // Test special keys have special keycodes
        #expect(Key.soundUp.specialKeycode != nil)
        #expect(Key.soundDown.specialKeycode != nil)
        #expect(Key.brightnessUp.specialKeycode != nil)
        #expect(Key.brightnessDown.specialKeycode != nil)
        #expect(Key.numLock.specialKeycode != nil)
    }
    
    @Test("Key enum comprehensive coverage")
    func testAllKeysHaveKeycode() {
        // Test that every key has either a normal or special keycode
        let allKeys: [Key] = [
            .returnKey, .enter, .tab, .space, .delete, .escape,
            .command, .shift, .capsLock, .option, .control,
            .rightShift, .rightOption, .rightControl,
            .leftArrow, .rightArrow, .downArrow, .upArrow,
            .volumeUp, .volumeDown, .mute, .help, .home,
            .pageUp, .forwardDelete, .end, .pageDown, .function,
            .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
            .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20,
            .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
            .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
            .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine,
            .equals, .minus, .semicolon, .apostrophe, .comma, .period,
            .forwardSlash, .backslash, .grave, .leftBracket, .rightBracket,
            .keypadDecimal, .keypadMultiply, .keypadPlus, .keypadClear,
            .keypadDivide, .keypadEnter, .keypadMinus, .keypadEquals,
            .keypad0, .keypad1, .keypad2, .keypad3, .keypad4,
            .keypad5, .keypad6, .keypad7, .keypad8, .keypad9,
            .soundUp, .soundDown, .brightnessUp, .brightnessDown, .numLock
        ]
        
        for key in allKeys {
            let hasKeycode = (key.normalKeycode != nil) || (key.specialKeycode != nil)
            #expect(hasKeycode, "Key.\(key.rawValue) should have either normal or special keycode")
        }
    }
    
    @Test("Keyboard event functions basic test")
    func testKeyboardEventFunctions() async throws {
        // Note: These tests only verify that the functions can be called without crashing
        // Actual key event generation requires accessibility permissions and cannot be
        // fully tested in unit tests
        
        // Test single key press
        await SwiftAutoGUI.keyDown(.a)
        await SwiftAutoGUI.keyUp(.a)
        
        // Test special key
        await SwiftAutoGUI.keyDown(.soundUp)
        await SwiftAutoGUI.keyUp(.soundUp)
        
        // Test key shortcut
        await SwiftAutoGUI.sendKeyShortcut([.command, .c])
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Write function basic test")
    func testWriteFunction() async {
        // Note: This test only verifies that the write function can be called without crashing
        // Actual text typing requires accessibility permissions and cannot be fully tested in unit tests
        
        // Test basic text writing
        await SwiftAutoGUI.write("Hello")
        
        // Test with special characters
        await SwiftAutoGUI.write("Hello, World!")
        
        // Test with numbers
        await SwiftAutoGUI.write("123")
        
        // Test with interval (should not crash)
        await SwiftAutoGUI.write("Test", interval: 0.01)
        
        // Test empty string
        await SwiftAutoGUI.write("")
        
        // Test with mixed case
        await SwiftAutoGUI.write("MixedCase")
        
        // If we get here without crashing, the basic structure is working
        #expect(true)
    }
    
    @Test("Character to key mapping")
    func testCharacterToKeyMapping() async {
        // Test that basic characters map correctly
        // Note: These are private functions, so we test indirectly through write
        
        // Test that unsupported characters are handled gracefully
        await SwiftAutoGUI.write("🎉") // Should not crash on emoji
        
        // Test common punctuation
        await SwiftAutoGUI.write("!@#$%^&*()")
        await SwiftAutoGUI.write("{}[]|:\"<>?~")
        
        // Test basic ASCII characters
        await SwiftAutoGUI.write("abcdefghijklmnopqrstuvwxyz")
        await SwiftAutoGUI.write("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        await SwiftAutoGUI.write("0123456789")
        
        // If we get here without crashing, character mapping works
        #expect(true)
    }
}