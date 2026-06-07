//
//  ActionGenerator.swift
//  SwiftAutoGUI
//

import Foundation
import FoundationModels

// MARK: - BasicAction (Lightweight @Generable type for on-device model)

/// A lightweight action type for AI generation.
///
/// This type is intentionally kept small to fit within the on-device model's
/// context window. It covers common automation operations and converts to
/// the full ``Action`` type via ``toAction()``.
@Generable
public enum BasicAction: Sendable, Codable {
    /// Type text.
    case write(text: String)

    /// Move mouse to absolute position.
    case move(x: Double, y: Double)

    /// Left click at current position.
    case leftClick

    /// Right click at current position.
    case rightClick

    /// Double click at current position.
    case doubleClick

    /// Scroll vertically. Positive values scroll up, negative values scroll down.
    case vscroll(clicks: Int)

    /// Scroll horizontally. Positive values scroll right, negative values scroll left.
    case hscroll(clicks: Int)

    /// Wait for a duration in seconds.
    case wait(duration: Double)

    /// Press a keyboard shortcut. Use key names like "command", "shift", "a", "c", "returnKey", "space", "delete", "tab", "escape", "upArrow", "downArrow", "leftArrow", "rightArrow".
    case keyShortcut(keys: [String])

    /// Drag mouse from one position to another.
    case drag(fromX: Double, fromY: Double, toX: Double, toY: Double)

    /// Press a button by accessibility label. `bundleID` is empty to target the
    /// frontmost app; otherwise pass a value like "com.apple.calculator".
    case pressButton(label: String, bundleID: String)

    /// Set a text field's value via the accessibility API.
    /// `label` may be empty to match by role only. `bundleID` empty = frontmost.
    case setTextField(label: String, value: String, bundleID: String)

    /// Select a menu item by hierarchical path, e.g. `["File", "Save As…"]`.
    case selectMenuItem(path: [String], bundleID: String)

    /// Bring a window to the front by title.
    case raiseWindow(title: String, bundleID: String)

    /// Convert to an executable ``Action``.
    public func toAction() -> Action {
        switch self {
        case .write(let text):
            return .write(text)
        case .move(let x, let y):
            return .move(to: CGPoint(x: x, y: y))
        case .leftClick:
            return .leftClick
        case .rightClick:
            return .rightClick
        case .doubleClick:
            return .doubleClick()
        case .vscroll(let clicks):
            return .vscroll(clicks: clicks)
        case .hscroll(let clicks):
            return .hscroll(clicks: clicks)
        case .wait(let duration):
            return .wait(duration)
        case .keyShortcut(let keys):
            let mapped = keys.compactMap { Key(rawValue: $0) }
            guard !mapped.isEmpty else { return .wait(0) }
            return .keyShortcut(mapped)
        case .drag(let fromX, let fromY, let toX, let toY):
            return .drag(from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
        case .pressButton(let label, let bundleID):
            return .pressButton(label: label, app: scope(bundleID))
        case .setTextField(let label, let value, let bundleID):
            return .setTextField(
                label: label.isEmpty ? nil : label,
                value: value,
                app: scope(bundleID)
            )
        case .selectMenuItem(let path, let bundleID):
            return .selectMenuItem(path: path, app: scope(bundleID))
        case .raiseWindow(let title, let bundleID):
            return .raiseWindow(title: title, app: scope(bundleID))
        }
    }

    private func scope(_ bundleID: String) -> AXAppScope {
        bundleID.isEmpty ? .frontmost : .bundleID(bundleID)
    }

    // MARK: - Tagged Union Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case text, x, y, clicks, duration, keys
        case fromX, fromY, toX, toY
        case label, value, path, title, bundleID
    }

