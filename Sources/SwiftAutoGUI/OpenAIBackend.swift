//
//  OpenAIBackend.swift
//  SwiftAutoGUI
//

import Foundation

// MARK: - OpenAIBackend

/// An ``ActionGenerating`` backend that uses the OpenAI API.
///
/// This backend sends natural language prompts to OpenAI's chat completion API
/// and uses Structured Outputs to get well-formed action JSON via the Responses API.
///
/// ## Example
///
/// ```swift
/// let backend = OpenAIBackend(apiKey: "sk-...")
/// let action = try await backend.generateAction(from: "click at 100, 200")
/// await action.execute()
///
/// // With a specific model
/// let backend = OpenAIBackend(apiKey: "sk-...", model: "gpt-4o")
/// ```
///
/// ## Security
///
/// Never hard-code API keys in source code. Use environment variables or secure storage.
public struct OpenAIBackend: ActionGenerating, Sendable {

    private let apiKey: String
    private let model: String
    private let baseURL: String

    /// Creates an OpenAI backend.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - model: The model to use (default: `gpt-4.1-nano`).
    ///   - baseURL: The API base URL (default: OpenAI).
    public init(apiKey: String, model: String = "gpt-4.1-nano", baseURL: String = "https://api.openai.com/v1") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public var isAvailable: Bool { true }
    public var unavailableReason: String? { nil }

    public func generateAction(from prompt: String) async throws -> Action {
        let actions = try await generateActionSequence(from: prompt)
        guard let first = actions.first else {
            throw ActionGeneratorError.noActionsGenerated
        }
        return first
    }

    public func generateActionSequence(from prompt: String) async throws -> [Action] {
        let requestBody: [String: Any] = [
            "model": model,
            "instructions": Self.systemPrompt,
            "input": prompt,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "action_sequence",
                    "strict": true,
                    "schema": Self.actionsSchemaDict
                ] as [String: Any]
            ] as [String: Any]
        ]

        let requestData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: "\(baseURL)/responses")!)
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

        let json = try OpenAIVisionBackend.parseJSON(data)

        guard let output = json["output"] as? [[String: Any]],
              let message = output.first(where: { $0["type"] as? String == "message" }),
              let messageContent = message["content"] as? [[String: Any]],
              let textItem = messageContent.first(where: { $0["type"] as? String == "output_text" }),
              let content = textItem["text"] as? String else {
            let preview = String(data: data, encoding: .utf8)?.prefix(500) ?? "(empty)"
            throw ActionGeneratorError.invalidResponse(
                detail: "Unexpected API response structure.\nRaw: \(preview)"
            )
        }

        let parsed = try OpenAIVisionBackend.parseJSON(Data(content.utf8))

        let actionsArray = parsed["actions"] as? [[String: Any]] ?? []
        let actions: [Action] = actionsArray.compactMap { dict in
            OpenAIVisionBackend.parseAction(dict)?.toAction()
        }

        guard !actions.isEmpty else {
            throw ActionGeneratorError.noActionsGenerated
        }

        return actions
    }
}

// MARK: - System Prompt

extension OpenAIBackend {
    static let systemPrompt = """
        You are an automation action generator for macOS. Convert natural language descriptions \
        into a JSON array of actions.

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

        Respond with a JSON object containing an "actions" array. Each action must have a "type" field \
        and the relevant parameters for that type. For parameters not relevant to the action type, \
        use null for optional string/number fields, 0 for integer fields, and empty array for array fields.
        """
}

// MARK: - JSON Schema (as Dictionary)

extension OpenAIBackend {
    nonisolated(unsafe) static let actionsSchemaDict: [String: Any] = [
        "type": "object",
        "description": "A wrapper containing an array of automation actions.",
        "properties": [
            "actions": [
                "type": "array",
                "description": "The array of actions to execute.",
                "items": OpenAIVisionBackend.actionItemSchemaDict
            ] as [String: Any]
        ] as [String: Any],
        "required": ["actions"],
        "additionalProperties": false
    ] as [String: Any]
}
