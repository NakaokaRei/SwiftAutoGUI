import AppKit
import Foundation
import FoundationModels
import Synchronization
import Testing
@testable import SwiftAutoGUI

@Suite("Chat Completions transport", .serialized)
struct ChatCompletionsIntegrationTests {
    @Test("Agent wire request preserves current context and image and restricts native actions")
    @MainActor
    func agentContextTransport() async throws {
        let output = AgentDecision(actions: [.write(text: "hello world")],
            reasoningSummary: "Type text", isDone: false).generatedContent.jsonString
        StubChatProtocol.state.withLock { $0 = .init(output: output) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubChatProtocol.self]
        let model = AutomationModels.openAI(apiKey: "test-only", model: "mock",
            baseURL: URL(string: "https://example.invalid")!, urlSessionConfiguration: config)
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 4, pixelsHigh: 4,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let pixels = try #require(bitmap.bitmapData)
        pixels.initialize(repeating: 255, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
        let jpeg = try #require(bitmap.representation(using: .jpeg, properties: [:]))
        let session = ActionSession(model: model, instructions: Agent.instructions)
        for context in ["OLD_OBSERVATION", "CURRENT_FOCUSED_EDITOR"] {
            let observation = AgentObservation(kind: .native, formattedContext: context,
                stateFingerprint: context, actionableElementCount: 0,
                viewportSize: CGSize(width: 1440, height: 900), screenshotJPEGData: jpeg)
            let decision = try await Agent.decision(session: session, goal: "Type hello world",
                observation: observation, lastStep: nil)
            guard case .write(let text) = decision.actions.first else {
                Issue.record("Text entry was lost during response decoding"); return
            }
            #expect(text == "hello world")
        }
        let body = try #require(StubChatProtocol.state.withLock { $0.body })
        let request = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let messages = try #require(request["messages"] as? [[String: Any]])
        #expect(messages.contains { ($0["content"] as? String)?.contains("Help accomplish") == true })
        let parts = messages.flatMap { $0["content"] as? [[String: Any]] ?? [] }
        #expect(parts.contains { ($0["text"] as? String)?.contains("CURRENT_FOCUSED_EDITOR") == true })
        #expect(parts.contains { ($0["text"] as? String)?.contains("Type hello world") == true })
        let images = parts.filter { $0["type"] as? String == "image_url" }
        #expect(images.count == 1)
        let url = try #require((images.first?["image_url"] as? [String: Any])?["url"] as? String)
        #expect(url.hasPrefix("data:image/jpeg;base64,"))
        let imageData = try #require(Data(base64Encoded: String(url.split(separator: ",", maxSplits: 1)[1])))
        let decoded = try #require(NSBitmapImageRep(data: imageData))
        #expect(decoded.pixelsWide == 4 && decoded.pixelsHigh == 4)
        let format = try #require(request["response_format"] as? [String: Any])
        let wrapper = try #require(format["json_schema"] as? [String: Any])
        let schema = try #require(wrapper["schema"] as? [String: Any])
        let definitions = try #require(schema["$defs"] as? [String: Any])
        #expect(definitions["DiscriminatedWrite"] != nil)
        #expect(definitions["DiscriminatedActivateTab"] == nil)
        #expect(definitions["DiscriminatedSetElementValue"] == nil)
    }

    @Test("Associated-value enum schemas preserve typed discriminators after normalization")
    func strictDiscriminators() throws {
        let schema = try OpenAIChatLanguageModel.Executor.strictSchema(AgentDecision.generationSchema)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(schema))
        func check(_ value: Any) {
            if let array = value as? [Any] { array.forEach(check) }
            if let object = value as? [String: Any] {
                if object["const"] != nil || object["enum"] != nil {
                    #expect(object["type"] != nil)
                }
                object.values.forEach(check)
            }
        }
        check(object)
    }

