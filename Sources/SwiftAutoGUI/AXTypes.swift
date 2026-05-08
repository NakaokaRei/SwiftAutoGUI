//
//  AXTypes.swift
//  SwiftAutoGUI
//

import Darwin
import Foundation

// MARK: - AXStringMatch

/// Strategies for matching an AX attribute string (label, title, value, etc.)
/// against a query.
public enum AXStringMatch: Sendable, Equatable {
    /// Exact equality.
    case exact(String)

    /// Case-insensitive substring match. This is the default for label matching
    /// because real-world buttons often look like "Save (⌘S)" or "Save…".
    case containsCaseInsensitive(String)

    /// Regular-expression match. The query is compiled with `NSRegularExpression`
    /// using `.caseInsensitive`. A malformed pattern never matches.
    case regex(String)

    /// Returns true if `subject` satisfies this match strategy.
    public func matches(_ subject: String?) -> Bool {
        guard let subject else { return false }
        switch self {
        case .exact(let q):
            return subject == q
        case .containsCaseInsensitive(let q):
            if q.isEmpty { return true }
            return subject.range(of: q, options: .caseInsensitive) != nil
        case .regex(let pattern):
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return false
            }
            let range = NSRange(subject.startIndex..., in: subject)
            return regex.firstMatch(in: subject, options: [], range: range) != nil
        }
    }
}

// MARK: - AXMatchOptions

/// Options that constrain an AX element search.
public struct AXMatchOptions: Sendable {
    /// How to match the element's label (title or description).
    /// `nil` means do not constrain by label.
    public var labelMatch: AXStringMatch?

    /// How to match the element's current value.
    /// `nil` means do not constrain by value.
    public var valueMatch: AXStringMatch?

    /// If true, only enabled elements match. Defaults to true so that disabled
    /// buttons don't get picked when a similar enabled one exists elsewhere.
    public var requireEnabled: Bool

    /// Maximum tree depth to traverse before stopping a branch.
    public var maxDepth: Int

    /// Maximum total nodes to visit before giving up.
    public var maxNodes: Int

    public init(
        labelMatch: AXStringMatch? = nil,
        valueMatch: AXStringMatch? = nil,
        requireEnabled: Bool = true,
        maxDepth: Int = 20,
        maxNodes: Int = 5000
    ) {
        self.labelMatch = labelMatch
        self.valueMatch = valueMatch
        self.requireEnabled = requireEnabled
        self.maxDepth = maxDepth
        self.maxNodes = maxNodes
    }

    /// Convenience: match by label using the default case-insensitive contains
    /// strategy. Pass `exact: true` for strict equality.
    public static func label(_ query: String, exact: Bool = false) -> AXMatchOptions {
        AXMatchOptions(
            labelMatch: exact ? .exact(query) : .containsCaseInsensitive(query)
        )
    }
}

// MARK: - AXAppScope

/// Selects which application's accessibility tree to search.
public enum AXAppScope: Sendable {
    /// The currently frontmost application (`NSWorkspace.frontmostApplication`).
    case frontmost

    /// An application identified by bundle identifier (e.g. "com.apple.TextEdit").
    case bundleID(String)

    /// An application identified by process identifier.
    case pid(pid_t)
}
