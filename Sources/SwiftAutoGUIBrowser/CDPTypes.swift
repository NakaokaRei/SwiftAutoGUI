import Foundation
import SwiftAutoGUI

/// A JSON value used by the lightweight CDP client.
public enum CDPJSONValue: Sendable, Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([CDPJSONValue])
    case object([String: CDPJSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([CDPJSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: CDPJSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    public var objectValue: [String: CDPJSONValue]? {
        guard case .object(let value) = self else { return nil }
        return value
    }

    public var arrayValue: [CDPJSONValue]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    public var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    public var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    public var doubleValue: Double? {
        guard case .number(let value) = self else { return nil }
        return value
    }

    public var intValue: Int? { doubleValue.map(Int.init) }

    public subscript(key: String) -> CDPJSONValue? { objectValue?[key] }
}

extension CDPJSONValue {
    static func object(_ pairs: (String, CDPJSONValue?)...) -> CDPJSONValue {
        .object(Dictionary(uniqueKeysWithValues: pairs.compactMap { key, value in
            value.map { (key, $0) }
        }))
    }
}

public enum BrowserError: Error, Sendable, LocalizedError, Equatable {
    case invalidEndpoint(String)
    case endpointNotAllowed(String)
    case discoveryFailed(String)
    case invalidWebSocketURL(String)
    case disconnected
    case timeout(method: String)
    case protocolError(code: Int, message: String)
    case noPageTabs
    case tabNotFound(String)
    case observationNotFound
    case staleElement(Int)
    case unsupportedAction(String)
    case navigationNotAllowed(String)
    case authorizationDenied(String)
    case malformedResponse(String)

    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let value): "Invalid browser debugging endpoint: \(value)"
        case .endpointNotAllowed(let value): "Browser debugging endpoint is not allowed: \(value)"
        case .discoveryFailed(let value): "Browser discovery failed: \(value)"
        case .invalidWebSocketURL(let value): "Invalid browser WebSocket URL: \(value)"
        case .disconnected: "The browser debugging connection closed."
        case .timeout(let method): "CDP command timed out: \(method)"
        case .protocolError(let code, let message): "CDP error \(code): \(message)"
        case .noPageTabs: "The browser has no page tabs."
        case .tabNotFound(let id): "Browser tab not found: \(id)"
        case .observationNotFound: "The browser observation is no longer available."
        case .staleElement(let id): "Browser element #\(id) became stale; observe the page again."
        case .unsupportedAction(let action): "The browser-only backend does not support \(action)."
        case .navigationNotAllowed(let url): "Navigation is not allowed by the domain policy: \(url)"
        case .authorizationDenied(let action): "Browser action was not authorized: \(action)"
        case .malformedResponse(let detail): "Malformed CDP response: \(detail)"
        }
    }
}

public struct BrowserSecurityPolicy: Sendable, Equatable {
    public var allowedEndpointHosts: Set<String>
    public var allowedDomains: Set<String>

    public init(
        allowedEndpointHosts: Set<String> = ["127.0.0.1", "localhost", "::1"],
        allowedDomains: Set<String> = []
    ) {
        self.allowedEndpointHosts = Set(allowedEndpointHosts.map { $0.lowercased() })
        self.allowedDomains = Set(allowedDomains.map { $0.lowercased() })
    }

    public func validateEndpoint(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host?.lowercased() else {
            throw BrowserError.invalidEndpoint(url.absoluteString)
        }
        guard allowedEndpointHosts.contains(host) else {
            throw BrowserError.endpointNotAllowed(url.absoluteString)
        }
    }

    public func validateWebSocket(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "ws" || scheme == "wss",
              let host = url.host?.lowercased() else {
            throw BrowserError.invalidWebSocketURL(url.absoluteString)
        }
        guard allowedEndpointHosts.contains(host) else {
            throw BrowserError.endpointNotAllowed(url.absoluteString)
        }
    }