    @Test("Apple adapter sends the shared schema and decodes SSE without network")
    func structuredTransport() async throws {
        let output = SingleAction(action: .write(text: "hello")).generatedContent.jsonString
        StubChatProtocol.state.withLock { $0 = .init(output: output) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubChatProtocol.self]
        let model = AutomationModels.openAI(apiKey: "test-only", model: "mock",
            baseURL: URL(string: "https://example.invalid")!, urlSessionConfiguration: configuration)
        let action = try await ActionGenerator(model: model).generateAction(from: "Type hello")
        guard case .write(let text, _) = action else {
            Issue.record("Expected a generated write action"); return
        }
        #expect(text == "hello")
        let captured = StubChatProtocol.state.withLock { $0 }
        #expect(captured.path == "/v1/chat/completions")
        let body = try #require(captured.body)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["model"] as? String == "mock")
        #expect(object["stream"] as? Bool == true)
        let format = try #require(object["response_format"] as? [String: Any])
        let wrapper = try #require(format["json_schema"] as? [String: Any])
        #expect(wrapper["strict"] as? Bool == true)
        let schema = try #require(wrapper["schema"] as? [String: Any])
        #expect(schema["type"] as? String == "object")
        #expect(schema["anyOf"] == nil)
        // Inspect the actual outgoing OpenAI schema, not just our Swift type.
        func containsKeyChoices(_ value: Any) -> Bool {
            if let array = value as? [Any] { return array.contains(where: containsKeyChoices) }
            guard let object = value as? [String: Any] else { return false }
            if let values = object["enum"] as? [String],
               Set(values) == Set(Key.allCases.map(\.rawValue)) { return true }
            return object.values.contains(where: containsKeyChoices)
        }
        #expect(containsKeyChoices(schema))
    }
}

