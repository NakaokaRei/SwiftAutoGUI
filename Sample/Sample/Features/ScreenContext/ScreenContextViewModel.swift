//
//  ScreenContextViewModel.swift
//  Sample
//

import SwiftUI
import SwiftAutoGUI

@MainActor
@Observable
class ScreenContextViewModel {
    var context: ScreenContext?
    var formattedOutput: String = ""
    var isLoading = false
    var autoRefresh = false
    var refreshInterval: Double = 2.0

    // Options
    var maxDepth: Int = 5
    var maxNodes: Int = 200
    var maxValueLength: Int = 100
    var includeAXTree: Bool = true
    var selectedElementID: Int = 1
    var elementValue: String = ""
    var executionLog: String = "No element action executed yet."
    var isExecuting = false

    private var refreshTask: Task<Void, Never>?

    func gather() {
        isLoading = true
        let options = ScreenContextProvider.Options(
            maxDepth: maxDepth,
            maxNodes: maxNodes,
            maxValueLength: maxValueLength,
            includeAXTree: includeAXTree
        )
        let result = ScreenContextProvider.gather(options: options)
        context = result
        formattedOutput = result.formatted()
        isLoading = false
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        autoRefresh = true
        refreshTask = Task {
            while !Task.isCancelled {
                gather()
                try? await Task.sleep(for: .seconds(refreshInterval))
            }
        }
    }

    func stopAutoRefresh() {
        autoRefresh = false
        refreshTask?.cancel()
        refreshTask = nil
    }

    var nodeCount: Int {
        guard let tree = context?.focusedWindowAXTree else { return 0 }
        return countNodes(tree)
    }

    var actionableElementCount: Int {
        context?.actionableElementCount ?? 0
    }

    func pressSelectedElement() {
        execute(.pressElement(elementID: selectedElementID))
    }

    func setSelectedElementValue() {
        execute(.setElementValue(elementID: selectedElementID, value: elementValue))
    }

    private func execute(_ action: BasicAction) {
        guard let context else {
            executionLog = "Capture a screen context first."
            return
        }
        isExecuting = true
        Task {
            let execution = await AgentActionExecutor.execute(
                action,
                in: context,
                screenContextOptions: currentOptions()
            )
            self.context = execution.screenContext
            if let updated = execution.screenContext {
                formattedOutput = updated.formatted()
            }
            executionLog = describe(execution.result)
            isExecuting = false
        }
    }

    private func currentOptions() -> ScreenContextProvider.Options {
        ScreenContextProvider.Options(
            maxDepth: maxDepth,
            maxNodes: maxNodes,
            maxValueLength: maxValueLength,
            includeAXTree: includeAXTree
        )
    }

    private func describe(_ result: ActionExecutionResult) -> String {
        var lines = [
            "Result: \(result.succeeded ? "succeeded" : "failed")",
            "Method: \(result.method.rawValue)",
            "Screen changed: \(result.screenChanged)",
            "Focused app changed: \(result.focusedAppChanged)",
            "Focused element changed: \(result.focusedElementChanged)",
        ]
        if let reason = result.failureReason {
            lines.append("Reason: \(reason)")
        }
        return lines.joined(separator: "\n")
    }

    private func countNodes(_ node: AXNode) -> Int {
        var count = 1
        if let children = node.children {
            for child in children {
                count += countNodes(child)
            }
        }
        return count
    }
}
