//
//  ActionGenerating.swift
//  SwiftAutoGUI
//

import Foundation

// MARK: - ActionGenerating Protocol

/// A protocol for backends that generate automation actions from natural language prompts.
///
/// Conform to this protocol to implement a custom action generation backend.
/// SwiftAutoGUI provides two built-in backends:
/// - ``FoundationModelsBackend``: Uses Apple's on-device Foundation Models (default)
/// - ``OpenAIBackend``: Uses the OpenAI API
///
/// ## Example
///
/// ```swift
/// let backend: any ActionGenerating = OpenAIBackend(apiKey: "sk-...")
/// let action = try await backend.generateAction(from: "click at 100, 200")
/// await action.execute()
/// ```
public protocol ActionGenerating: Sendable {
    /// Whether this backend is currently available for generating actions.
    var isAvailable: Bool { get }

    /// A human-readable message describing why the backend is unavailable.
    ///
    /// Returns `nil` if the backend is available.
    var unavailableReason: String? { get }

    /// Generates a single action from a natural language prompt.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    func generateAction(from prompt: String) async throws -> Action

    /// Generates multiple actions from a natural language prompt describing a sequence.
    ///
    /// - Parameter prompt: A natural language description of a multi-step task.
    /// - Returns: An array of ``Action`` instances representing the sequence.
    /// - Throws: ``ActionGeneratorError`` or backend-specific errors.
    func generateActionSequence(from prompt: String) async throws -> [Action]
}

// MARK: - ActionGeneratorError

/// Errors that can occur during action generation.
public enum ActionGeneratorError: Error, LocalizedError, Sendable {
    /// No actions were generated from the given prompt.
    case noActionsGenerated

    /// The backend is unavailable.
    case backendUnavailable(reason: String)

    /// The response from the backend could not be parsed.
    case invalidResponse(detail: String)

    public var errorDescription: String? {
        switch self {
        case .noActionsGenerated:
            return "No actions were generated from the given prompt."
        case .backendUnavailable(let reason):
            return "Backend is unavailable: \(reason)"
        case .invalidResponse(let detail):
            return "Invalid response: \(detail)"
        }
    }
}
