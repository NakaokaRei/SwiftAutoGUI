//
//  ActionGenerator.swift
//  SwiftAutoGUI
//

import Foundation
import FoundationModels

// MARK: - BasicAction (Lightweight @Generable type for on-device model)

/// A lightweight action type for AI generation.
///
/// This type is intentionally kept small to fit within the on-device model's
/// context window. It covers common automation operations and converts to
/// the full ``Action`` type via ``toAction()``.
@Generable
public enum BasicAction: Sendable, Codable {
    /// Type text.
    case write(text: String)

    /// Move mouse to absolute position.
    case move(x: Double, y: Double)

    /// Left click at current position.
    case leftClick

    /// Right click at current position.
    case rightClick

    /// Double click at current position.
    case doubleClick

    /// Scroll vertically. Positive values scroll up, negative values scroll down.
    case vscroll(clicks: Int)

    /// Scroll horizontally. Positive values scroll right, negative values scroll left.
    case hscroll(clicks: Int)

    /// Wait for a duration in seconds.
    case wait(duration: Double)

    /// Press a keyboard shortcut. Use key names like "command", "shift", "a", "c", "returnKey", "space", "delete", "tab", "escape", "upArrow", "downArrow", "leftArrow", "rightArrow".
    case keyShortcut(keys: [Key])

    /// Drag mouse from one position to another.
    case drag(fromX: Double, fromY: Double, toX: Double, toY: Double)

    /// Press a button by accessibility label. `bundleID` is empty to target the
    /// frontmost app; otherwise pass a value like "com.apple.calculator".
    case pressButton(label: String, bundleID: String)

    /// Press a step-local element from the current screen observation.
    case pressElement(elementID: Int)

    /// Set a text field's value via the accessibility API.
    /// `label` may be empty to match by role only. `bundleID` empty = frontmost.
    case setTextField(label: String, value: String, bundleID: String)

    /// Set the value of a step-local element from the current observation.
    case setElementValue(elementID: Int, value: String)

    /// Select a menu item by hierarchical path, e.g. `["File", "Save As…"]`.
    case selectMenuItem(path: [String], bundleID: String)

    /// Bring a window to the front by title.
    case raiseWindow(title: String, bundleID: String)

    /// Open an HTTP or HTTPS URL in the default browser.
    case openURL(url: String)

    /// Launch an application if needed and bring it to the front.
    case activateApp(name: String)

    /// Gracefully quit an application.
    case quitApp(name: String)

    /// Get the name of the frontmost application.
    case getFrontmostApp

    /// Activate a browser tab by its CDP target identifier.
    /// Native automation backends report this action as unsupported.
    case activateTab(tabID: String)

