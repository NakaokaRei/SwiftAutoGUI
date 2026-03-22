import ArgumentParser
import SwiftAutoGUI
import CoreGraphics

/// Mouse control commands for the sagui CLI.
///
/// Provides subcommands for querying the cursor position, moving the mouse,
/// clicking, dragging, and scrolling.
///
/// ## Usage
///
/// ```bash
/// # Get current mouse position
/// sagui mouse position
///
/// # Move to absolute coordinates
/// sagui mouse move --x 100 --y 200
///
/// # Click at the current position
/// sagui mouse click
/// sagui mouse click --right
///
/// # Scroll
/// sagui mouse scroll --vertical 5
/// ```
///
/// ## Topics
///
/// ### Subcommands
/// - ``Position``
/// - ``Move``
/// - ``MoveRelative``
/// - ``Click``
/// - ``Drag``
/// - ``Scroll``
struct MouseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mouse",
        abstract: "Mouse control commands.",
        subcommands: [Position.self, Move.self, MoveRelative.self, Click.self, Drag.self, Scroll.self]
    )
}

extension MouseCommand {
    /// Print the current mouse cursor position.
    ///
    /// Outputs the X and Y coordinates separated by a space.
    ///
    /// ```bash
    /// sagui mouse position
    /// # Output: 512.0 384.0
    /// ```
    struct Position: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print the current mouse cursor position."
        )

        func run() async throws {
            let pos = SwiftAutoGUI.position()
            print("\(pos.x) \(pos.y)")
        }
    }

    /// Move the mouse cursor to an absolute screen position.
    ///
    /// Coordinates use the macOS screen coordinate system where the origin (0, 0)
    /// is at the top-left corner of the main display.
    ///
    /// ```bash
    /// sagui mouse move --x 100 --y 200
    /// ```
    struct Move: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Move the mouse to an absolute position."
        )

        @Option(help: "X coordinate.")
        var x: Double

        @Option(help: "Y coordinate.")
        var y: Double

        func run() async throws {
            await SwiftAutoGUI.move(to: CGPoint(x: x, y: y), duration: 0)
        }
    }

    /// Move the mouse cursor relative to its current position.
    ///
    /// Positive `dx` moves right, positive `dy` moves down.
    ///
    /// ```bash
    /// sagui mouse move-relative --dx 50 --dy -30
    /// ```
    struct MoveRelative: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "move-relative",
            abstract: "Move the mouse relative to its current position."
        )

        @Option(help: "Horizontal distance (positive = right).")
        var dx: Double

        @Option(help: "Vertical distance (positive = down).")
        var dy: Double

        func run() async throws {
            await SwiftAutoGUI.moveMouse(dx: dx, dy: dy)
        }
    }

    /// Click the mouse at the current cursor position.
    ///
    /// Supports left click (default), right click, double-click, and triple-click.
    ///
    /// ```bash
    /// sagui mouse click              # Left click
    /// sagui mouse click --right      # Right click
    /// sagui mouse click --double     # Double click
    /// sagui mouse click --triple     # Triple click
    /// ```
    struct Click: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Click the mouse at the current position."
        )

        @Flag(help: "Use right mouse button.")
        var right = false

        @Flag(name: .long, help: "Perform a double-click.")
        var double = false

        @Flag(name: .long, help: "Perform a triple-click.")
        var triple = false

        func run() async throws {
            let button: SwiftAutoGUI.MouseButton = right ? .right : .left

            if triple {
                await SwiftAutoGUI.tripleClick(button: button)
            } else if double {
                await SwiftAutoGUI.doubleClick(button: button)
            } else {
                if right {
                    SwiftAutoGUI.rightClick()
                } else {
                    SwiftAutoGUI.leftClick()
                }
            }
        }
    }

    /// Drag the mouse from one position to another.
    ///
    /// Performs a left-button drag from the start coordinates to the end coordinates.
    ///
    /// ```bash
    /// sagui mouse drag --from-x 100 --from-y 100 --to-x 300 --to-y 300
    /// ```
    struct Drag: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Drag the mouse from one position to another."
        )

        @Option(name: .customLong("from-x"), help: "Start X coordinate.")
        var fromX: Double

        @Option(name: .customLong("from-y"), help: "Start Y coordinate.")
        var fromY: Double

        @Option(name: .customLong("to-x"), help: "End X coordinate.")
        var toX: Double

        @Option(name: .customLong("to-y"), help: "End Y coordinate.")
        var toY: Double

        func run() async throws {
            SwiftAutoGUI.leftDragged(
                to: CGPoint(x: toX, y: toY),
                from: CGPoint(x: fromX, y: fromY)
            )
        }
    }

    /// Scroll the mouse wheel vertically or horizontally.
    ///
    /// At least one of `--vertical` or `--horizontal` must be specified.
    /// For vertical scrolling, positive values scroll up and negative values scroll down.
    /// For horizontal scrolling, positive values scroll left and negative values scroll right.
    ///
    /// ```bash
    /// sagui mouse scroll --vertical 5       # Scroll up
    /// sagui mouse scroll --vertical -3      # Scroll down
    /// sagui mouse scroll --horizontal 2     # Scroll left
    /// ```
    struct Scroll: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Scroll the mouse wheel."
        )

        @Option(help: "Vertical scroll clicks (positive = up, negative = down).")
        var vertical: Int?

        @Option(help: "Horizontal scroll clicks (positive = left, negative = right).")
        var horizontal: Int?

        func validate() throws {
            if vertical == nil && horizontal == nil {
                throw ValidationError("Specify at least one of --vertical or --horizontal.")
            }
        }

        func run() async throws {
            if let v = vertical {
                SwiftAutoGUI.vscroll(clicks: v)
            }
            if let h = horizontal {
                SwiftAutoGUI.hscroll(clicks: h)
            }
        }
    }
}
