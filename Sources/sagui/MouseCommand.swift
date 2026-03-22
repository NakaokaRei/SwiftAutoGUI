import ArgumentParser
import SwiftAutoGUI
import CoreGraphics

struct MouseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mouse",
        abstract: "Mouse control commands.",
        subcommands: [Position.self, Move.self, MoveRelative.self, Click.self, Drag.self, Scroll.self]
    )
}

extension MouseCommand {
    struct Position: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Print the current mouse cursor position."
        )

        func run() async throws {
            let pos = SwiftAutoGUI.position()
            print("\(pos.x) \(pos.y)")
        }
    }

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
