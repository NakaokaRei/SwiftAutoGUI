import CoreGraphics

/// Keycode for keyboard input
///
/// Example
/// ```swift
/// // Send ctrl + ←
/// import SwiftAutoGUI
/// SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
///
/// // Send sound up
/// SwiftAutoGUI.keyDown(.soundUp)
/// SwiftAutoGUI.keyUp(.soundUp)
/// ```
public enum Key: String {

    // normal keycode
    case returnKey
    case enter
    case tab
    case space
    case delete
    case escape
    case command
    case shift
    case capsLock
    case option
    case control
    case rightShift
    case rightOption
    case rightControl
    case leftArrow
    case rightArrow
    case downArrow
    case upArrow
    case volumeUp
    case volumeDown
    case mute
    case help
    case home
    case pageUp
    case forwardDelete
    case end
    case pageDown
    case function
    case f1
    case f2
    case f4
    case f5
    case f6
    case f7
    case f3
    case f8
    case f9
    case f10
    case f11
    case f12
    case f13
    case f14
    case f15
    case f16
    case f17
    case f18
    case f19
    case f20

    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    case zero
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine

    case equals
    case minus
    case semicolon
    case apostrophe
    case comma
    case period
    case forwardSlash
    case backslash
    case grave
    case leftBracket
    case rightBracket

    case keypadDecimal
    case keypadMultiply
    case keypadPlus
    case keypadClear
    case keypadDivide
    case keypadEnter
    case keypadMinus
    case keypadEquals
    case keypad0
    case keypad1
    case keypad2
    case keypad3
    case keypad4
    case keypad5
    case keypad6
    case keypad7
    case keypad8
    case keypad9

    // special keycode
    // TODO: add other code
    case soundUp
    case soundDown
    case brightnessUp
    case brightnessDown
    case numLock


    /// Normal keycode of the key.
    public var normalKeycode: CGKeyCode? {
        switch self {
        case .returnKey      : return 0x24
        case .enter          : return 0x4C
        case .tab            : return 0x30
        case .space          : return 0x31
        case .delete         : return 0x33
        case .escape         : return 0x35
        case .command        : return 0x37
        case .shift          : return 0x38
        case .capsLock       : return 0x39
        case .option         : return 0x3A
        case .control        : return 0x3B
        case .rightShift     : return 0x3C
        case .rightOption    : return 0x3D
        case .rightControl   : return 0x3E
        case .leftArrow      : return 0x7B
        case .rightArrow     : return 0x7C
        case .downArrow      : return 0x7D
        case .upArrow        : return 0x7E
        case .volumeUp       : return 0x48
        case .volumeDown     : return 0x49
        case .mute           : return 0x4A
        case .help           : return 0x72
        case .home           : return 0x73
        case .pageUp         : return 0x74
        case .forwardDelete  : return 0x75
        case .end            : return 0x77
        case .pageDown       : return 0x79
        case .function       : return 0x3F
        case .f1             : return 0x7A
        case .f2             : return 0x78
        case .f4             : return 0x76
        case .f5             : return 0x60
        case .f6             : return 0x61
        case .f7             : return 0x62
        case .f3             : return 0x63
        case .f8             : return 0x64
        case .f9             : return 0x65
        case .f10            : return 0x6D
        case .f11            : return 0x67
        case .f12            : return 0x6F
        case .f13            : return 0x69
        case .f14            : return 0x6B
        case .f15            : return 0x71
        case .f16            : return 0x6A
        case .f17            : return 0x40
        case .f18            : return 0x4F
        case .f19            : return 0x50
        case .f20            : return 0x5A

        case .a              : return 0x00
        case .b              : return 0x0B
        case .c              : return 0x08
        case .d              : return 0x02
        case .e              : return 0x0E
        case .f              : return 0x03
        case .g              : return 0x05
        case .h              : return 0x04
        case .i              : return 0x22
        case .j              : return 0x26
        case .k              : return 0x28
        case .l              : return 0x25
        case .m              : return 0x2E
        case .n              : return 0x2D
        case .o              : return 0x1F
        case .p              : return 0x23
        case .q              : return 0x0C
        case .r              : return 0x0F
        case .s              : return 0x01
        case .t              : return 0x11
        case .u              : return 0x20
        case .v              : return 0x09
        case .w              : return 0x0D
        case .x              : return 0x07
        case .y              : return 0x10
        case .z              : return 0x06

        case .zero           : return 0x1D
        case .one            : return 0x12
        case .two            : return 0x13
        case .three          : return 0x14
        case .four           : return 0x15
        case .five           : return 0x17
        case .six            : return 0x16
        case .seven          : return 0x1A
        case .eight          : return 0x1C
        case .nine           : return 0x19

        case .equals         : return 0x18
        case .minus          : return 0x1B
        case .semicolon      : return 0x29
        case .apostrophe     : return 0x27
        case .comma          : return 0x2B
        case .period         : return 0x2F
        case .forwardSlash   : return 0x2C
        case .backslash      : return 0x2A
        case .grave          : return 0x32
        case .leftBracket    : return 0x21
        case .rightBracket   : return 0x1E

        case .keypadDecimal  : return 0x41
        case .keypadMultiply : return 0x43
        case .keypadPlus     : return 0x45
        case .keypadClear    : return 0x47
        case .keypadDivide   : return 0x4B
        case .keypadEnter    : return 0x4C
        case .keypadMinus    : return 0x4E
        case .keypadEquals   : return 0x51
        case .keypad0        : return 0x52
        case .keypad1        : return 0x53
        case .keypad2        : return 0x54
        case .keypad3        : return 0x55
        case .keypad4        : return 0x56
        case .keypad5        : return 0x57
        case .keypad6        : return 0x58
        case .keypad7        : return 0x59
        case .keypad8        : return 0x5B
        case .keypad9        : return 0x5C
        default              : return nil
        }
    }

    /// Special keycodes for media keys and other special keys
    public var specialKeycode: Int32? {
        switch self {
        case .soundUp        : return NX_KEYTYPE_SOUND_UP
        case .soundDown      : return NX_KEYTYPE_SOUND_DOWN
        case .brightnessUp   : return NX_KEYTYPE_BRIGHTNESS_UP
        case .brightnessDown : return NX_KEYTYPE_BRIGHTNESS_DOWN
        case .numLock        : return NX_KEYTYPE_NUM_LOCK
        default              : return nil
        }
    }
}
