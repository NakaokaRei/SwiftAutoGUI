//
//  OpenAIVisionBackend.swift
//  SwiftAutoGUI
//

import AppKit
import Foundation

// MARK: - OpenAIVisionBackend

/// A ``VisionActionGenerating`` backend that uses the OpenAI API with vision capabilities.
///
/// This backend sends screenshots along with the goal and history to a vision-capable
/// OpenAI model, enabling an observe-think-act agent loop.
///
/// Uses direct HTTP calls to the OpenAI Chat Completions API (no SDK dependency)
/// for maximum compatibility with the latest models.
///
/// ## Example
///
/// ```swift
/// let backend = OpenAIVisionBackend(apiKey: "sk-...")
/// let response = try await backend.generateActions(
///     goal: "Open Safari and search for Swift",
///     screenshot: jpegData,
///     screenSize: CGSize(width: 1920, height: 1080),
///     history: []
/// )
/// ```
public struct OpenAIVisionBackend: VisionActionGenerating, Sendable {

    private let apiKey: String
    private let model: String
    private let baseURL: String

    /// Creates an OpenAI vision backend.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - model: The vision-capable model to use (default: `gpt-4o`).
    ///   - baseURL: The API base URL (default: OpenAI).
    public init(apiKey: String, model: String = "gpt-4o", baseURL: String = "https://api.openai.com/v1") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public var isAvailable: Bool { true }
    public var unavailableReason: String? { nil }

    public func generateActions(
        goal: String,
        screenshot: Data,
        screenSize: CGSize,
        history: [AgentStep]
    ) async throws -> AgentResponse {
        let messages = buildMessages(
            goal: goal,
            screenshot: screenshot,
            screenSize: screenSize,
            history: history
        )

        let requestBody: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": messages,
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "agent_response",
                    "strict": true,
                    "schema": Self.agentResponseSchemaDict
                ] as [String: Any]
            ] as [String: Any]
        ]

        let requestData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ActionGeneratorError.invalidResponse(
                detail: "API returned HTTP \(httpResponse.statusCode): \(String(body.prefix(500)))"
            )
        }

        let json = try Self.parseJSON(data)

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            let preview = String(data: data, encoding: .utf8)?.prefix(500) ?? "(empty)"
            throw ActionGeneratorError.invalidResponse(
                detail: "Unexpected API response structure.\nRaw: \(preview)"
            )
        }

        let parsed = try Self.parseJSON(Data(content.utf8))

        let reasoning = parsed["reasoning"] as? String ?? ""
        let isDone = parsed["isDone"] as? Bool ?? false
        let actionsArray = parsed["actions"] as? [[String: Any]] ?? []
        let actions: [BasicAction] = actionsArray.compactMap { Self.parseAction($0) }

        return AgentResponse(actions: actions, reasoning: reasoning, isDone: isDone)
    }
}

// MARK: - Message Building

extension OpenAIVisionBackend {
    private func buildMessages(
        goal: String,
        screenshot: Data,
        screenSize: CGSize,
        history: [AgentStep]
    ) -> [[String: Any]] {
        var messages: [[String: Any]] = []

        // System prompt
        messages.append([
            "role": "system",
            "content": Self.buildSystemPrompt(screenSize: screenSize)
        ])

        // History steps
        for (index, step) in history.enumerated() {
            let actionSummary = step.actions.map { describeBasicAction($0) }.joined(separator: ", ")
            messages.append([
                "role": "assistant",
                "content": "Step \(index + 1): \(step.reasoning)\nActions executed: \(actionSummary)"
            ])
        }

        // Current screenshot + goal
        let base64 = screenshot.base64EncodedString()
        messages.append([
            "role": "user",
            "content": [
                [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64)",
                        "detail": "low"
                    ] as [String: Any]
                ] as [String: Any],
                [
                    "type": "text",
                    "text": "Goal: \(goal)\n\nThis is the current screenshot. What actions should I take next?"
                ] as [String: Any]
            ] as [[String: Any]]
        ] as [String: Any])

        return messages
    }

    private func describeBasicAction(_ action: BasicAction) -> String {
        switch action {
        case .write(let text): return "write(\"\(text)\")"
        case .move(let x, let y): return "move(\(Int(x)), \(Int(y)))"
        case .leftClick: return "leftClick"
        case .rightClick: return "rightClick"
        case .doubleClick: return "doubleClick"
        case .vscroll(let clicks): return "vscroll(\(clicks))"
        case .hscroll(let clicks): return "hscroll(\(clicks))"
        case .wait(let duration): return "wait(\(duration)s)"
        case .keyShortcut(let keys): return "keyShortcut(\(keys.joined(separator: "+")))"
        case .drag(let fromX, let fromY, let toX, let toY):
            return "drag(\(Int(fromX)),\(Int(fromY)) -> \(Int(toX)),\(Int(toY)))"
        }
    }
}

