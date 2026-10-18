import ComposableArchitecture
import FoundationModels
import SampleSupport
import SwiftAutoGUI

struct GenerationClient: Sendable {
    var execute: @MainActor @Sendable (GeneratedPlan, Int) async -> Void = { plan, index in
        _ = await plan.actions[index].execute()
    }
    var generate:
        @MainActor @Sendable (String, AIGenerationDemoFeature.Backend, String, String) async throws
            ->
            GeneratedPlan
}
extension GenerationClient: DependencyKey {
    static let liveValue = Self { prompt, backend, key, model in
        switch backend {
        case .foundationModels:
            return GeneratedPlan(
                actions: try await ActionGenerator.generateActionSequence(from: prompt))
        case .pcc:
            return GeneratedPlan(
                actions: try await ActionGenerator(model: PrivateCloudComputeLanguageModel())
                    .generateActionSequence(from: prompt))
        case .openAI:
            return GeneratedPlan(
                actions: try await ActionGenerator(
                    model: AutomationModels.openAI(apiKey: key, model: model)
                ).generateActionSequence(from: prompt))
        }
    }
    static let testValue = Self(
        execute: { _, _ in fatalError("Override GenerationClient.execute in tests") },
        generate: { _, _, _, _ in throw Unimplemented() })
    private struct Unimplemented: Error {}
}
extension DependencyValues {
    var generationClient: GenerationClient {
        get { self[GenerationClient.self] }
        set { self[GenerationClient.self] = newValue }
    }
}

/// The library's Action can contain non-Sendable easing closures. Keep the
/// executable plan on MainActor and expose only immutable descriptions to state.
@MainActor
final class GeneratedPlan {
    let actions: [AutomationAction]
    nonisolated let descriptions: [String]
    init(actions: [AutomationAction]) {
        self.actions = actions
        self.descriptions = actions.map(describeAction)
    }
}
