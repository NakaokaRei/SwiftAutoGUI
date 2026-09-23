import Foundation
import FoundationModels

/// Restrict the shared Generable schema to actions the current environment can use.
enum AgentActionSchema {
    static func make(
        _ schema: GenerationSchema, kind: AgentObservationKind, allowsElementIDs: Bool
    ) throws -> GenerationSchema {
        guard var root = try JSONSerialization.jsonObject(with: JSONEncoder().encode(schema)) as? [String: Any] else {
            throw ActionGeneratorError.invalidConfiguration("Expected an object generation schema.")
        }
        guard var definitions = root["$defs"] as? [String: Any] else { return schema }
        let browserActions: Set<String> = [
            "pressElement", "setElementValue", "openURL", "keyShortcut",
            "vscroll", "hscroll", "wait", "activateTab"
        ]
        var excluded = Set<String>()
        for (name, value) in definitions {
            guard let definition = value as? [String: Any],
                  let properties = definition["properties"] as? [String: Any],
                  let discriminator = properties["type"] as? [String: Any],
                  let action = discriminator["const"] as? String else { continue }
            if (kind == .native && action == "activateTab")
                || (kind == .browser && !browserActions.contains(action))
                || (!allowsElementIDs && ["pressElement", "setElementValue"].contains(action)) {
                excluded.insert("#/$defs/\(name)")
            }
        }
        func filter(_ value: Any) -> Any {
            if let array = value as? [Any] { return array.map(filter) }
            guard var object = value as? [String: Any] else { return value }
            if let alternatives = object["anyOf"] as? [[String: Any]] {
                object["anyOf"] = alternatives.filter { candidate in
                    guard let reference = candidate["$ref"] as? String else { return true }
                    return !excluded.contains(reference)
                }
            }
            return object.mapValues(filter)
        }
        definitions = definitions.filter { !excluded.contains("#/$defs/\($0.key)") }
        root["$defs"] = definitions
        return try JSONDecoder().decode(GenerationSchema.self,
            from: JSONSerialization.data(withJSONObject: filter(root)))
    }
}
