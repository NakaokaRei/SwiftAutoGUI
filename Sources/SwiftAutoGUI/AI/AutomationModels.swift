import Foundation
import FoundationModels
import FoundationModelsUtilities

/// Factories for models used by both action generation and Agent.
/// Passing a remote model is an explicit choice to send prompts and observations off-device.
public enum AutomationModels {
    public static let defaultAgentModel = "gpt-5.6-sol"
    public static let defaultTextModel = "gpt-5.6-luna"

    /// Connects to a Chat Completions endpoint, using Apple's pinned utility adapter.
    /// Supply a base URL, not a complete `/chat/completions` URL. The selected
    /// endpoint/model must support images (if used) and JSON Schema output.
    /// The adapter advertises capabilities; it does not discover server support.
    /// This adapter does not forward ContextOptions.reasoningLevel.
    public static func openAI(
        apiKey: String,
        model: String = defaultAgentModel,
        baseURL: URL = URL(string: "https://api.openai.com")!,
        urlSessionConfiguration: URLSessionConfiguration? = nil
    ) -> OpenAIChatLanguageModel {
        OpenAIChatLanguageModel(client: ChatCompletionsLanguageModel(
            name: model,
            url: baseURL,
            additionalHeaders: ["Authorization": "Bearer \(apiKey)"],
            urlSessionConfiguration: urlSessionConfiguration
        ))
    }

    /// Availability checks for Apple's models. Third-party executors report
    /// network, authentication, and endpoint errors when a request is made.
    public static func unavailableReason(for model: some LanguageModel) -> String? {
        if let system = model as? SystemLanguageModel,
           case .unavailable(let reason) = system.availability {
            return "On-device model unavailable: \(reason)"
        }
        if let cloud = model as? PrivateCloudComputeLanguageModel {
            if case .unavailable(let reason) = cloud.availability {
                return "Private Cloud Compute unavailable: \(reason)"
            }
            if cloud.quotaUsage.isLimitReached {
                return "Private Cloud Compute daily quota reached."
            }
        }
        return nil
    }
}
