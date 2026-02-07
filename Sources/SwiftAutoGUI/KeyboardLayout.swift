import Carbon

/// Represents the result of mapping a character to a physical key, including whether the Shift modifier is needed.
public struct CharacterKeyMapping: Sendable {
    public let key: Key
    public let needsShift: Bool

    public init(key: Key, needsShift: Bool) {
        self.key = key
        self.needsShift = needsShift
    }
}

/// Represents a keyboard layout for character-to-keycode mapping.
///
/// Different keyboard layouts (e.g., US and JIS) map characters to different physical keys.
/// This enum provides layout-specific character mappings and automatic layout detection.
///
/// ## Example
///
/// ```swift
/// // Auto-detect the current keyboard layout
/// let layout = KeyboardLayout.detect()
///
/// // Get the mapping for a character
/// if let mapping = layout.mapping(for: "@") {
///     print("Key: \(mapping.key), needsShift: \(mapping.needsShift)")
/// }
///
/// // Manually set a layout
/// SwiftAutoGUI.currentLayout = .jis
/// ```
public enum KeyboardLayout: String, Sendable, CaseIterable {
    case us
    case jis

    /// Detects the physical keyboard layout using macOS hardware API.
    ///
    /// Uses `KBGetLayoutType(LMGetKbdType())` to determine the physical keyboard type,
    /// independent of the current IME or input source setting.
    ///
    /// - Returns: The detected keyboard layout.
    public static func detect() -> KeyboardLayout {
        let layoutType = KBGetLayoutType(Int16(LMGetKbdType()))
        if layoutType == kKeyboardJIS {
            return .jis
        }
        return .us
    }

    /// Returns the character-to-key mapping for the given character in this layout.
    ///
    /// - Parameter character: The character to map.
    /// - Returns: A `CharacterKeyMapping` containing the key and whether Shift is needed, or `nil` if unmapped.
    public func mapping(for character: Character) -> CharacterKeyMapping? {
        // Common mappings shared across layouts (letters, numbers, whitespace)
        if let common = Self.commonMapping(for: character) {
            return common
        }
        switch self {
        case .us:
            return Self.usMapping(for: character)
        case .jis:
            return Self.jisMapping(for: character)
        }
    }

    // MARK: - Common mappings (shared across all layouts)

    private static func commonMapping(for character: Character) -> CharacterKeyMapping? {
        switch character.lowercased() {
        case "a": return CharacterKeyMapping(key: .a, needsShift: character.isUppercase)
        case "b": return CharacterKeyMapping(key: .b, needsShift: character.isUppercase)
        case "c": return CharacterKeyMapping(key: .c, needsShift: character.isUppercase)
        case "d": return CharacterKeyMapping(key: .d, needsShift: character.isUppercase)
        case "e": return CharacterKeyMapping(key: .e, needsShift: character.isUppercase)
        case "f": return CharacterKeyMapping(key: .f, needsShift: character.isUppercase)
        case "g": return CharacterKeyMapping(key: .g, needsShift: character.isUppercase)
        case "h": return CharacterKeyMapping(key: .h, needsShift: character.isUppercase)
        case "i": return CharacterKeyMapping(key: .i, needsShift: character.isUppercase)
        case "j": return CharacterKeyMapping(key: .j, needsShift: character.isUppercase)
        case "k": return CharacterKeyMapping(key: .k, needsShift: character.isUppercase)
        case "l": return CharacterKeyMapping(key: .l, needsShift: character.isUppercase)
        case "m": return CharacterKeyMapping(key: .m, needsShift: character.isUppercase)
        case "n": return CharacterKeyMapping(key: .n, needsShift: character.isUppercase)
        case "o": return CharacterKeyMapping(key: .o, needsShift: character.isUppercase)
        case "p": return CharacterKeyMapping(key: .p, needsShift: character.isUppercase)
        case "q": return CharacterKeyMapping(key: .q, needsShift: character.isUppercase)
        case "r": return CharacterKeyMapping(key: .r, needsShift: character.isUppercase)
        case "s": return CharacterKeyMapping(key: .s, needsShift: character.isUppercase)
        case "t": return CharacterKeyMapping(key: .t, needsShift: character.isUppercase)
        case "u": return CharacterKeyMapping(key: .u, needsShift: character.isUppercase)
        case "v": return CharacterKeyMapping(key: .v, needsShift: character.isUppercase)
        case "w": return CharacterKeyMapping(key: .w, needsShift: character.isUppercase)
        case "x": return CharacterKeyMapping(key: .x, needsShift: character.isUppercase)
        case "y": return CharacterKeyMapping(key: .y, needsShift: character.isUppercase)
        case "z": return CharacterKeyMapping(key: .z, needsShift: character.isUppercase)
        default: break
        }

        switch character {
        case "0": return CharacterKeyMapping(key: .zero, needsShift: false)
        case "1": return CharacterKeyMapping(key: .one, needsShift: false)
        case "2": return CharacterKeyMapping(key: .two, needsShift: false)
        case "3": return CharacterKeyMapping(key: .three, needsShift: false)
        case "4": return CharacterKeyMapping(key: .four, needsShift: false)
        case "5": return CharacterKeyMapping(key: .five, needsShift: false)
        case "6": return CharacterKeyMapping(key: .six, needsShift: false)
        case "7": return CharacterKeyMapping(key: .seven, needsShift: false)
        case "8": return CharacterKeyMapping(key: .eight, needsShift: false)
        case "9": return CharacterKeyMapping(key: .nine, needsShift: false)
        case " ": return CharacterKeyMapping(key: .space, needsShift: false)
        case "\t": return CharacterKeyMapping(key: .tab, needsShift: false)
        case "\n": return CharacterKeyMapping(key: .returnKey, needsShift: false)
        case "\r": return CharacterKeyMapping(key: .returnKey, needsShift: false)
        case ",": return CharacterKeyMapping(key: .comma, needsShift: false)
        case ".": return CharacterKeyMapping(key: .period, needsShift: false)
        case "/": return CharacterKeyMapping(key: .forwardSlash, needsShift: false)
        case "-": return CharacterKeyMapping(key: .minus, needsShift: false)
        case "!": return CharacterKeyMapping(key: .one, needsShift: true)
        case "#": return CharacterKeyMapping(key: .three, needsShift: true)
        case "$": return CharacterKeyMapping(key: .four, needsShift: true)
        case "%": return CharacterKeyMapping(key: .five, needsShift: true)
        case "<": return CharacterKeyMapping(key: .comma, needsShift: true)
        case ">": return CharacterKeyMapping(key: .period, needsShift: true)
        case "?": return CharacterKeyMapping(key: .forwardSlash, needsShift: true)
        default: return nil
        }
    }

