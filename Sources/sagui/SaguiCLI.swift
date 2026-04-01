import ArgumentParser

/// A command-line tool for controlling the mouse and keyboard on macOS.
///
/// `sagui` provides a CLI interface to the SwiftAutoGUI library, enabling GUI automation
/// from the terminal or shell scripts. It supports keyboard input, mouse control,
/// and screen capture operations.
///
/// ## Usage
///
/// ```bash
/// # Keyboard shortcuts
/// sagui key shortcut command c
///
/// # Mouse movement
/// sagui mouse move --x 100 --y 200
///
/// # Take a screenshot
/// sagui screen screenshot --output capture.png
/// ```
///
/// > Note: Requires accessibility permissions in System Settings > Privacy & Security > Accessibility.
///
/// ## Topics
///
/// ### Subcommands
/// - ``KeyCommand``
/// - ``MouseCommand``
/// - ``ScreenCommand``
@main
struct SaguiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sagui",
        abstract: "Control mouse and keyboard on macOS from the command line.",
        discussion: "Requires accessibility permissions in System Settings > Privacy & Security > Accessibility.",
        subcommands: [KeyCommand.self, MouseCommand.self, ScreenCommand.self, AgentCommand.self]
    )
}
