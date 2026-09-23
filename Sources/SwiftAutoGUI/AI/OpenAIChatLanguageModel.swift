import Foundation
import FoundationModels
import FoundationModelsUtilities

/// An OpenAI-compatible LanguageModel using Apple's Chat Completions transport.
/// Normalizes generated enum discriminators to the endpoint's strict JSON Schema
/// subset. Action schemas still come exclusively from Generable domain types.
public struct OpenAIChatLanguageModel: LanguageModel {
    let client: ChatCompletionsLanguageModel
    public let capabilities: LanguageModelCapabilities

    /// Advertise only capabilities verified for the configured endpoint/model.
    /// Apple's beta5 transport does not forward reasoning levels.
    public init(
        client: ChatCompletionsLanguageModel,
        capabilities: LanguageModelCapabilities = .init([.vision, .guidedGeneration, .toolCalling])
    ) {
        self.client = client
        self.capabilities = capabilities
    }

    public var executorConfiguration: Executor.Configuration { client.executorConfiguration }

    public struct Executor: LanguageModelExecutor {
        public typealias Model = OpenAIChatLanguageModel
        public typealias Configuration = ChatCompletionsLanguageModel.Executor.Configuration
        private let transport: ChatCompletionsLanguageModel.Executor

        public init(configuration: Configuration) {
            transport = ChatCompletionsLanguageModel.Executor(configuration: configuration)
        }

        public func prewarm(model: Model, transcript: Transcript) {
            transport.prewarm(model: model.client, transcript: transcript)
        }

        public func respond(
            to request: LanguageModelExecutorGenerationRequest,
            model: Model,
            streamingInto channel: LanguageModelExecutorGenerationChannel
        ) async throws {
            var request = request
            if let schema = request.schema {
                request.schema = try Self.strictSchema(schema)
            }
            for index in request.enabledToolDefinitions.indices {
                request.enabledToolDefinitions[index].parameters = try Self.strictSchema(
                    request.enabledToolDefinitions[index].parameters)
            }
            try await transport.respond(to: request, model: model.client, streamingInto: channel)
        }

        static func strictSchema(_ schema: GenerationSchema) throws -> GenerationSchema {
            let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(schema))
            let data = try JSONSerialization.data(withJSONObject: normalize(object))
            return try JSONDecoder().decode(GenerationSchema.self, from: data)
        }

        private static func normalize(_ value: Any) -> Any {
            if let array = value as? [Any] { return array.map(normalize) }
            guard var object = value as? [String: Any] else { return value }
            object = object.mapValues(normalize)
            // Swift's associated-value enum schema emits untyped string constants.
            // OpenAI strict output requires a typed discriminator. A singleton
            // enum is semantically equivalent and supported by both frameworks.
            if let constant = object["const"] as? String {
                object.removeValue(forKey: "const")
                object["type"] = "string"
                object["enum"] = [constant]
            }
            return object
        }
    }
}
