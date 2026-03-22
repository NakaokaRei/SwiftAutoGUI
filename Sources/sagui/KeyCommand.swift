import ArgumentParser
import SwiftAutoGUI

struct KeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "key",
        abstract: "Keyboard control commands.",
        subcommands: [Shortcut.self, Down.self, Up.self, TypeText.self]
    )
}

extension KeyCommand {
    struct Shortcut: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Send a keyboard shortcut (e.g., sagui key shortcut command c)."
        )

        @Argument(help: "Key names to press together (e.g., command shift a).")
        var keys: [String]

        func run() async throws {
            let mapped = try keys.map { name -> Key in
                guard let key = Key(rawValue: name) else {
                    throw ValidationError("Unknown key: '\(name)'. Examples: a, command, shift, leftArrow, space, f1")
                }
                return key
            }
            await SwiftAutoGUI.sendKeyShortcut(mapped)
        }
    }

    struct Down: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Press a key down without releasing."
        )

        @Argument(help: "Key name (e.g., command, shift, a).")
        var key: String

        func run() async throws {
            guard let k = Key(rawValue: key) else {
                throw ValidationError("Unknown key: '\(key)'. Examples: a, command, shift, leftArrow, space, f1")
            }
            await SwiftAutoGUI.keyDown(k)
        }
    }

    struct Up: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Release a pressed key."
        )

        @Argument(help: "Key name (e.g., command, shift, a).")
        var key: String

        func run() async throws {
            guard let k = Key(rawValue: key) else {
                throw ValidationError("Unknown key: '\(key)'. Examples: a, command, shift, leftArrow, space, f1")
            }
            await SwiftAutoGUI.keyUp(k)
        }
    }

    struct TypeText: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "type",
            abstract: "Type a text string."
        )

        @Argument(help: "The text to type.")
        var text: String

        @Option(help: "Delay between keystrokes in seconds.")
        var interval: Double = 0

        @MainActor
        func run() async throws {
            await SwiftAutoGUI.write(text, interval: interval)
        }
    }
}