// MARK: - System Prompt

extension OpenAIVisionBackend {
    static func buildSystemPrompt(screenSize: CGSize) -> String {
        """
        You are an AI agent controlling a macOS computer to achieve a user's goal. \
        You will receive screenshots of the current screen state and must decide what actions to take.

        Screen size: \(Int(screenSize.width)) x \(Int(screenSize.height)) pixels (origin at top-left).

        Available action types and their parameters:
        - write: Type text. Parameters: text (string)
        - move: Move mouse to absolute position. Parameters: x (number), y (number)
        - leftClick: Left click at current position. No additional parameters needed.
        - rightClick: Right click at current position. No additional parameters needed.
        - doubleClick: Double click at current position. No additional parameters needed.
        - vscroll: Scroll vertically. Parameters: clicks (integer, positive=up, negative=down)
        - hscroll: Scroll horizontally. Parameters: clicks (integer, positive=right, negative=left)
        - wait: Wait for a duration. Parameters: duration (number, in seconds)
        - keyShortcut: Press a keyboard shortcut. Parameters: keys (array of strings). \
        Use key names: "command", "shift", "control", "option", "a"-"z", "0"-"9", \
        "returnKey", "space", "delete", "tab", "escape", "upArrow", "downArrow", "leftArrow", "rightArrow", \
        "f1"-"f20".
        - drag: Drag mouse from one position to another. Parameters: fromX, fromY, toX, toY (numbers)

        Instructions:
        1. Analyze the screenshot to understand the current screen state.
        2. Decide the next action(s) to move toward the goal.
        3. Set isDone to true ONLY when the goal has been fully achieved.
        4. Provide brief reasoning about what you see and why you chose these actions.
        5. Use move + leftClick to click on UI elements. First move to the element, then click.
        6. Keep action sequences short (1-3 actions per step) to allow re-observation.

        Respond with a JSON object containing "reasoning", "isDone", and "actions" fields.
        """
    }
}

// MARK: - Action Parsing

extension OpenAIVisionBackend {
    /// Parse a single action from a JSON dictionary, tolerating null fields.
    static func parseAction(_ dict: [String: Any]) -> BasicAction? {
        guard let type = dict["type"] as? String else { return nil }

        switch type {
        case "write":
            let text = dict["text"] as? String ?? ""
            return .write(text: text)
        case "move":
            let x = (dict["x"] as? NSNumber)?.doubleValue ?? 0
            let y = (dict["y"] as? NSNumber)?.doubleValue ?? 0
            return .move(x: x, y: y)
        case "leftClick":
            return .leftClick
        case "rightClick":
            return .rightClick
        case "doubleClick":
            return .doubleClick
        case "vscroll":
            let clicks = (dict["clicks"] as? NSNumber)?.intValue ?? 0
            return .vscroll(clicks: clicks)
        case "hscroll":
            let clicks = (dict["clicks"] as? NSNumber)?.intValue ?? 0
            return .hscroll(clicks: clicks)
        case "wait":
            let duration = (dict["duration"] as? NSNumber)?.doubleValue ?? 0
            return .wait(duration: duration)
        case "keyShortcut":
            let keys = dict["keys"] as? [String] ?? []
            return .keyShortcut(keys: keys)
        case "drag":
            let fromX = (dict["fromX"] as? NSNumber)?.doubleValue ?? 0
            let fromY = (dict["fromY"] as? NSNumber)?.doubleValue ?? 0
            let toX = (dict["toX"] as? NSNumber)?.doubleValue ?? 0
            let toY = (dict["toY"] as? NSNumber)?.doubleValue ?? 0
            return .drag(fromX: fromX, fromY: fromY, toX: toX, toY: toY)
        default:
            return nil
        }
    }
}

// MARK: - JSON Parsing

