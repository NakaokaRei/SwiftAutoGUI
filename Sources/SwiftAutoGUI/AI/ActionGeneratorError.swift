import Foundation

public enum ActionGeneratorError: Error, LocalizedError, Sendable {
    case noActionsGenerated
    case backendUnavailable(reason: String)
    case invalidResponse(detail: String)
    case unsupportedCapability(String)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .noActionsGenerated: "No actions were generated."
        case .backendUnavailable(let reason): reason
        case .invalidResponse(let detail): "Invalid response: \(detail)"
        case .unsupportedCapability(let capability): "The model does not support \(capability)."
        case .invalidConfiguration(let detail): "Invalid configuration: \(detail)"
        }
    }
}
