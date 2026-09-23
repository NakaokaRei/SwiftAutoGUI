import FoundationModels
import SwiftAutoGUI

/// Choosing a cloud provider explicitly permits sending the prompt and screen content.
enum AIProviderChoice: String, CaseIterable, Identifiable {
    case onDevice = "On-device"
    case pcc = "Private Cloud Compute"
    case openAI = "OpenAI"

    var id: String { rawValue }
    var explanation: String {
        switch self {
        case .onDevice: "Processes prompts and screen content on this Mac."
        case .pcc: "Sends content to Apple. Requires an eligible, entitled app and available daily quota."
        case .openAI: "Sends prompts and screen content to OpenAI using your API key."
        }
    }
    func model(apiKey: String, name: String) -> any LanguageModel {
        switch self {
        case .onDevice: SystemLanguageModel.default
        case .pcc: PrivateCloudComputeLanguageModel()
        case .openAI: AutomationModels.openAI(apiKey: apiKey, model: name)
        }
    }
}
