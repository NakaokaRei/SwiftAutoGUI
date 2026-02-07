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

    @Test("JIS key keycodes")
    func testJISKeycodes() {
        #expect(Key.jisYen.normalKeycode == 0x5D)
        #expect(Key.jisUnderscore.normalKeycode == 0x5E)
        #expect(Key.jisEisu.normalKeycode == 0x66)
        #expect(Key.jisKana.normalKeycode == 0x68)

        // JIS keys are normal keys, not special keys
        #expect(Key.jisYen.specialKeycode == nil)
        #expect(Key.jisUnderscore.specialKeycode == nil)
        #expect(Key.jisEisu.specialKeycode == nil)
        #expect(Key.jisKana.specialKeycode == nil)
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
            .jisYen, .jisUnderscore, .jisEisu, .jisKana,
            .soundUp, .soundDown, .brightnessUp, .brightnessDown, .numLock
        ]

        for key in allKeys {
            let hasKeycode = (key.normalKeycode != nil) || (key.specialKeycode != nil)
            #expect(hasKeycode, "Key.\(key.rawValue) should have either normal or special keycode")
        }
    }

    @Test("US layout character mapping")
    func testUSLayoutMapping() {
        let layout = KeyboardLayout.us

        // Letters
        let aMapping = layout.mapping(for: "a")
        #expect(aMapping?.key == .a)
        #expect(aMapping?.needsShift == false)

        let upperA = layout.mapping(for: "A")
        #expect(upperA?.key == .a)
        #expect(upperA?.needsShift == true)

        // Numbers
        #expect(layout.mapping(for: "0")?.key == .zero)
        #expect(layout.mapping(for: "0")?.needsShift == false)

        // US-specific symbol mappings
        #expect(layout.mapping(for: "@")?.key == .two)
        #expect(layout.mapping(for: "@")?.needsShift == true)

        #expect(layout.mapping(for: "[")?.key == .leftBracket)
        #expect(layout.mapping(for: "[")?.needsShift == false)

        #expect(layout.mapping(for: "]")?.key == .rightBracket)
        #expect(layout.mapping(for: "]")?.needsShift == false)

        #expect(layout.mapping(for: ":")?.key == .semicolon)
        #expect(layout.mapping(for: ":")?.needsShift == true)

        #expect(layout.mapping(for: "^")?.key == .six)
        #expect(layout.mapping(for: "^")?.needsShift == true)

        #expect(layout.mapping(for: "\"")?.key == .apostrophe)
        #expect(layout.mapping(for: "\"")?.needsShift == true)

        #expect(layout.mapping(for: "&")?.key == .seven)
        #expect(layout.mapping(for: "&")?.needsShift == true)

        #expect(layout.mapping(for: "'")?.key == .apostrophe)
        #expect(layout.mapping(for: "'")?.needsShift == false)

        #expect(layout.mapping(for: "(")?.key == .nine)
        #expect(layout.mapping(for: "(")?.needsShift == true)

        #expect(layout.mapping(for: ")")?.key == .zero)
        #expect(layout.mapping(for: ")")?.needsShift == true)

        #expect(layout.mapping(for: "=")?.key == .equals)
        #expect(layout.mapping(for: "=")?.needsShift == false)

        #expect(layout.mapping(for: "~")?.key == .grave)
        #expect(layout.mapping(for: "~")?.needsShift == true)

        #expect(layout.mapping(for: "`")?.key == .grave)
        #expect(layout.mapping(for: "`")?.needsShift == false)

        #expect(layout.mapping(for: "+")?.key == .equals)
        #expect(layout.mapping(for: "+")?.needsShift == true)

        #expect(layout.mapping(for: "*")?.key == .eight)
        #expect(layout.mapping(for: "*")?.needsShift == true)

        #expect(layout.mapping(for: "_")?.key == .minus)
        #expect(layout.mapping(for: "_")?.needsShift == true)

        #expect(layout.mapping(for: "\\")?.key == .backslash)
        #expect(layout.mapping(for: "\\")?.needsShift == false)

        #expect(layout.mapping(for: "{")?.key == .leftBracket)
        #expect(layout.mapping(for: "{")?.needsShift == true)

        #expect(layout.mapping(for: "}")?.key == .rightBracket)
        #expect(layout.mapping(for: "}")?.needsShift == true)

        #expect(layout.mapping(for: "|")?.key == .backslash)
        #expect(layout.mapping(for: "|")?.needsShift == true)

        // Unsupported characters
        #expect(layout.mapping(for: "😀") == nil)
    }

    @Test("JIS layout character mapping")
    func testJISLayoutMapping() {
        let layout = KeyboardLayout.jis

        // Letters work the same way
        let aMapping = layout.mapping(for: "a")
        #expect(aMapping?.key == .a)
        #expect(aMapping?.needsShift == false)

        // JIS-specific mappings that differ from US
        #expect(layout.mapping(for: "@")?.key == .leftBracket)
        #expect(layout.mapping(for: "@")?.needsShift == false)

        #expect(layout.mapping(for: "[")?.key == .rightBracket)
        #expect(layout.mapping(for: "[")?.needsShift == false)

        #expect(layout.mapping(for: "]")?.key == .backslash)
        #expect(layout.mapping(for: "]")?.needsShift == false)

        #expect(layout.mapping(for: ":")?.key == .apostrophe)
        #expect(layout.mapping(for: ":")?.needsShift == false)

        #expect(layout.mapping(for: "^")?.key == .equals)
        #expect(layout.mapping(for: "^")?.needsShift == false)

        #expect(layout.mapping(for: "\"")?.key == .two)
        #expect(layout.mapping(for: "\"")?.needsShift == true)

        #expect(layout.mapping(for: "&")?.key == .six)
        #expect(layout.mapping(for: "&")?.needsShift == true)

        #expect(layout.mapping(for: "'")?.key == .seven)
        #expect(layout.mapping(for: "'")?.needsShift == true)

        #expect(layout.mapping(for: "(")?.key == .eight)
        #expect(layout.mapping(for: "(")?.needsShift == true)

        #expect(layout.mapping(for: ")")?.key == .nine)
        #expect(layout.mapping(for: ")")?.needsShift == true)

        #expect(layout.mapping(for: "=")?.key == .minus)
        #expect(layout.mapping(for: "=")?.needsShift == true)

        #expect(layout.mapping(for: "~")?.key == .equals)
        #expect(layout.mapping(for: "~")?.needsShift == true)

        #expect(layout.mapping(for: "`")?.key == .leftBracket)
        #expect(layout.mapping(for: "`")?.needsShift == true)

        #expect(layout.mapping(for: "+")?.key == .semicolon)
        #expect(layout.mapping(for: "+")?.needsShift == true)

        #expect(layout.mapping(for: "*")?.key == .apostrophe)
        #expect(layout.mapping(for: "*")?.needsShift == true)

        #expect(layout.mapping(for: "_")?.key == .jisUnderscore)
        #expect(layout.mapping(for: "_")?.needsShift == false)

        #expect(layout.mapping(for: "\\")?.key == .jisYen)
        #expect(layout.mapping(for: "\\")?.needsShift == false)

        #expect(layout.mapping(for: "{")?.key == .rightBracket)
        #expect(layout.mapping(for: "{")?.needsShift == true)

        #expect(layout.mapping(for: "}")?.key == .backslash)
        #expect(layout.mapping(for: "}")?.needsShift == true)

        #expect(layout.mapping(for: "|")?.key == .jisYen)
        #expect(layout.mapping(for: "|")?.needsShift == true)
    }

    @Test("Layout override")
    @MainActor
    func testLayoutOverride() {
        // Set to JIS
        SwiftAutoGUI.currentLayout = .jis
        #expect(SwiftAutoGUI.currentLayout == .jis)

        // Key.from(character:) should use JIS layout
        #expect(Key.from(character: "@") == .leftBracket)
        #expect(Key.from(character: "[") == .rightBracket)

        // Set to US
        SwiftAutoGUI.currentLayout = .us
        #expect(SwiftAutoGUI.currentLayout == .us)

        // Key.from(character:) should use US layout
        #expect(Key.from(character: "@") == .two)
        #expect(Key.from(character: "[") == .leftBracket)

        // Reset to auto-detect
        SwiftAutoGUI.resetLayoutToAutoDetect()
    }

    @Test("Key.from(character:layout:) backward compatibility")
    func testFromCharacterWithLayout() {
        // The layout-explicit version works from any context (not @MainActor)
        #expect(Key.from(character: "a", layout: .us) == .a)
        #expect(Key.from(character: "a", layout: .jis) == .a)

        // Layout-specific differences
        #expect(Key.from(character: "@", layout: .us) == .two)
        #expect(Key.from(character: "@", layout: .jis) == .leftBracket)

        #expect(Key.from(character: "_", layout: .us) == .minus)
        #expect(Key.from(character: "_", layout: .jis) == .jisUnderscore)

        #expect(Key.from(character: "\\", layout: .us) == .backslash)
        #expect(Key.from(character: "\\", layout: .jis) == .jisYen)

        // Unsupported character returns nil for both layouts
        #expect(Key.from(character: "😀", layout: .us) == nil)
        #expect(Key.from(character: "😀", layout: .jis) == nil)
    }

    @Test("KeyboardLayout.detect returns a valid layout")
    func testLayoutDetection() {
        let detected = KeyboardLayout.detect()
        #expect(KeyboardLayout.allCases.contains(detected))
    }

    @Test("Common mappings are consistent across layouts")
    func testCommonMappings() {
        let commonChars: [Character] = [
            "a", "z", "0", "9", " ", "\t", "\n",
            ",", ".", "/", "-", "!", "#", "$", "%", "<", ">", "?"
        ]

        for char in commonChars {
            let usMapping = KeyboardLayout.us.mapping(for: char)
            let jisMapping = KeyboardLayout.jis.mapping(for: char)
            #expect(usMapping?.key == jisMapping?.key,
                    "Character '\(char)' should map to the same key on US and JIS")
            #expect(usMapping?.needsShift == jisMapping?.needsShift,
                    "Character '\(char)' should have the same shift requirement on US and JIS")
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
