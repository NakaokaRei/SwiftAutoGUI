import ArgumentParser
import SwiftAutoGUI
import Foundation

/// Accessibility-based GUI automation for the sagui CLI.
///
/// Wraps the `SwiftAutoGUI` AX API: press buttons by label, set text fields,
/// select menu items by path, raise windows, dump the AX tree, and find
/// elements by role. These commands are coordinate-free and tend to be more
/// robust than `sagui mouse` for cooperative apps.
///
/// ## Usage
///
/// ```bash
/// # Press a button in the frontmost app (case-insensitive contains match)
/// sagui ax press --label "5"
///
/// # Press a button in a specific app by bundle id
/// sagui ax press --label "Save" --bundle-id com.apple.TextEdit
///
/// # Set a text field's value
/// sagui ax set --role AXTextArea --value "hello" --bundle-id com.apple.TextEdit
///
/// # Select a menu item by path
/// sagui ax menu File "Save As…" --bundle-id com.apple.TextEdit
///
/// # Print the focused window's AX tree (useful for debugging)
/// sagui ax tree
///
/// # List elements by role in the frontmost app
/// sagui ax find --role AXButton
/// ```
///
/// ## Topics
///
/// ### Subcommands
/// - ``Press``
/// - ``Set``
/// - ``Menu``
/// - ``Tree``
/// - ``Find``
struct AXCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ax",
        abstract: "Accessibility-based GUI automation (semantic, coordinate-free).",
        subcommands: [Press.self, Set.self, Menu.self, Tree.self, Find.self]
    )
}

// MARK: - Shared option parsing

struct AppOption: ParsableArguments {
    @Option(name: .customLong("bundle-id"), help: "Target app bundle identifier (default: frontmost).")
    var bundleID: String?

    @Option(name: .customLong("pid"), help: "Target app process ID (default: frontmost).")
    var pid: Int32?

    func scope() -> AXAppScope {
        if let pid { return .pid(pid) }
        if let bundleID, !bundleID.isEmpty { return .bundleID(bundleID) }
        return .frontmost
    }
}

// MARK: - Subcommands

extension AXCommand {
    /// Press a button by accessibility label.
    struct Press: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Press a button by accessibility label."
        )

        @Option(help: "Label to match (case-insensitive contains by default).")
        var label: String

        @Flag(help: "Require exact label equality instead of contains match.")
        var exact = false

        @Flag(name: .customLong("ax-only"), help: "Skip the CGEvent click fallback if AX press fails.")
        var axOnly = false

        @OptionGroup var app: AppOption

        @MainActor
        func run() async throws {
            let success = await SwiftAutoGUI.pressButton(
                label: label,
                app: app.scope(),
                exact: exact,
                axOnly: axOnly
            )
            if !success {
                throw RuntimeError("No matching button or press failed.")
            }
        }
    }

    /// Set the value of a text field or text area.
    struct Set: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Set the value of a text field by label and/or role."
        )

        @Option(help: "Label to match (optional; if omitted, role-only match).")
        var label: String?

        @Option(help: "AX role to match (default: AXTextField; use AXTextArea for multi-line).")
        var role: String = "AXTextField"

        @Option(help: "New value to set.")
        var value: String

        @Flag(help: "Require exact label equality instead of contains match.")
        var exact = false

        @OptionGroup var app: AppOption

        @MainActor
        func run() async throws {
            let success = SwiftAutoGUI.setTextField(
                label: label,
                role: role,
                value: value,
                app: app.scope(),
                exact: exact
            )
            if !success {
                throw RuntimeError("No matching text field or set failed.")
            }
        }
    }

    /// Select a menu item by hierarchical path.
    struct Menu: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Select a menu item by path, e.g. 'sagui ax menu File \"Save As…\"'."
        )

        @Argument(help: "Path components: top-level menu, then submenu items.")
        var path: [String]

        @Flag(help: "Require exact label equality instead of contains match.")
        var exact = false

        @OptionGroup var app: AppOption

        @MainActor
        func run() async throws {
            guard !path.isEmpty else {
                throw ValidationError("Pass at least one path component, e.g. File 'Save As…'.")
            }
            let success = SwiftAutoGUI.selectMenuItem(
                path: path,
                app: app.scope(),
                exact: exact
            )
            if !success {
                throw RuntimeError("Menu item not found or pick failed.")
            }
        }
    }

    /// Print the accessibility tree of the focused window.
    struct Tree: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print the focused window's accessibility tree (debug aid)."
        )

        @Option(help: "Maximum tree depth.")
        var maxDepth: Int = 10

        @Option(help: "Maximum total nodes.")
        var maxNodes: Int = 1000

        @MainActor
        func run() async throws {
            let context = ScreenContextProvider.gather(options: .init(
                maxDepth: maxDepth,
                maxNodes: maxNodes
            ))
            print(context.formatted())
        }
    }

    /// List elements matching a role (and optional label) in the frontmost or
    /// chosen app. One per line: `<role>: <label>`.
    struct Find: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List elements matching a role and/or label."
        )

        @Option(help: "AX role to match (e.g. AXButton, AXTextField).")
        var role: String?

        @Option(help: "Label substring to match (case-insensitive contains).")
        var label: String?

        @Option(help: "Maximum results.")
        var limit: Int = 50

        @OptionGroup var app: AppOption

        @MainActor
        func run() async throws {
            let options = AXMatchOptions(
                labelMatch: label.map { .containsCaseInsensitive($0) }
            )
            let elements = AXSearch.findElements(role: role, options: options, scope: app.scope())
            for element in elements.prefix(limit) {
                let r = AXAction.role(of: element) ?? "AXUnknown"
                let l = AXAction.label(of: element) ?? ""
                print("\(r): \(l)")
            }
        }
    }
}

