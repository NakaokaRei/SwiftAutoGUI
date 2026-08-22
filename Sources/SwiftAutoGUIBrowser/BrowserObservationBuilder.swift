import Foundation

struct BrowserAXCandidate: Sendable, Equatable {
    let backendDOMNodeID: Int
    let frameID: String?
    let role: String
    let name: String
    let value: String?
    let isEnabled: Bool
    let isEditable: Bool
}

enum BrowserSelectorMapBuilder {
    private static let actionableRoles: Set<String> = [
        "button", "link", "textbox", "searchbox", "checkbox", "radio",
        "combobox", "listbox", "menuitem", "option", "tab", "switch",
        "slider", "spinbutton", "treeitem"
    ]

    static func candidates(from result: CDPJSONValue, limit: Int) -> [BrowserAXCandidate] {
        let nodes = result["nodes"]?.arrayValue ?? []
        var output: [BrowserAXCandidate] = []
        output.reserveCapacity(min(nodes.count, limit))

        for node in nodes {
            guard output.count < limit,
                  node["ignored"]?.boolValue != true,
                  let backendID = node["backendDOMNodeId"]?.intValue,
                  let role = nestedString(node["role"]),
                  !role.isEmpty else { continue }

            let properties = propertyMap(node["properties"]?.arrayValue ?? [])
            let isHidden = properties["hidden"]?.boolValue == true
            let isDisabled = properties["disabled"]?.boolValue == true
            let isEditable = properties["editable"]?.boolValue == true
                || properties["settable"]?.boolValue == true
            let isFocusable = properties["focusable"]?.boolValue == true
            guard !isHidden,
                  actionableRoles.contains(role.lowercased()) || isEditable || isFocusable else { continue }

            output.append(
                BrowserAXCandidate(
                    backendDOMNodeID: backendID,
                    frameID: node["frameId"]?.stringValue,
                    role: role,
                    name: nestedString(node["name"]) ?? "",
                    value: nestedString(node["value"]),
                    isEnabled: !isDisabled,
                    isEditable: isEditable || ["textbox", "searchbox"].contains(role.lowercased())
                )
            )
        }
        return output
    }

    static func elements(
        candidates: [BrowserAXCandidate],
        bounds: [Int: BrowserRect],
        destinationURLs: [Int: String]
    ) -> [BrowserElement] {
        var nextID = 1
        return candidates.compactMap { candidate in
            guard candidate.isEnabled,
                  let rect = bounds[candidate.backendDOMNodeID],
                  rect.width > 0,
                  rect.height > 0 else { return nil }
            defer { nextID += 1 }
            return BrowserElement(
                elementID: nextID,
                backendDOMNodeID: candidate.backendDOMNodeID,
                frameID: candidate.frameID,
                role: candidate.role,
                name: candidate.name,
                value: candidate.value,
                bounds: rect,
                isEnabled: candidate.isEnabled,
                isEditable: candidate.isEditable,
                destinationURL: destinationURLs[candidate.backendDOMNodeID]
            )
        }
    }

    static func format(tabs: [BrowserTab], activeTabID: String, elements: [BrowserElement]) -> String {
        var lines = ["Browser tabs:"]
        for tab in tabs {
            let active = tab.id == activeTabID ? " active" : ""
            lines.append("  [tab:\(tab.id)] \"\(tab.title)\" \(tab.url) state=\(tab.state.rawValue)\(active)")
        }
        lines.append("Actionable page elements:")
        if elements.isEmpty { lines.append("  (none)") }
        for element in elements {
            var line = "  [#\(element.elementID)] \(element.role)"
            if !element.name.isEmpty { line += " \"\(element.name)\"" }
            if let value = element.value, !value.isEmpty { line += " value=\"\(value.prefix(120))\"" }
            let rect = element.bounds
            line += " {\(Int(rect.x)),\(Int(rect.y)) \(Int(rect.width))x\(Int(rect.height))}"
            if element.isEditable { line += " editable" }
            if let url = element.destinationURL { line += " url=\"\(url)\"" }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    static func fingerprint(
        tab: BrowserTab,
        loaderID: String,
        elements: [BrowserElement]
    ) -> String {
        var lines = ["tab:\(tab.id):\(tab.url):\(loaderID)"]
        for element in elements {
            lines.append(
                "\(element.backendDOMNodeID):\(element.role):\(element.name):\(element.value ?? ""):" +
                "\(Int(element.bounds.x)),\(Int(element.bounds.y)),\(Int(element.bounds.width)),\(Int(element.bounds.height))"
            )
        }
        return lines.joined(separator: "\n")
    }

    static func bounds(from boxModelResult: CDPJSONValue) -> BrowserRect? {
        guard let quad = boxModelResult["model"]?["border"]?.arrayValue?.compactMap(\.doubleValue),
              quad.count >= 8 else { return nil }
        let xs = stride(from: 0, to: quad.count, by: 2).map { quad[$0] }
        let ys = stride(from: 1, to: quad.count, by: 2).map { quad[$0] }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }
        return BrowserRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func destinationURL(from describeNodeResult: CDPJSONValue) -> String? {
        guard let attributes = describeNodeResult["node"]?["attributes"]?.arrayValue?.compactMap(\.stringValue) else {
            return nil
        }
        var index = 0
        while index + 1 < attributes.count {
            if attributes[index].lowercased() == "href" { return attributes[index + 1] }
            index += 2
        }
        return nil
    }

    private static func propertyMap(_ properties: [CDPJSONValue]) -> [String: CDPJSONValue] {
        Dictionary(uniqueKeysWithValues: properties.compactMap { property in
            guard let name = property["name"]?.stringValue,
                  let value = property["value"]?["value"] else { return nil }
            return (name, value)
        })
    }

    private static func nestedString(_ value: CDPJSONValue?) -> String? {
        if let string = value?["value"]?.stringValue { return string }
        if let number = value?["value"]?.doubleValue { return String(number) }
        if let bool = value?["value"]?.boolValue { return String(bool) }
        return nil
    }
}
