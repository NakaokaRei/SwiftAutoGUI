//
//  FoundationModelsBackend.swift
//  SwiftAutoGUI
//

import Foundation
import FoundationModels

// MARK: - FoundationModelsBackend

/// An ``ActionGenerating`` backend that uses Apple's on-device Foundation Models.
///
/// This is the default backend for ``ActionGenerator``. It uses the Foundation Models
/// framework to convert natural language prompts into actions entirely on-device.
///
/// ## Requirements
///
/// - macOS 26.0 or later
/// - Apple Intelligence enabled on the device
///
/// ## Example
///
/// ```swift
/// let backend = FoundationModelsBackend()
/// guard backend.isAvailable else {
///     print(backend.unavailableReason ?? "Unavailable")
///     return
/// }
/// let action = try await backend.generateAction(from: "click at 100, 200")
/// ```
@MainActor
public struct FoundationModelsBackend: @preconcurrency ActionGenerating, Sendable {

    public init() {}

    public var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    public var unavailableReason: String? {
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

    public func generateAction(from prompt: String) async throws -> Action {
        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt, generating: BasicAction.self)
        return response.content.toAction()
    }

    public func generateActionSequence(from prompt: String) async throws -> [Action] {
        let session = LanguageModelSession(model: .default)
        let response = try await session.respond(to: prompt, generating: [BasicAction].self)
        return response.content.map { $0.toAction() }
    }
}
