import Foundation
import SwiftAutoGUI
import Testing
@testable import SwiftAutoGUIBrowser

@Suite("Browser session")
struct BrowserSessionTests {
    @Test("observes numbered semantic elements through CDP")
    func observesElements() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(transport: transport)
        try await session.start()

        let observation = try await session.observe(visionMode: .never)
        #expect(observation.kind == .browser)
        #expect(observation.actionableElementCount == 1)
        #expect(observation.formattedContext.contains("[#1] button \"Submit\""))
        #expect(await transport.didSend("Accessibility.getFullAXTree"))
        #expect(await transport.didSend("DOM.getBoxModel"))
    }

    @Test("native-only actions fail without AX or CGEvent fallback")
    func rejectsNativeAction() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(transport: transport)
        try await session.start()
        let observation = try await session.observe(visionMode: .never)

        let execution = await session.execute(.activateApp(name: "Notes"), in: observation)
        #expect(!execution.result.succeeded)
        #expect(execution.result.method == .none)
        #expect(execution.result.failureReason?.contains("does not support") == true)
        #expect(!(await transport.didSend("Input.dispatchMouseEvent")))
    }

    @Test("stale elements never fall back to a saved coordinate")
    func staleElement() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(transport: transport)
        try await session.start()
        let observation = try await session.observe(visionMode: .never)
        await transport.setLoaderID("loader-2")

        let execution = await session.execute(.pressElement(elementID: 1), in: observation)
        #expect(!execution.result.succeeded)
        #expect(execution.result.method == .cdp)
        #expect(execution.result.failureReason?.contains("stale") == true)
        #expect(!(await transport.didSend("Input.dispatchMouseEvent")))
    }

    @Test("semantic click dispatches CDP mouse events")
    func clicksElement() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(transport: transport)
        try await session.start()
        let observation = try await session.observe(visionMode: .never)

        let execution = await session.execute(.pressElement(elementID: 1), in: observation)
        #expect(execution.result.succeeded)
        #expect(execution.result.method == .cdp)
        #expect(await transport.count("Input.dispatchMouseEvent") == 3)
    }

    @Test("cross-origin navigation is denied without an authorizer")
    func deniesCrossOriginNavigation() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(
            transport: transport,
            policy: BrowserSecurityPolicy(allowedDomains: ["example.com", "other.example"])
        )
        try await session.start()
        let observation = try await session.observe(visionMode: .never)

        let execution = await session.execute(.openURL(url: "https://other.example/path"), in: observation)
        #expect(!execution.result.succeeded)
        #expect(execution.result.failureReason?.contains("not authorized") == true)
        #expect(!(await transport.didSend("Page.navigate")))
    }

    @Test("an authorizer can approve allowlisted cross-origin navigation")
    func authorizesCrossOriginNavigation() async throws {
        let transport = MockCDPTransport()
        let session = makeSession(
            transport: transport,
            policy: BrowserSecurityPolicy(allowedDomains: ["example.com", "other.example"]),
            authorizer: AllowingAuthorizer()
        )
        try await session.start()
        let observation = try await session.observe(visionMode: .never)

        let execution = await session.execute(.openURL(url: "https://other.example/path"), in: observation)
        #expect(execution.result.succeeded)
        #expect(await transport.didSend("Page.navigate"))
    }

    private func makeSession(
        transport: MockCDPTransport,
        policy: BrowserSecurityPolicy = BrowserSecurityPolicy(allowedDomains: ["example.com"]),
        authorizer: (any BrowserActionAuthorizing)? = nil
    ) -> BrowserSession {
        BrowserSession(
            transport: transport,
            securityPolicy: policy,
            authorizer: authorizer,
            options: .init(maxElements: 20, actionObservationDelay: .zero)
        )
    }
}

private struct AllowingAuthorizer: BrowserActionAuthorizing {
    func authorize(_ request: BrowserAuthorizationRequest) async -> Bool { true }
}

private actor MockCDPTransport: CDPTransporting {
    private var methods: [String] = []
    private var loaderID = "loader-1"

    func connect() async throws {}

    func send(method: String, params: CDPJSONValue, sessionID: String?) async throws -> CDPJSONValue {
        methods.append(method)
        switch method {
        case "Browser.getVersion":
            return .object(["protocolVersion": .string("1.3"), "product": .string("Chrome/140")])
        case "Target.getTargets":
            return .object([
                "targetInfos": .array([
                    .object([
                        "targetId": .string("tab-1"),
                        "type": .string("page"),
                        "url": .string("https://example.com"),
                        "title": .string("Example")
                    ])
                ])
            ])
        case "Target.attachToTarget":
            return .object(["sessionId": .string("session-1")])
        case "Page.getFrameTree":
            return .object([
                "frameTree": .object([
                    "frame": .object([
                        "id": .string("frame-1"),
                        "loaderId": .string(loaderID),
                        "url": .string("https://example.com")
                    ])
                ])
            ])
        case "Accessibility.getFullAXTree", "Accessibility.getPartialAXTree":
            return .object(["nodes": .array([buttonNode])])
        case "DOM.getBoxModel":
            return boxModel
        case "DOM.describeNode":
            return .object(["node": .object(["attributes": .array([])])])
        case "Page.getLayoutMetrics":
            return .object([
                "cssVisualViewport": .object([
                    "clientWidth": .number(1024),
                    "clientHeight": .number(768)
                ])
            ])
        default:
            return .object([:])
        }
    }

    func events() async -> AsyncStream<CDPEvent> { AsyncStream { _ in } }
    func close() async {}

    func setLoaderID(_ value: String) { loaderID = value }
    func didSend(_ method: String) -> Bool { methods.contains(method) }
    func count(_ method: String) -> Int { methods.filter { $0 == method }.count }

    private var buttonNode: CDPJSONValue {
        .object([
            "ignored": .bool(false),
            "backendDOMNodeId": .number(42),
            "frameId": .string("frame-1"),
            "role": .object(["type": .string("role"), "value": .string("button")]),
            "name": .object(["type": .string("computedString"), "value": .string("Submit")]),
            "properties": .array([])
        ])
    }

    private var boxModel: CDPJSONValue {
        .object([
            "model": .object([
                "border": .array([10, 20, 90, 20, 90, 50, 10, 50].map { .number(Double($0)) })
            ])
        ])
    }
}