    // MARK: - US layout mappings

    private static func usMapping(for character: Character) -> CharacterKeyMapping? {
        switch character {
        case "=": return CharacterKeyMapping(key: .equals, needsShift: false)
        case ";": return CharacterKeyMapping(key: .semicolon, needsShift: false)
        case "'": return CharacterKeyMapping(key: .apostrophe, needsShift: false)
        case "\\": return CharacterKeyMapping(key: .backslash, needsShift: false)
        case "`": return CharacterKeyMapping(key: .grave, needsShift: false)
        case "[": return CharacterKeyMapping(key: .leftBracket, needsShift: false)
        case "]": return CharacterKeyMapping(key: .rightBracket, needsShift: false)
        case "@": return CharacterKeyMapping(key: .two, needsShift: true)
        case "^": return CharacterKeyMapping(key: .six, needsShift: true)
        case "&": return CharacterKeyMapping(key: .seven, needsShift: true)
        case "*": return CharacterKeyMapping(key: .eight, needsShift: true)
        case "(": return CharacterKeyMapping(key: .nine, needsShift: true)
        case ")": return CharacterKeyMapping(key: .zero, needsShift: true)
        case "_": return CharacterKeyMapping(key: .minus, needsShift: true)
        case "+": return CharacterKeyMapping(key: .equals, needsShift: true)
        case "{": return CharacterKeyMapping(key: .leftBracket, needsShift: true)
        case "}": return CharacterKeyMapping(key: .rightBracket, needsShift: true)
        case "|": return CharacterKeyMapping(key: .backslash, needsShift: true)
        case ":": return CharacterKeyMapping(key: .semicolon, needsShift: true)
        case "\"": return CharacterKeyMapping(key: .apostrophe, needsShift: true)
        case "~": return CharacterKeyMapping(key: .grave, needsShift: true)
        default: return nil
        }
    }

    // MARK: - JIS layout mappings

    private static func jisMapping(for character: Character) -> CharacterKeyMapping? {
        switch character {
        case ";": return CharacterKeyMapping(key: .semicolon, needsShift: false)
        case "@": return CharacterKeyMapping(key: .leftBracket, needsShift: false)
        case "[": return CharacterKeyMapping(key: .rightBracket, needsShift: false)
        case "]": return CharacterKeyMapping(key: .backslash, needsShift: false)
        case ":": return CharacterKeyMapping(key: .apostrophe, needsShift: false)
        case "^": return CharacterKeyMapping(key: .equals, needsShift: false)
        case "_": return CharacterKeyMapping(key: .jisUnderscore, needsShift: false)
        case "\\": return CharacterKeyMapping(key: .jisYen, needsShift: false)
        case "\"": return CharacterKeyMapping(key: .two, needsShift: true)
        case "&": return CharacterKeyMapping(key: .six, needsShift: true)
        case "'": return CharacterKeyMapping(key: .seven, needsShift: true)
        case "(": return CharacterKeyMapping(key: .eight, needsShift: true)
        case ")": return CharacterKeyMapping(key: .nine, needsShift: true)
        case "=": return CharacterKeyMapping(key: .minus, needsShift: true)
        case "~": return CharacterKeyMapping(key: .equals, needsShift: true)
        case "`": return CharacterKeyMapping(key: .leftBracket, needsShift: true)
        case "+": return CharacterKeyMapping(key: .semicolon, needsShift: true)
        case "*": return CharacterKeyMapping(key: .apostrophe, needsShift: true)
        case "{": return CharacterKeyMapping(key: .rightBracket, needsShift: true)
        case "}": return CharacterKeyMapping(key: .backslash, needsShift: true)
        case "|": return CharacterKeyMapping(key: .jisYen, needsShift: true)
        default: return nil
        }
    }
}
