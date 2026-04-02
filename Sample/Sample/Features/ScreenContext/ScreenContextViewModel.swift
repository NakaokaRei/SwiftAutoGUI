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