    private enum ActionType: String, Codable {
        case write, move, leftClick, rightClick, doubleClick
        case vscroll, hscroll, wait, keyShortcut, drag
        case pressButton, setTextField, selectMenuItem, raiseWindow
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
        case .write:
            let text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self = .write(text: text)
        case .move:
            let x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
            let y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
            self = .move(x: x, y: y)
        case .leftClick:
            self = .leftClick
        case .rightClick:
            self = .rightClick
        case .doubleClick:
            self = .doubleClick
        case .vscroll:
            let clicks = try container.decodeIfPresent(Int.self, forKey: .clicks) ?? 0
            self = .vscroll(clicks: clicks)
        case .hscroll:
            let clicks = try container.decodeIfPresent(Int.self, forKey: .clicks) ?? 0
            self = .hscroll(clicks: clicks)
        case .wait:
            let duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 0
            self = .wait(duration: duration)
        case .keyShortcut:
            let keys = try container.decodeIfPresent([String].self, forKey: .keys) ?? []
            self = .keyShortcut(keys: keys)
        case .drag:
            let fromX = try container.decodeIfPresent(Double.self, forKey: .fromX) ?? 0
            let fromY = try container.decodeIfPresent(Double.self, forKey: .fromY) ?? 0
            let toX = try container.decodeIfPresent(Double.self, forKey: .toX) ?? 0
            let toY = try container.decodeIfPresent(Double.self, forKey: .toY) ?? 0
            self = .drag(fromX: fromX, fromY: fromY, toX: toX, toY: toY)
        case .pressButton:
            let label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .pressButton(label: label, bundleID: bundleID)
        case .setTextField:
            let label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
            let value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .setTextField(label: label, value: value, bundleID: bundleID)
        case .selectMenuItem:
            let path = try container.decodeIfPresent([String].self, forKey: .path) ?? []
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .selectMenuItem(path: path, bundleID: bundleID)
        case .raiseWindow:
            let title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .raiseWindow(title: title, bundleID: bundleID)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .write(let text):
            try container.encode(ActionType.write, forKey: .type)
            try container.encode(text, forKey: .text)
        case .move(let x, let y):
            try container.encode(ActionType.move, forKey: .type)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
        case .leftClick:
            try container.encode(ActionType.leftClick, forKey: .type)
        case .rightClick:
            try container.encode(ActionType.rightClick, forKey: .type)
        case .doubleClick:
            try container.encode(ActionType.doubleClick, forKey: .type)
        case .vscroll(let clicks):
            try container.encode(ActionType.vscroll, forKey: .type)
            try container.encode(clicks, forKey: .clicks)
        case .hscroll(let clicks):
            try container.encode(ActionType.hscroll, forKey: .type)
            try container.encode(clicks, forKey: .clicks)
        case .wait(let duration):
            try container.encode(ActionType.wait, forKey: .type)
            try container.encode(duration, forKey: .duration)
        case .keyShortcut(let keys):
            try container.encode(ActionType.keyShortcut, forKey: .type)
            try container.encode(keys, forKey: .keys)
        case .drag(let fromX, let fromY, let toX, let toY):
            try container.encode(ActionType.drag, forKey: .type)
            try container.encode(fromX, forKey: .fromX)
            try container.encode(fromY, forKey: .fromY)
            try container.encode(toX, forKey: .toX)
            try container.encode(toY, forKey: .toY)
        case .pressButton(let label, let bundleID):
            try container.encode(ActionType.pressButton, forKey: .type)
            try container.encode(label, forKey: .label)
            try container.encode(bundleID, forKey: .bundleID)
        case .setTextField(let label, let value, let bundleID):
            try container.encode(ActionType.setTextField, forKey: .type)
            try container.encode(label, forKey: .label)
            try container.encode(value, forKey: .value)
            try container.encode(bundleID, forKey: .bundleID)
        case .selectMenuItem(let path, let bundleID):
            try container.encode(ActionType.selectMenuItem, forKey: .type)
            try container.encode(path, forKey: .path)
            try container.encode(bundleID, forKey: .bundleID)
        case .raiseWindow(let title, let bundleID):
            try container.encode(ActionType.raiseWindow, forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(bundleID, forKey: .bundleID)
        }
    }
}

// MARK: - ActionGenerator

