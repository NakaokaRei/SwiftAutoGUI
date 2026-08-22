import AppKit
import Foundation

/// The kind of environment represented by an agent observation.
public enum AgentObservationKind: String, Sendable, Codable {
    case native
    case browser
}

/// A backend-neutral observation consumed by ``Agent`` and vision backends.
///
/// `nativeScreenContext` is populated only by ``NativeAutomationBackend`` and
/// keeps the existing screen-context API source-compatible. Browser backends
/// provide their semantic state through `formattedContext` instead.
public struct AgentObservation: Sendable {
    public let id: UUID
    public let kind: AgentObservationKind
    public let formattedContext: String
    public let stateFingerprint: String
    public let actionableElementCount: Int
    public let viewportSize: CGSize
    public let screenshotJPEGData: Data?
    public let nativeScreenContext: ScreenContext?

    public init(
        id: UUID = UUID(),
        kind: AgentObservationKind,
        formattedContext: String,
        stateFingerprint: String,
        actionableElementCount: Int,
        viewportSize: CGSize,
        screenshotJPEGData: Data? = nil,
        nativeScreenContext: ScreenContext? = nil
    ) {
        self.id = id
        self.kind = kind
        self.formattedContext = formattedContext
        self.stateFingerprint = stateFingerprint
        self.actionableElementCount = actionableElementCount
        self.viewportSize = viewportSize
        self.screenshotJPEGData = screenshotJPEGData
        self.nativeScreenContext = nativeScreenContext
    }
}

/// An action result paired with the backend observation captured afterwards.
public struct AgentAutomationExecution: Sendable {
    public let result: ActionExecutionResult
    public let observation: AgentObservation

    public init(result: ActionExecutionResult, observation: AgentObservation) {
        self.result = result
        self.observation = observation
    }
}

/// Supplies observations and executes actions for ``Agent``.
///
/// SwiftAutoGUI uses ``NativeAutomationBackend`` by default. Optional modules
/// can implement this protocol without adding their dependencies to the core
/// library.
public protocol AgentAutomationBackend: Sendable {
    func observe(visionMode: AgentVisionMode) async throws -> AgentObservation

    func execute(
        _ action: BasicAction,
        in observation: AgentObservation
    ) async -> AgentAutomationExecution
}

/// The existing Accessibility and CGEvent based Agent environment.
public struct NativeAutomationBackend: AgentAutomationBackend, Sendable {
    public let screenContextOptions: ScreenContextProvider.Options?
    public let observationDelay: TimeInterval

    public init(
        screenContextOptions: ScreenContextProvider.Options? = ScreenContextProvider.Options(),
        observationDelay: TimeInterval = 0.15
    ) {
        self.screenContextOptions = screenContextOptions
        self.observationDelay = observationDelay
    }

    public func observe(visionMode: AgentVisionMode) async throws -> AgentObservation {
        let context = await MainActor.run {
            screenContextOptions.map { ScreenContextProvider.gather(options: $0) }
        }
        let includeScreenshot = switch visionMode {
        case .always: true
        case .automatic: context?.actionableElementCount == 0
        case .never: false
        }

        let screenshotData: Data?
        if includeScreenshot {
            guard let screenshot = try await SwiftAutoGUI.screenshot(),
                  let data = await MainActor.run(body: {
                      screenshot.jpegData(compressionFactor: 0.5)
                  }) else {
                throw ActionGeneratorError.invalidResponse(detail: "Failed to capture screenshot")
            }
            screenshotData = data
        } else {
            screenshotData = nil
        }

        let size = await MainActor.run { SwiftAutoGUI.size() }
        return Self.makeObservation(
            context: context,
            viewportSize: CGSize(width: size.width, height: size.height),
            screenshotData: screenshotData
        )
    }

    public func execute(
        _ action: BasicAction,
        in observation: AgentObservation
    ) async -> AgentAutomationExecution {
        guard observation.kind == .native else {
            let result = ActionExecutionResult(
                action: action,
                succeeded: false,
                method: .none,
                failureReason: "NativeAutomationBackend cannot execute a non-native observation."
            )
            return AgentAutomationExecution(result: result, observation: observation)
        }

        let execution = await AgentActionExecutor.execute(
            action,
            in: observation.nativeScreenContext,
            screenContextOptions: screenContextOptions,
            observationDelay: observationDelay
        )
        let nextObservation = Self.makeObservation(
            context: execution.screenContext,
            viewportSize: observation.viewportSize,
            screenshotData: nil
        )
        return AgentAutomationExecution(result: execution.result, observation: nextObservation)
    }

    private static func makeObservation(
        context: ScreenContext?,
        viewportSize: CGSize,
        screenshotData: Data?
    ) -> AgentObservation {
        AgentObservation(
            kind: .native,
            formattedContext: context?.formatted() ?? "",
            stateFingerprint: context?.stateFingerprint ?? "native:no-context",
            actionableElementCount: context?.actionableElementCount ?? 0,
            viewportSize: viewportSize,
            screenshotJPEGData: screenshotData,
            nativeScreenContext: context
        )
    }
}
