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
    case standardAction
    case none
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

    public init(
        action: BasicAction,
        succeeded: Bool,
        method: AgentActionExecutionMethod,
        failureReason: String? = nil,
        screenChanged: Bool = false,
        focusedAppChanged: Bool = false,
        focusedElementChanged: Bool = false
    ) {
        self.action = action
        self.succeeded = succeeded
        self.method = method
        self.failureReason = failureReason
        self.screenChanged = screenChanged
        self.focusedAppChanged = focusedAppChanged
        self.focusedElementChanged = focusedElementChanged
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