extension OpenAIVisionBackend {
    /// Parse JSON data robustly, handling trailing whitespace/newlines that
    /// some API responses include.
    static func parseJSON(_ data: Data) throws -> [String: Any] {
        guard let str = String(data: data, encoding: .utf8) else {
            throw ActionGeneratorError.invalidResponse(detail: "Response is not valid UTF-8")
        }

        // Handle SSE streaming format: extract JSON from "data: {...}" lines
        var jsonString = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("data: ") {
            let lines = jsonString.components(separatedBy: "\n")
            var lastJSON: String?
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.hasPrefix("data: ") && trimmedLine != "data: [DONE]" {
                    lastJSON = String(trimmedLine.dropFirst(6))
                }
            }
            jsonString = lastJSON ?? jsonString
        }

        // Extract only the JSON object by finding balanced braces.
        // Some API responses include trailing bytes (newlines, chunked encoding
        // markers, etc.) that cause JSONSerialization to fail with
        // "Garbage at end".
        jsonString = Self.extractJSONObject(from: jsonString) ?? jsonString

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ActionGeneratorError.invalidResponse(
                detail: "Not a JSON object.\nRaw (\(data.count) bytes): \(String(str.prefix(800)))"
            )
        }
        return json
    }

    /// Finds the first top-level `{ … }` in the string by counting balanced braces.
    private static func extractJSONObject(from string: String) -> String? {
        guard let startIdx = string.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escaped = false
        var endIdx: String.Index?

        for i in string[startIdx...].indices {
            let ch = string[i]
            if escaped { escaped = false; continue }
            if ch == "\\" && inString { escaped = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            if inString { continue }
            if ch == "{" { depth += 1 }
            else if ch == "}" {
                depth -= 1
                if depth == 0 { endIdx = i; break }
            }
        }

        guard let end = endIdx else { return nil }
        return String(string[startIdx...end])
    }
}

// MARK: - JSON Schema (as Dictionary for direct HTTP call)

extension OpenAIVisionBackend {
    nonisolated(unsafe) static let actionItemSchemaDict: [String: Any] = [
        "type": "object",
        "description": "A single automation action.",
        "properties": [
            "type": [
                "type": "string",
                "description": "The action type.",
                "enum": ["write", "move", "leftClick", "rightClick", "doubleClick",
                         "vscroll", "hscroll", "wait", "keyShortcut", "drag"]
            ] as [String: Any],
            "text": ["type": ["string", "null"], "description": "Text to type. Used with 'write' action."] as [String: Any],
            "x": ["type": ["number", "null"], "description": "X coordinate. Used with 'move' action."] as [String: Any],
            "y": ["type": ["number", "null"], "description": "Y coordinate. Used with 'move' action."] as [String: Any],
            "clicks": ["type": ["integer", "null"], "description": "Scroll clicks. Used with 'vscroll'/'hscroll'."] as [String: Any],
            "duration": ["type": ["number", "null"], "description": "Wait duration in seconds."] as [String: Any],
            "keys": ["type": ["array", "null"], "description": "Key names for shortcut.", "items": ["type": "string"]] as [String: Any],
            "fromX": ["type": ["number", "null"], "description": "Start X. Used with 'drag'."] as [String: Any],
            "fromY": ["type": ["number", "null"], "description": "Start Y. Used with 'drag'."] as [String: Any],
            "toX": ["type": ["number", "null"], "description": "End X. Used with 'drag'."] as [String: Any],
            "toY": ["type": ["number", "null"], "description": "End Y. Used with 'drag'."] as [String: Any],
        ] as [String: Any],
        "required": ["type", "text", "x", "y", "clicks", "duration", "keys", "fromX", "fromY", "toX", "toY"],
        "additionalProperties": false
    ] as [String: Any]

    nonisolated(unsafe) static let agentResponseSchemaDict: [String: Any] = [
        "type": "object",
        "description": "Agent response with reasoning, completion status, and actions.",
        "properties": [
            "reasoning": [
                "type": "string",
                "description": "Brief reasoning about the current screen state and chosen actions."
            ] as [String: Any],
            "isDone": [
                "type": "boolean",
                "description": "Whether the goal has been fully achieved."
            ] as [String: Any],
            "actions": [
                "type": "array",
                "description": "The array of actions to execute.",
                "items": actionItemSchemaDict
            ] as [String: Any]
        ] as [String: Any],
        "required": ["reasoning", "isDone", "actions"],
        "additionalProperties": false
    ] as [String: Any]
}

// MARK: - NSImage JPEG Conversion

extension NSImage {
    /// Converts the image to JPEG data.
    ///
    /// - Parameter compressionFactor: JPEG compression quality (0.0 to 1.0).
    /// - Returns: JPEG data, or nil if conversion fails.
    func jpegData(compressionFactor: CGFloat = 0.5) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor])
    }
}