/// URLSession serializes this protocol instance's callbacks. Shared test state
/// is protected by Mutex; no mutable instance fields are introduced.
private final class StubChatProtocol: URLProtocol, @unchecked Sendable {
    struct State {
        var output = ""
        var path: String?
        var body: Data?
    }
    static let state = Mutex(State())
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            var data = Data()
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(contentsOf: buffer.prefix(count))
            }
            body = data
        }
        let output = Self.state.withLock { state in
            state.path = request.url?.path
            state.body = body
            return state.output
        }
        do {
            let chunk: [String: Any] = ["id": "test", "model": "mock",
                "choices": [["delta": ["content": output]]]]
            let json = try JSONSerialization.data(withJSONObject: chunk)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/event-stream"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("data: ".utf8) + json + Data("\n\ndata: [DONE]\n\n".utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

/// Explicit opt-in only. Generates decisions from synthetic input, never executes them.
@Suite("Live model smoke tests")
struct LiveModelSmokeTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "openai"), arguments: 0..<3)
    func openAIEditorTyping(attempt: Int) async throws {
        let key = try #require(ProcessInfo.processInfo.environment["OPENAI_API_KEY"])
        let model = AutomationModels.openAI(apiKey: key)
        let session = ActionSession(model: model, instructions: Agent.instructions,
                                    options: .init(maximumResponseTokens: 512))
        let observation = AgentObservation(kind: .native,
            formattedContext: "Frontmost application: Visual Studio Code. Window: Untitled-1. Focused element: AXTextArea. Empty new text editor focused, caret at line 1 column 1.",
            stateFingerprint: "synthetic-editor", actionableElementCount: 0,
            viewportSize: CGSize(width: 1440, height: 900))
        do {
            let result = try await Agent.decision(session: session,
                goal: "Visual Studio Codeを開き、新規テキストファイルにhello worldと入力してください。保存は不要です。",
                observation: observation, lastStep: nil)
            print("SYNTHETIC_EDITOR_ACTIONS", result.actions)
            #expect(result.actions.contains { if case .write(let text) = $0 { text == "hello world" } else { false } })
        } catch {
            let diagnostic = error.localizedDescription.replacingOccurrences(of: key, with: "[redacted]")
            Issue.record("Editor generation failed: \(diagnostic)")
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "on-device"))
    func onDeviceSpotlightShortcut() async throws {
        let session = ActionSession(model: SystemLanguageModel.default, instructions: Agent.instructions,
                                    options: .init(maximumResponseTokens: 512))
        let generated = try await session.respond(
            to: Prompt("Open Spotlight using the Command + Space keyboard shortcut. Generate exactly that shortcut; do not activate an app or browser tab."),
            generating: SingleAction.self)
        guard case .keyShortcut(let keys) = generated.action else {
            Issue.record("Expected a keyboard shortcut, received: \(generated.action)")
            return
        }
        #expect(keys == [.command, .space])
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "on-device"))
    func onDevice() async throws {
        let model = SystemLanguageModel.default
        if let reason = AutomationModels.unavailableReason(for: model) {
            throw ActionGeneratorError.backendUnavailable(reason: reason)
        }
        _ = try await ActionGenerator(model: model).generateAction(from: "Type hello")
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "on-device"))
    @MainActor
    func onDeviceSafariAction() async throws {
        let session = ActionSession(model: SystemLanguageModel.default, instructions: Agent.instructions,
                                    options: .init(maximumResponseTokens: 512))
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 32,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let pixels = try #require(bitmap.bitmapData)
        pixels.initialize(repeating: 255, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
        let jpeg = try #require(bitmap.representation(using: .jpeg, properties: [:]))
        let observation = AgentObservation(kind: .native,
            formattedContext: "Frontmost application: Xcode. Window: Sample. Safari is not open.",
            stateFingerprint: "synthetic", actionableElementCount: 0,
            viewportSize: CGSize(width: 1440, height: 900))
        for index in 0..<5 {
            // Exercise text, images, and an AX tree much larger than the 4K context.
            let current = index == 0 ? observation : AgentObservation(kind: .native,
                formattedContext: observation.formattedContext + (index == 4 ? String(repeating: "\n[#1] AXButton Test button", count: 1200) : ""),
                stateFingerprint: "synthetic", actionableElementCount: 0,
                viewportSize: observation.viewportSize, screenshotJPEGData: jpeg)
            let decision = try await Agent.decision(session: session,
                goal: "Open Safari and search for Swift programming", observation: current, lastStep: nil)
            #expect(!decision.actions.isEmpty)
            #expect(!decision.isDone)
            guard case .activateApp(let name) = decision.actions.first else {
                Issue.record("Expected Safari activation, received: \(decision.actions)")
                continue
            }
            #expect(name.lowercased().contains("safari"))
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "openai"))
    func openAI() async throws {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            throw ActionGeneratorError.invalidConfiguration("OPENAI_API_KEY is required for this opt-in test.")
        }
        let model = AutomationModels.openAI(
            apiKey: key,
            model: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_TEST_MODEL"] ?? AutomationModels.defaultTextModel)
        do {
            let actions = try await ActionGenerator(model: model).generateActionSequence(from: "Type exactly hello, using one write action.")
            #expect(!actions.isEmpty)
        } catch {
            // The prompt is synthetic; still redact the credential from any provider diagnostic.
            let diagnostic = error.localizedDescription.replacingOccurrences(of: key, with: "[redacted]")
            Issue.record("OpenAI generation failed: \(diagnostic)")
        }
    }
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "on-device"))
    @MainActor
    func onDeviceVision() async throws {
        try await vision(model: SystemLanguageModel.default)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_MODEL_TESTS"] == "openai"))
    @MainActor
    func openAIVision() async throws {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            throw ActionGeneratorError.invalidConfiguration("OPENAI_API_KEY is required for this opt-in test.")
        }
        do {
            try await vision(model: AutomationModels.openAI(apiKey: key))
        } catch {
            let diagnostic = error.localizedDescription.replacingOccurrences(of: key, with: "[redacted]")
            Issue.record("OpenAI image generation failed: \(diagnostic)")
        }
    }

    @MainActor
    private func vision(model: some LanguageModel) async throws {
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 32,
            bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let pixels = try #require(bitmap.bitmapData)
        pixels.initialize(repeating: 255, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
        let image = try #require(bitmap.cgImage)
        let prompt = Prompt {
            "This is a synthetic white tile. No computer interaction is required. Return no actions and isDone true."
            Attachment(image)
        }
        let session = ActionSession(model: model, instructions: Agent.instructions,
                                    options: .init(maximumResponseTokens: 512))
        let decision = try await session.respond(to: prompt, generating: AgentDecision.self, includesImage: true)
        #expect(decision.actions.isEmpty)
        #expect(decision.isDone)
    }

}
