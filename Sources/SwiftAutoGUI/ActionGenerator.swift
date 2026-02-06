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
enum BasicAction: Sendable {
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

    /// Convert to an executable ``Action``.
    func toAction() -> Action {
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
        }
    }
}

// MARK: - ActionGenerator

/// Generates automation actions from natural language prompts using AI.
///
/// `ActionGenerator` uses the Foundation Models framework to convert natural language
/// descriptions into executable ``Action`` instances. This enables AI-powered automation
/// where users can describe what they want to do in plain language.
///
/// ## Example Usage
///
/// ```swift
/// // Generate a single action from a prompt
/// let action = try await ActionGenerator.generateAction(from: "click at position 100, 200")
/// await action.execute()
///
/// // Generate multiple actions for a complex task
/// let actions = try await ActionGenerator.generateActionSequence(
///     from: "Click at 100, 100, wait 1 second, then type 'test'"
/// )
/// await actions.execute()
/// ```
///
/// ## Requirements
///
/// - macOS 26.0 or later
/// - Apple Intelligence enabled
///
@MainActor
public struct ActionGenerator: Sendable {

    /// Checks if the on-device language model is available.
    ///
    /// Use this method to verify model availability before attempting to generate actions.
    public static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Returns a human-readable message describing why the model is unavailable.
    ///
    /// - Returns: A message string if the model is unavailable, `nil` if available.
    public static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device does not support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence is not enabled. Please enable it in System Settings."
        case .unavailable(.modelNotReady):
            return "The model is still downloading or initializing. Please try again later."
        case .unavailable:
            return "The model is unavailable."
        }
    }

    /// Generates a single action from a natural language prompt.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: Any errors from the Foundation Models framework.
    public static func generateAction(from prompt: String) async throws -> Action {
        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt, generating: BasicAction.self)
        return response.content.toAction()
    }

    /// Generates multiple actions from a natural language prompt describing a sequence.
    ///
    /// - Parameter prompt: A natural language description of a multi-step task.
    /// - Returns: An array of ``Action`` instances representing the sequence.
    /// - Throws: Any errors from the Foundation Models framework.
    public static func generateActionSequence(from prompt: String) async throws -> [Action] {
        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt, generating: [BasicAction].self)
        return response.content.map { $0.toAction() }
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
    /// - Throws: Any errors from the Foundation Models framework.
    @MainActor
    public static func fromPrompt(_ prompt: String) async throws -> Action {
        return try await ActionGenerator.generateAction(from: prompt)
    }
}