    public func allowsNavigation(to url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host?.lowercased() else { return false }
        return allowedDomains.contains { rule in
            if rule.hasPrefix("*.") {
                let suffix = String(rule.dropFirst(2))
                return host != suffix && host.hasSuffix("." + suffix)
            }
            return host == rule
        }
    }
}

public enum BrowserAuthorizationRequest: Sendable, Equatable {
    case crossOriginNavigation(from: URL?, to: URL)
    case download(url: URL?, suggestedFilename: String?)
}

public protocol BrowserActionAuthorizing: Sendable {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool
}

public enum BrowserTabState: String, Sendable, Codable {
    case active
    case loading
    case ready
    case closed
}

public struct BrowserTab: Sendable, Codable, Equatable {
    public let id: String
    public let url: String
    public let title: String
    public let state: BrowserTabState

    public init(id: String, url: String, title: String, state: BrowserTabState) {
        self.id = id
        self.url = url
        self.title = title
        self.state = state
    }
}

public struct BrowserRect: Sendable, Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
}

public struct BrowserElement: Sendable, Codable, Equatable {
    public let elementID: Int
    public let backendDOMNodeID: Int
    public let frameID: String?
    public let role: String
    public let name: String
    public let value: String?
    public let bounds: BrowserRect
    public let isEnabled: Bool
    public let isEditable: Bool
    public let destinationURL: String?

    public init(
        elementID: Int,
        backendDOMNodeID: Int,
        frameID: String?,
        role: String,
        name: String,
        value: String?,
        bounds: BrowserRect,
        isEnabled: Bool,
        isEditable: Bool,
        destinationURL: String? = nil
    ) {
        self.elementID = elementID
        self.backendDOMNodeID = backendDOMNodeID
        self.frameID = frameID
        self.role = role
        self.name = name
        self.value = value
        self.bounds = bounds
        self.isEnabled = isEnabled
        self.isEditable = isEditable
        self.destinationURL = destinationURL
    }
}

public struct BrowserObservation: Sendable {
    public let id: UUID
    public let tab: BrowserTab
    public let frameID: String
    public let loaderID: String
    public let viewportSize: CGSize
    public let elements: [BrowserElement]
    public let formattedContext: String
    public let stateFingerprint: String
    public let screenshotJPEGData: Data?

    public init(
        id: UUID = UUID(),
        tab: BrowserTab,
        frameID: String,
        loaderID: String,
        viewportSize: CGSize,
        elements: [BrowserElement],
        formattedContext: String,
        stateFingerprint: String,
        screenshotJPEGData: Data? = nil
    ) {
        self.id = id
        self.tab = tab
        self.frameID = frameID
        self.loaderID = loaderID
        self.viewportSize = viewportSize
        self.elements = elements
        self.formattedContext = formattedContext
        self.stateFingerprint = stateFingerprint
        self.screenshotJPEGData = screenshotJPEGData
    }

    public func element(withID id: Int) -> BrowserElement? {
        elements.first { $0.elementID == id }
    }
}

public enum BrowserAction: Sendable, Equatable {
    case navigate(URL)
    case click(elementID: Int)
    case replaceText(elementID: Int, value: String)
    case insertText(String)
    case keyShortcut([String])
    case scroll(horizontal: Int, vertical: Int)
    case activateTab(String)
    case wait(TimeInterval)
}

public struct BrowserActionResult: Sendable {
    public let action: BrowserAction
    public let succeeded: Bool
    public let failure: BrowserError?
    public let observation: BrowserObservation
    public let navigation: AgentNavigationResult?
    public let tabChanges: [AgentTabChange]
    public let downloads: [AgentDownloadResult]

    public init(
        action: BrowserAction,
        succeeded: Bool,
        failure: BrowserError? = nil,
        observation: BrowserObservation,
        navigation: AgentNavigationResult? = nil,
        tabChanges: [AgentTabChange] = [],
        downloads: [AgentDownloadResult] = []
    ) {
        self.action = action
        self.succeeded = succeeded
        self.failure = failure
        self.observation = observation
        self.navigation = navigation
        self.tabChanges = tabChanges
        self.downloads = downloads
    }
}
