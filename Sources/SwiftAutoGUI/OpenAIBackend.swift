//
//  OpenAIBackend.swift
//  SwiftAutoGUI
//

import Foundation
@preconcurrency import OpenAI

// MARK: - OpenAIBackend

/// An ``ActionGenerating`` backend that uses the OpenAI API.
///
/// This backend sends natural language prompts to OpenAI's chat completion API
/// and uses Structured Outputs to get well-formed action JSON.
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

    private let client: OpenAI
    private let model: Model

    /// Creates an OpenAI backend.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - model: The model to use (default: `gpt-4.1-nano`).
    public init(apiKey: String, model: String = "gpt-4.1-nano") {
        self.client = OpenAI(apiToken: apiKey)
        self.model = Model(model)
    }

    public var isAvailable: Bool {
        true
    }

    public var unavailableReason: String? {
        nil
    }

    public func generateAction(from prompt: String) async throws -> Action {
        let actions = try await generateActionSequence(from: prompt)
        guard let first = actions.first else {
            throw ActionGeneratorError.noActionsGenerated
        }
        return first
    }

    public func generateActionSequence(from prompt: String) async throws -> [Action] {
        let query = ChatQuery(
            messages: [
                .system(.init(content: .textContent(Self.systemPrompt))),
                .user(.init(content: .string(prompt)))
            ],
            model: model,
            responseFormat: .jsonSchema(.init(
                name: "action_sequence",
                schema: .jsonSchema(Self.actionsSchema),
                strict: true
            ))
        )

        let result = try await client.chats(query: query)

        guard let content = result.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw ActionGeneratorError.invalidResponse(detail: "No content in response")
        }

        let wrapper = try JSONDecoder().decode(ActionsWrapper.self, from: data)
        let actions = wrapper.actions.map { $0.toAction() }

        guard !actions.isEmpty else {
            throw ActionGeneratorError.noActionsGenerated
        }

        return actions
    }
}

// MARK: - Response Wrapper

private struct ActionsWrapper: Codable {
    let actions: [BasicAction]
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

// MARK: - JSON Schema for Structured Outputs

extension OpenAIBackend {
    /// JSON Schema for the actions wrapper object.
    ///
    /// Uses flat object format with all fields required (nullable for optional ones),
    /// because OpenAI's strict mode does not fully support `oneOf`/`anyOf`.
    static let actionsSchema: JSONSchema = .init(
        .type(.object),
        .description("A wrapper containing an array of automation actions."),
        .properties([
            "actions": JSONSchema(
                .type(.array),
                .description("The array of actions to execute."),
                .items(actionItemSchema)
            )
        ]),
        .required(["actions"]),
        .additionalProperties(.boolean(false))
    )

    /// JSON Schema for a single action item (flat object, type-discriminated).
    private static let actionItemSchema: JSONSchema = .init(
        .type(.object),
        .description("A single automation action."),
        .properties([
            "type": JSONSchema(
                .type(.string),
                .description("The action type."),
                .enumValues([
                    "write", "move", "leftClick", "rightClick", "doubleClick",
                    "vscroll", "hscroll", "wait", "keyShortcut", "drag"
                ] as [String])
            ),
            "text": JSONSchema(
                .type(.types(["string", "null"])),
                .description("Text to type. Used with 'write' action.")
            ),
            "x": JSONSchema(
                .type(.types(["number", "null"])),
                .description("X coordinate for mouse position. Used with 'move' action.")
            ),
            "y": JSONSchema(
                .type(.types(["number", "null"])),
                .description("Y coordinate for mouse position. Used with 'move' action.")
            ),
            "clicks": JSONSchema(
                .type(.types(["integer", "null"])),
                .description("Number of scroll clicks. Used with 'vscroll' and 'hscroll' actions.")
            ),
            "duration": JSONSchema(
                .type(.types(["number", "null"])),
                .description("Wait duration in seconds. Used with 'wait' action.")
            ),
            "keys": JSONSchema(
                .type(.types(["array", "null"])),
                .description("Key names for shortcut. Used with 'keyShortcut' action."),
                .items(JSONSchema(.type(.string)))
            ),
            "fromX": JSONSchema(
                .type(.types(["number", "null"])),
                .description("Start X coordinate. Used with 'drag' action.")
            ),
            "fromY": JSONSchema(
                .type(.types(["number", "null"])),
                .description("Start Y coordinate. Used with 'drag' action.")
            ),
            "toX": JSONSchema(
                .type(.types(["number", "null"])),
                .description("End X coordinate. Used with 'drag' action.")
            ),
            "toY": JSONSchema(
                .type(.types(["number", "null"])),
                .description("End Y coordinate. Used with 'drag' action.")
            )
        ]),
        .required(["type", "text", "x", "y", "clicks", "duration", "keys", "fromX", "fromY", "toX", "toY"]),
        .additionalProperties(.boolean(false))
    )
}