/// Generates automation actions from natural language prompts using AI.
///
/// `ActionGenerator` uses AI backends to convert natural language
/// descriptions into executable ``Action`` instances. This enables AI-powered automation
/// where users can describe what they want to do in plain language.
///
/// ## Example Usage
///
/// ```swift
/// // Generate a single action from a prompt (uses default backend)
/// let action = try await ActionGenerator.generateAction(from: "click at position 100, 200")
/// await action.execute()
///
/// // Generate multiple actions for a complex task
/// let actions = try await ActionGenerator.generateActionSequence(
///     from: "Click at 100, 100, wait 1 second, then type 'test'"
/// )
/// await actions.execute()
///
/// // Use a specific backend
/// let generator = ActionGenerator(openAIKey: "sk-...")
/// let actions = try await generator.generateActionSequence(from: "type hello")
/// ```
///
/// ## Requirements
///
/// - macOS 26.0 or later
/// - For Foundation Models backend: Apple Intelligence enabled
/// - For OpenAI backend: Valid API key
///
public struct ActionGenerator: Sendable {

    /// The default backend used by static methods.
    ///
    /// Defaults to ``FoundationModelsBackend``. Change this to use a different
    /// backend globally:
    ///
    /// ```swift
    /// ActionGenerator.defaultBackend = OpenAIBackend(apiKey: "sk-...")
    /// ```
    @MainActor
    public static var defaultBackend: any ActionGenerating = FoundationModelsBackend()

    /// The backend used by this instance.
    public let backend: any ActionGenerating

    /// Creates an ActionGenerator with the specified backend.
    ///
    /// - Parameter backend: The backend to use for action generation.
    public init(backend: any ActionGenerating) {
        self.backend = backend
    }

    /// Creates an ActionGenerator using the OpenAI backend.
    ///
    /// - Parameters:
    ///   - openAIKey: Your OpenAI API key.
    ///   - model: The model to use (default: `gpt-4.1-nano`).
    public init(openAIKey: String, model: String = "gpt-4.1-nano") {
        self.backend = OpenAIBackend(apiKey: openAIKey, model: model)
    }

    // MARK: - Instance Methods

    /// Generates a single action from a natural language prompt using this instance's backend.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    public func generateAction(from prompt: String) async throws -> Action {
        try await backend.generateAction(from: prompt)
    }

    /// Generates multiple actions from a natural language prompt using this instance's backend.
    ///
    /// - Parameter prompt: A natural language description of a multi-step task.
    /// - Returns: An array of ``Action`` instances representing the sequence.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    public func generateActionSequence(from prompt: String) async throws -> [Action] {
        try await backend.generateActionSequence(from: prompt)
    }

    // MARK: - Static Methods (backward compatible, delegate to defaultBackend)

    /// Checks if the default backend is available.
    ///
    /// Use this method to verify backend availability before attempting to generate actions.
    @MainActor
    public static var isAvailable: Bool {
        defaultBackend.isAvailable
    }

    /// Returns a human-readable message describing why the default backend is unavailable.
    ///
    /// - Returns: A message string if the backend is unavailable, `nil` if available.
    @MainActor
    public static var unavailableReason: String? {
        defaultBackend.unavailableReason
    }

    /// Generates a single action from a natural language prompt using the default backend.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    @MainActor
    public static func generateAction(from prompt: String) async throws -> Action {
        try await defaultBackend.generateAction(from: prompt)
    }

    /// Generates multiple actions from a natural language prompt using the default backend.
    ///
    /// - Parameter prompt: A natural language description of a multi-step task.
    /// - Returns: An array of ``Action`` instances representing the sequence.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    @MainActor
    public static func generateActionSequence(from prompt: String) async throws -> [Action] {
        try await defaultBackend.generateActionSequence(from: prompt)
    }
}

// MARK: - Convenience Extensions

extension Action {
    /// Generates an action from a natural language prompt.
    ///
    /// This is a convenience method that uses ``ActionGenerator`` to generate a single action.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: Any errors from the action generation backend.
    @MainActor
    public static func fromPrompt(_ prompt: String) async throws -> Action {
        return try await ActionGenerator.generateAction(from: prompt)
    }
}
