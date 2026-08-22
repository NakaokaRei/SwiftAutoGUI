import Foundation
import Testing
@testable import SwiftAutoGUIBrowser

@Suite("Browser selector map")
struct BrowserSelectorMapTests {
    @Test("filters AX nodes and numbers visible actionable elements")
    func actionableElements() throws {
        let tree: CDPJSONValue = .object([
            "nodes": .array([
                axNode(backendID: 10, role: "button", name: "Submit"),
                axNode(backendID: 11, role: "StaticText", name: "Description"),
                axNode(backendID: 12, role: "textbox", name: "Email", editable: true),
                axNode(backendID: 13, role: "button", name: "Disabled", disabled: true)
            ])
        ])
        let candidates = BrowserSelectorMapBuilder.candidates(from: tree, limit: 20)
        #expect(candidates.map(\.backendDOMNodeID) == [10, 12, 13])

        let elements = BrowserSelectorMapBuilder.elements(
            candidates: candidates,
            bounds: [
                10: BrowserRect(x: 10, y: 20, width: 80, height: 30),
                12: BrowserRect(x: 20, y: 60, width: 200, height: 24),
                13: BrowserRect(x: 10, y: 90, width: 80, height: 30)
            ],
            destinationURLs: [10: "https://example.com/next"]
        )
        #expect(elements.count == 2)
        #expect(elements[0].elementID == 1)
        #expect(elements[0].name == "Submit")
        #expect(elements[1].elementID == 2)
        #expect(elements[1].isEditable)

        let tab = BrowserTab(id: "tab-1", url: "https://example.com", title: "Example", state: .active)
        let formatted = BrowserSelectorMapBuilder.format(tabs: [tab], activeTabID: tab.id, elements: elements)
        #expect(formatted.contains("[#1] button \"Submit\""))
        #expect(formatted.contains("[#2] textbox \"Email\""))
    }

    @Test("extracts bounds from a CDP box model")
    func boxBounds() throws {
        let result: CDPJSONValue = .object([
            "model": .object([
                "border": .array([10, 20, 90, 20, 90, 50, 10, 50].map { .number(Double($0)) })
            ])
        ])
        let bounds = try #require(BrowserSelectorMapBuilder.bounds(from: result))
        #expect(bounds == BrowserRect(x: 10, y: 20, width: 80, height: 30))
    }

    @Test("CDP JSON values tolerate nested and unknown data")
    func jsonRoundTrip() throws {
        let value: CDPJSONValue = .object([
            "known": .string("value"),
            "futureField": .array([.bool(true), .number(2), .null])
        ])
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(CDPJSONValue.self, from: data) == value)
    }

    private func axNode(
        backendID: Int,
        role: String,
        name: String,
        editable: Bool = false,
        disabled: Bool = false
    ) -> CDPJSONValue {
        var properties: [CDPJSONValue] = []
        if editable { properties.append(property("editable", .bool(true))) }
        if disabled { properties.append(property("disabled", .bool(true))) }
        return .object([
            "ignored": .bool(false),
            "backendDOMNodeId": .number(Double(backendID)),
            "frameId": .string("frame-1"),
            "role": axValue(.string(role)),
            "name": axValue(.string(name)),
            "properties": .array(properties)
        ])
    }

    private func property(_ name: String, _ value: CDPJSONValue) -> CDPJSONValue {
        .object(["name": .string(name), "value": axValue(value)])
    }

    private func axValue(_ value: CDPJSONValue) -> CDPJSONValue {
        .object(["type": .string("string"), "value": value])
    }
}