    /// Convert to an executable ``Action``.
    /// Throws for invalid parameters and actions requiring an observation or browser session.
    public func toAction() throws -> Action {
        try validate()
        switch self {
        case .write(let text):
            return .write(text)
        case .move(let x, let y):
            return .move(to: CGPoint(x: x, y: y))
        case .leftClick:
            return .leftClick
        case .rightClick:
            return .rightClick
        case .doubleClick:
            return .doubleClick()
        case .vscroll(let clicks):
            return .vscroll(clicks: clicks)
        case .hscroll(let clicks):
            return .hscroll(clicks: clicks)
        case .wait(let duration):
            return .wait(duration)
        case .keyShortcut(let keys):
            return .keyShortcut(keys)
        case .drag(let fromX, let fromY, let toX, let toY):
            return .drag(from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
        case .pressButton(let label, let bundleID):
            return .pressButton(label: label, app: scope(bundleID))
        case .pressElement:
            // Element IDs require the ScreenContext captured by Agent and are
            // executed by AgentActionExecutor. Standalone conversion is an error.
            throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.")
        case .setTextField(let label, let value, let bundleID):
            return .setTextField(
                label: label.isEmpty ? nil : label,
                value: value,
                app: scope(bundleID)
            )
        case .setElementValue:
            throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.")
        case .selectMenuItem(let path, let bundleID):
            return .selectMenuItem(path: path, app: scope(bundleID))
        case .raiseWindow(let title, let bundleID):
            return .raiseWindow(title: title, app: scope(bundleID))
        case .openURL(let url):
            guard let url = validatedHTTPURL(url) else { throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.") }
            return .openURL(url)
        case .activateApp(let name):
            guard let name = normalizedAppName(name) else { throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.") }
            return .activateApp(name: name)
        case .quitApp(let name):
            guard let name = normalizedAppName(name) else { throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.") }
            return .quitApp(name: name)
        case .getFrontmostApp:
            return .getFrontmostApp
        case .activateTab:
            // Browser-only actions are executed by SwiftAutoGUIBrowser.
            throw ActionGeneratorError.invalidResponse(detail: "This action requires a valid target or an observation-aware automation backend.")
        }
    }

    private func scope(_ bundleID: String) -> AXAppScope {
        bundleID.isEmpty ? .frontmost : .bundleID(bundleID)
    }

    func validatedHTTPURL(_ value: String) -> URL? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count <= 2_048,
              let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.isEmpty == false,
              let url = components.url else {
            return nil
        }
        return url
    }

    func normalizedAppName(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              value.count <= 128,
              !value.contains("/"),
              !value.contains("\0") else {
            return nil
        }
        return value
    }

    // MARK: - Tagged Union Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case text, x, y, clicks, duration, keys
        case fromX, fromY, toX, toY
        case label, value, path, title, bundleID, elementID
        case url, name, tabID
    }

    private enum ActionType: String, Codable {
        case write, move, leftClick, rightClick, doubleClick
        case vscroll, hscroll, wait, keyShortcut, drag
        case pressButton, pressElement, setTextField, setElementValue, selectMenuItem, raiseWindow
        case openURL, activateApp, quitApp, getFrontmostApp, activateTab
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
        case .write:
            let text = try container.decode(String.self, forKey: .text)
            self = .write(text: text)
        case .move:
            let x = try container.decode(Double.self, forKey: .x)
            let y = try container.decode(Double.self, forKey: .y)
            self = .move(x: x, y: y)
        case .leftClick:
            self = .leftClick
        case .rightClick:
            self = .rightClick
        case .doubleClick:
            self = .doubleClick
        case .vscroll:
            let clicks = try container.decode(Int.self, forKey: .clicks)
            self = .vscroll(clicks: clicks)
        case .hscroll:
            let clicks = try container.decode(Int.self, forKey: .clicks)
            self = .hscroll(clicks: clicks)
        case .wait:
            let duration = try container.decode(Double.self, forKey: .duration)
            self = .wait(duration: duration)
        case .keyShortcut:
            let keys = try container.decode([Key].self, forKey: .keys)
            self = .keyShortcut(keys: keys)
        case .drag:
            let fromX = try container.decode(Double.self, forKey: .fromX)
            let fromY = try container.decode(Double.self, forKey: .fromY)
            let toX = try container.decode(Double.self, forKey: .toX)
            let toY = try container.decode(Double.self, forKey: .toY)
            self = .drag(fromX: fromX, fromY: fromY, toX: toX, toY: toY)
        case .pressButton:
            let label = try container.decode(String.self, forKey: .label)
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .pressButton(label: label, bundleID: bundleID)
        case .pressElement:
            let elementID = try container.decode(Int.self, forKey: .elementID)
            self = .pressElement(elementID: elementID)
        case .setTextField:
            let label = try container.decode(String.self, forKey: .label)
            let value = try container.decode(String.self, forKey: .value)
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .setTextField(label: label, value: value, bundleID: bundleID)
        case .setElementValue:
            let elementID = try container.decode(Int.self, forKey: .elementID)
            let value = try container.decode(String.self, forKey: .value)
            self = .setElementValue(elementID: elementID, value: value)
        case .selectMenuItem:
            let path = try container.decode([String].self, forKey: .path)
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .selectMenuItem(path: path, bundleID: bundleID)
        case .raiseWindow:
            let title = try container.decode(String.self, forKey: .title)
            let bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
            self = .raiseWindow(title: title, bundleID: bundleID)
        case .openURL:
            let url = try container.decode(String.self, forKey: .url)
            self = .openURL(url: url)
        case .activateApp:
            let name = try container.decode(String.self, forKey: .name)
            self = .activateApp(name: name)
        case .quitApp:
            let name = try container.decode(String.self, forKey: .name)
            self = .quitApp(name: name)
        case .getFrontmostApp:
            self = .getFrontmostApp
        case .activateTab:
            let tabID = try container.decode(String.self, forKey: .tabID)
            self = .activateTab(tabID: tabID)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .write(let text):
            try container.encode(ActionType.write, forKey: .type)
            try container.encode(text, forKey: .text)
        case .move(let x, let y):
            try container.encode(ActionType.move, forKey: .type)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
        case .leftClick:
            try container.encode(ActionType.leftClick, forKey: .type)
        case .rightClick:
            try container.encode(ActionType.rightClick, forKey: .type)
        case .doubleClick:
            try container.encode(ActionType.doubleClick, forKey: .type)
        case .vscroll(let clicks):
            try container.encode(ActionType.vscroll, forKey: .type)
            try container.encode(clicks, forKey: .clicks)
        case .hscroll(let clicks):
            try container.encode(ActionType.hscroll, forKey: .type)
            try container.encode(clicks, forKey: .clicks)
        case .wait(let duration):
            try container.encode(ActionType.wait, forKey: .type)
            try container.encode(duration, forKey: .duration)
        case .keyShortcut(let keys):
            try container.encode(ActionType.keyShortcut, forKey: .type)
            try container.encode(keys, forKey: .keys)
        case .drag(let fromX, let fromY, let toX, let toY):
            try container.encode(ActionType.drag, forKey: .type)
            try container.encode(fromX, forKey: .fromX)
            try container.encode(fromY, forKey: .fromY)
            try container.encode(toX, forKey: .toX)
            try container.encode(toY, forKey: .toY)
        case .pressButton(let label, let bundleID):
            try container.encode(ActionType.pressButton, forKey: .type)
            try container.encode(label, forKey: .label)
            try container.encode(bundleID, forKey: .bundleID)
        case .pressElement(let elementID):
            try container.encode(ActionType.pressElement, forKey: .type)
            try container.encode(elementID, forKey: .elementID)
        case .setTextField(let label, let value, let bundleID):
            try container.encode(ActionType.setTextField, forKey: .type)
            try container.encode(label, forKey: .label)
            try container.encode(value, forKey: .value)
            try container.encode(bundleID, forKey: .bundleID)
        case .setElementValue(let elementID, let value):
            try container.encode(ActionType.setElementValue, forKey: .type)
            try container.encode(elementID, forKey: .elementID)
            try container.encode(value, forKey: .value)
        case .selectMenuItem(let path, let bundleID):
            try container.encode(ActionType.selectMenuItem, forKey: .type)
            try container.encode(path, forKey: .path)
            try container.encode(bundleID, forKey: .bundleID)
        case .raiseWindow(let title, let bundleID):
            try container.encode(ActionType.raiseWindow, forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(bundleID, forKey: .bundleID)
        case .openURL(let url):
            try container.encode(ActionType.openURL, forKey: .type)
            try container.encode(url, forKey: .url)
        case .activateApp(let name):
            try container.encode(ActionType.activateApp, forKey: .type)
            try container.encode(name, forKey: .name)
        case .quitApp(let name):
            try container.encode(ActionType.quitApp, forKey: .type)
            try container.encode(name, forKey: .name)
        case .getFrontmostApp:
            try container.encode(ActionType.getFrontmostApp, forKey: .type)
        case .activateTab(let tabID):
            try container.encode(ActionType.activateTab, forKey: .type)
            try container.encode(tabID, forKey: .tabID)
        }
    }
}

// MARK: - ActionGenerator

/// Generates actions through Foundation Models using any LanguageModel.
/// Each independent request gets a fresh session. No input is executed here.
public struct ActionGenerator: Sendable {
    @MainActor public static var defaultModel: any LanguageModel = SystemLanguageModel.default
    public let model: any LanguageModel
    public let fallbackModel: (any LanguageModel)?

    /// A fallback is opt-in. Passing a cloud model permits sending the prompt to it.
    public init(model: some LanguageModel, fallbackModel: (any LanguageModel)? = nil) {
        self.model = model
        self.fallbackModel = fallbackModel
    }

    public func generateAction(from prompt: String) async throws -> Action {
        let session = makeSession()
        let result = try await session.respond(to: Prompt(prompt), generating: SingleAction.self)
        return try result.action.toAction()
    }

    public func generateActionSequence(from prompt: String) async throws -> [Action] {
        let session = makeSession()
        let plan = try await session.respond(to: Prompt(prompt), generating: ActionPlan.self)
        guard !plan.actions.isEmpty else { throw ActionGeneratorError.noActionsGenerated }
        guard plan.actions.count <= 20 else { throw ActionGeneratorError.invalidResponse(detail: "An action plan may contain at most twenty actions.") }
        return try plan.actions.map { try $0.toAction() }
    }

    private func makeSession() -> ActionSession {
        ActionSession(model: model, fallbackModel: fallbackModel, instructions:
            "Convert the user's request into a short sequence of automation actions. Use only the provided schema. No observation or browser session is available: do not use pressElement, setElementValue, or activateTab.")
    }

    @MainActor public static var isAvailable: Bool { unavailableReason == nil }
    @MainActor public static var unavailableReason: String? {
        AutomationModels.unavailableReason(for: defaultModel)
    }

    @MainActor public static func generateAction(from prompt: String) async throws -> Action {
        try await ActionGenerator(model: defaultModel).generateAction(from: prompt)
    }

    @MainActor public static func generateActionSequence(from prompt: String) async throws -> [Action] {
        try await ActionGenerator(model: defaultModel).generateActionSequence(from: prompt)
    }
}

@Generable
struct SingleAction: Sendable {
    var action: BasicAction
}

@Generable
struct ActionPlan: Sendable {
    @Guide(.maximumCount(20))
    var actions: [BasicAction]
}

// MARK: - Convenience Extensions

extension Action {
    /// Generates an action from a natural language prompt.
    ///
    /// This is a convenience method that uses ``ActionGenerator`` to generate a single action.
    ///
    /// - Parameter prompt: A natural language description of the desired action.
    /// - Returns: An ``Action`` instance.
    /// - Throws: Any errors from the action generation backend.
    @MainActor
    public static func fromPrompt(_ prompt: String) async throws -> Action {
        return try await ActionGenerator.generateAction(from: prompt)
    }
}
