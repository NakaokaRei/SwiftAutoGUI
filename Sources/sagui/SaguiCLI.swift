import ArgumentParser

@main
struct SaguiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sagui",
        abstract: "Control mouse and keyboard on macOS from the command line.",
        discussion: "Requires accessibility permissions in System Settings > Privacy & Security > Accessibility.",
        subcommands: [KeyCommand.self, MouseCommand.self, ScreenCommand.self]
    )
}
