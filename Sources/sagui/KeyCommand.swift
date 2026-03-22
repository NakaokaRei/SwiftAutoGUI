import ArgumentParser
import SwiftAutoGUI

/// Keyboard control commands for the sagui CLI.
///
/// Provides subcommands for sending keyboard shortcuts, pressing and releasing
/// individual keys, and typing text strings.
///
/// ## Usage
///
/// ```bash
/// # Send a keyboard shortcut
/// sagui key shortcut command c
///
/// # Type text
/// sagui key type "Hello, World!"
///
/// # Press and release a key
/// sagui key down shift
/// sagui key up shift
/// ```
///
/// ## Topics
///
/// ### Subcommands
/// - ``Shortcut``
/// - ``Down``
/// - ``Up``
/// - ``TypeText``
struct KeyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "key",
        abstract: "Keyboard control commands.",
        subcommands: [Shortcut.self, Down.self, Up.self, TypeText.self]
    )
}

extension KeyCommand {
    /// Send a keyboard shortcut by pressing multiple keys simultaneously.
    ///
    /// Keys are specified by their ``Key`` raw values. Multiple keys are pressed together
    /// as a single shortcut combination.
    ///
    /// ```bash
    /// sagui key shortcut command shift a
    /// sagui key shortcut command c
    /// ```
    ///
    /// - Parameter keys: Key names to press together (e.g., `command`, `shift`, `a`).
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

    /// Press a key down without releasing it.
    ///
    /// Useful for holding modifier keys while performing other actions.
    /// Use ``Up`` to release the key.
    ///
    /// ```bash
    /// sagui key down shift
    /// ```
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

    /// Release a previously pressed key.
    ///
    /// Use this to release a key that was held down with ``Down``.
    ///
    /// ```bash
    /// sagui key up shift
    /// ```
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

    /// Type a text string character by character.
    ///
    /// Simulates typing each character in the given text. An optional interval
    /// can be specified to add a delay between keystrokes.
    ///
    /// ```bash
    /// sagui key type "Hello, World!"
    /// sagui key type "slow typing" --interval 0.1
    /// ```
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
