import Foundation
import FoundationModels

/// Limits retained conversation state. Current instructions, goal, observation,
/// and latest execution results are never truncated to force a request to fit.
public struct AgentHistoryPolicy: Sendable {
    public var maximumTurns: Int
    public var maximumCharacters: Int

    public init(maximumTurns: Int = 4, maximumCharacters: Int = 12_000) {
        self.maximumTurns = maximumTurns
        self.maximumCharacters = maximumCharacters
    }
}

/// Owns a session and serializes requests. It is private to one Agent run or
/// one independent ActionGenerator request; no conversation state is shared.
actor ActionSession {
    private var model: any LanguageModel
    private var fallbackModel: (any LanguageModel)?
    private let instructions: String
    private let historyPolicy: AgentHistoryPolicy
    private let options: GenerationOptions
    private let contextOptions: ContextOptions
    private var session: LanguageModelSession
    private var responding = false
    private var usingFallback = false

    init(
        model: some LanguageModel,
        fallbackModel: (any LanguageModel)? = nil,
        instructions: String,
        historyPolicy: AgentHistoryPolicy = .init(),
        options: GenerationOptions = .init(),
        contextOptions: ContextOptions = .init()
    ) {
        self.model = model
        self.fallbackModel = fallbackModel
        self.instructions = instructions
        self.historyPolicy = historyPolicy
        self.options = options
        self.contextOptions = contextOptions
        self.session = LanguageModelSession(model: model, instructions: instructions)
    }

    func respond<Content: Generable & Sendable>(
        to prompt: Prompt,
        generating: Content.Type,
        includesImage: Bool = false,
        discardHistory: Bool = false
    ) async throws -> Content {
        guard !responding else { throw LanguageModelSession.Error.concurrentRequests }
        guard historyPolicy.maximumTurns >= 0, historyPolicy.maximumCharacters >= 0 else {
            throw ActionGeneratorError.invalidConfiguration("History limits must be nonnegative.")
        }
        responding = true
        defer { responding = false }
        try Task.checkCancellation()
        if discardHistory { resetSession() }
        compactHistory()
        var recoveredContext = false
        while true {
            do {
                try validate(includesImage: includesImage)
                try await fitOnDevice(prompt: prompt, schema: Content.generationSchema)
                let response = try await session.respond(
                    to: prompt, generating: Content.self,
                    options: options,
                    contextOptions: model.capabilities.contains(.reasoning) ? contextOptions : .init()
                )
                try Task.checkCancellation()
                return response.content
            } catch {
                try Task.checkCancellation()
                if Self.isContextError(error), !recoveredContext,
                   !session.transcript.history.isEmpty {
                    // Retry generation only. The caller has not executed this decision.
                    resetSession()
                    recoveredContext = true
                    continue
                }
                if Self.canFallback(after: error), let fallbackModel {
                    self.fallbackModel = nil // A single, explicitly configured transition.
                    model = fallbackModel
                    usingFallback = true
                    resetSession() // Never forward a 32K cloud transcript to a 4K model.
                    recoveredContext = false
                    continue
                }
                throw error
            }
        }
    }

    private func validate(includesImage: Bool) throws {
        if let reason = AutomationModels.unavailableReason(for: model) {
            throw ActionGeneratorError.backendUnavailable(reason: reason)
        }
        guard model.capabilities.contains(.guidedGeneration) else {
            throw ActionGeneratorError.unsupportedCapability("guided generation")
        }
        if !usingFallback, contextOptions.reasoningLevel != nil,
           !model.capabilities.contains(.reasoning) {
            throw ActionGeneratorError.unsupportedCapability("configurable reasoning")
        }
        if includesImage, !model.capabilities.contains(.vision) {
            throw ActionGeneratorError.unsupportedCapability("vision")
        }
    }

    private func resetSession() {
        session = LanguageModelSession(model: model, instructions: instructions)
    }

    private func fitOnDevice(prompt: Prompt, schema: GenerationSchema) async throws {
        guard let system = model as? SystemLanguageModel else { return }
        do {
            let fixed = try await system.tokenCount(for: prompt)
                + system.tokenCount(for: Instructions(instructions))
                + system.tokenCount(for: schema)
            let reserve = max(1, options.maximumResponseTokens ?? 512) + 128
            let limit = system.contextSize
            // Drop whole old turns. Do not cut the current observation or JSON schema.
            while !session.transcript.history.isEmpty {
                let history = try await system.tokenCount(for: Array(session.transcript.history))
                if fixed + history + reserve <= limit { return }
                removeOldestTurn()
            }
            if fixed + reserve > limit {
                throw LanguageModelError.contextSizeExceeded(.init(
                    contextSize: limit, tokenCount: fixed + reserve,
                    debugDescription: "Current observation and schema exceed the on-device token budget."
                ))
            }
        } catch {
            try Task.checkCancellation()
            if error is CancellationError || Self.isContextError(error) { throw error }
            // Xcode 27.2's token-count service can reject multimodal prompts
            // that respond() accepts. Counting is an optimization, not a gate.
            // Without reliable counting, old turns can consume the 4K budget.
            // The current prompt already includes the goal and latest execution results.
            resetSession()
        }
    }

    private func compactHistory() {
        // Old screenshots and hidden reasoning are not needed for execution logs.
        let entries: [Transcript.Entry] = session.transcript.history.compactMap { entry in
            switch entry {
            case .prompt(var prompt):
                prompt.segments.removeAll { if case .attachment = $0 { true } else { false } }
                return .prompt(prompt)
            case .response: return entry
            default: return nil
            }
        }
        session.transcript.history.replaceSubrange(session.transcript.history.indices, with: entries)
        while !session.transcript.history.isEmpty {
            let history = Array(session.transcript.history)
            let turns = history.filter { if case .prompt = $0 { true } else { false } }.count
            let characters = history.reduce(0) { $0 + String(describing: $1).count }
            if turns <= historyPolicy.maximumTurns, characters <= historyPolicy.maximumCharacters { break }
            removeOldestTurn()
        }
    }

    private func removeOldestTurn() {
        let history = Array(session.transcript.history)
        let nextPrompt = history.dropFirst().firstIndex { if case .prompt = $0 { true } else { false } }
        session.transcript.history.removeFirst(nextPrompt ?? history.count)
    }

    static func isContextError(_ error: any Error) -> Bool {
        if case LanguageModelError.contextSizeExceeded = error { return true }
        return false
    }

    static func canFallback(after error: any Error) -> Bool {
        switch error {
        case is PrivateCloudComputeLanguageModel.Error: return true
        case ActionGeneratorError.backendUnavailable, ActionGeneratorError.unsupportedCapability: return true
        default: return false
        }
    }
}
