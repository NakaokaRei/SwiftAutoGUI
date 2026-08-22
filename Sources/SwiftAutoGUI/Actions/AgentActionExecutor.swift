//
//  AgentActionExecutor.swift
//  SwiftAutoGUI
//

import ApplicationServices
import Foundation

/// How an agent action was executed.
public enum AgentActionExecutionMethod: String, Sendable, Codable {
    case accessibility
    case cgEvent
    case cdp
    case standardAction
    case none
}

/// A top-level browser navigation observed after an action.
public struct AgentNavigationResult: Sendable, Codable, Equatable {
    public let fromURL: String?
    public let toURL: String

    public init(fromURL: String?, toURL: String) {
        self.fromURL = fromURL
        self.toURL = toURL
    }
}

/// A browser tab lifecycle change observed after an action.
public struct AgentTabChange: Sendable, Codable, Equatable {
    public enum Kind: String, Sendable, Codable { case opened, closed, activated }

    public let kind: Kind
    public let tabID: String
    public let url: String?

    public init(kind: Kind, tabID: String, url: String? = nil) {
        self.kind = kind
        self.tabID = tabID
        self.url = url
    }
}

/// A browser download lifecycle update observed after an action.
public struct AgentDownloadResult: Sendable, Codable, Equatable {
    public enum State: String, Sendable, Codable { case requested, inProgress, completed, canceled }

    public let identifier: String
    public let url: String?
    public let suggestedFilename: String?
    public let state: State
    public let filePath: String?

    public init(
        identifier: String,
        url: String? = nil,
        suggestedFilename: String? = nil,
        state: State,
        filePath: String? = nil
    ) {
        self.identifier = identifier
        self.url = url
        self.suggestedFilename = suggestedFilename
        self.state = state
        self.filePath = filePath
    }
}

/// Structured result for a single action executed by ``Agent``.
public struct ActionExecutionResult: Sendable, Codable {
    public let action: BasicAction
    public let succeeded: Bool
    public let method: AgentActionExecutionMethod
    public let failureReason: String?
    public let screenChanged: Bool
    public let focusedAppChanged: Bool
    public let focusedElementChanged: Bool
    public let navigation: AgentNavigationResult?
    public let tabChanges: [AgentTabChange]
    public let downloads: [AgentDownloadResult]

    public init(
        action: BasicAction,
        succeeded: Bool,
        method: AgentActionExecutionMethod,
        failureReason: String? = nil,
        screenChanged: Bool = false,
        focusedAppChanged: Bool = false,
        focusedElementChanged: Bool = false,
        navigation: AgentNavigationResult? = nil,
        tabChanges: [AgentTabChange] = [],
        downloads: [AgentDownloadResult] = []
    ) {
        self.action = action
        self.succeeded = succeeded
        self.method = method
        self.failureReason = failureReason
        self.screenChanged = screenChanged
        self.focusedAppChanged = focusedAppChanged
        self.focusedElementChanged = focusedElementChanged
        self.navigation = navigation
        self.tabChanges = tabChanges
        self.downloads = downloads
    }
}

/// The action result together with the observation captured after execution.
public struct AgentActionExecution: Sendable {
    public let result: ActionExecutionResult
    public let screenContext: ScreenContext?

    public init(result: ActionExecutionResult, screenContext: ScreenContext?) {
        self.result = result
        self.screenContext = screenContext
    }
}

/// Executes agent actions against the exact ``ScreenContext`` used to generate
/// them. Element-ID actions are resolved just before execution so stale UI
/// references fail safely instead of clicking an unrelated coordinate.
public enum AgentActionExecutor {
    @MainActor
    public static func execute(
        _ action: BasicAction,
        in observation: ScreenContext?,
        screenContextOptions: ScreenContextProvider.Options? = ScreenContextProvider.Options(),
        observationDelay: TimeInterval = 0.15
    ) async -> AgentActionExecution {
        let execution = await perform(action, in: observation)

        if observationDelay > 0 {
            try? await Task.sleep(for: .seconds(observationDelay))
        }

        let updatedContext = screenContextOptions.map { ScreenContextProvider.gather(options: $0) }
        let screenChanged = observation?.stateFingerprint != updatedContext?.stateFingerprint
        let focusedAppChanged = observation?.frontmostApp?.pid != updatedContext?.frontmostApp?.pid
        let focusedElementChanged = observation?.focusedElement != updatedContext?.focusedElement

        return AgentActionExecution(
            result: ActionExecutionResult(
                action: action,
                succeeded: execution.succeeded,
                method: execution.method,
                failureReason: execution.failureReason,
                screenChanged: observation != nil && updatedContext != nil && screenChanged,
                focusedAppChanged: observation != nil && updatedContext != nil && focusedAppChanged,
                focusedElementChanged: observation != nil && updatedContext != nil && focusedElementChanged
            ),
            screenContext: updatedContext
        )
    }

    @MainActor
    private static func perform(
        _ action: BasicAction,
        in observation: ScreenContext?
    ) async -> (succeeded: Bool, method: AgentActionExecutionMethod, failureReason: String?) {
        switch action {
        case .activateTab:
            return (false, .none, "Browser tab actions require SwiftAutoGUIBrowser.")
        case .pressElement(let elementID):
            guard elementID > 0,
                  let observation,
                  let node = observation.focusedWindowAXTree?.node(withID: elementID) else {
                return (false, .none, "Element #\(elementID) is not present in the current observation.")
            }
            guard node.isEnabled else {
                return (false, .none, "Element #\(elementID) is disabled.")
            }
            guard let element = ScreenContextProvider.resolveElement(id: elementID, in: observation) else {
                return (false, .none, "Element #\(elementID) became stale; observe the screen again.")
            }

            if node.actions.contains(kAXPressAction), AXAction.press(element) {
                return (true, .accessibility, nil)
            }
            let frame = AXAction.frame(of: element) ?? node.frame.cgRect
            guard frame.width > 0, frame.height > 0 else {
                return (false, .none, "Element #\(elementID) has no clickable frame and AXPress failed.")
            }
            SwiftAutoGUI.click(at: CGPoint(x: frame.midX, y: frame.midY))
            return (true, .cgEvent, nil)

        case .setElementValue(let elementID, let value):
            guard elementID > 0,
                  let observation,
                  let node = observation.focusedWindowAXTree?.node(withID: elementID) else {
                return (false, .none, "Element #\(elementID) is not present in the current observation.")
            }
            guard node.isEnabled else {
                return (false, .none, "Element #\(elementID) is disabled.")
            }
            guard node.actions.contains("AXSetValue") else {
                return (false, .none, "Element #\(elementID) does not expose a writable value.")
            }
            guard let element = ScreenContextProvider.resolveElement(id: elementID, in: observation) else {
                return (false, .none, "Element #\(elementID) became stale; observe the screen again.")
            }
            guard AXAction.setValue(element, value: value) else {
                return (false, .accessibility, "Setting the value of element #\(elementID) failed.")
            }
            return (true, .accessibility, nil)

        default:
            _ = await action.toAction().execute()
            return (true, .standardAction, nil)
        }
    }
}
