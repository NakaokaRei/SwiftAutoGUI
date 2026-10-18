import ComposableArchitecture
import SwiftAutoGUI

struct ScreenContextClient: Sendable {
    var gather: @MainActor @Sendable (ScreenContextProvider.Options) -> ScreenContext
    var execute:
        @MainActor @Sendable (BasicAction, ScreenContext, ScreenContextProvider.Options) async ->
            AgentActionExecution
}
extension ScreenContextClient: DependencyKey {
    static let testValue = Self(
        gather: { _ in fatalError("Override ScreenContextClient.gather in tests") },
        execute: { _, _, _ in fatalError("Override ScreenContextClient.execute in tests") }
    )
    static let liveValue = Self(
        gather: { ScreenContextProvider.gather(options: $0) },
        execute: { await AgentActionExecutor.execute($0, in: $1, screenContextOptions: $2) }
    )
}
extension DependencyValues {
    var screenContextClient: ScreenContextClient {
        get { self[ScreenContextClient.self] }
        set { self[ScreenContextClient.self] = newValue }
    }
}
