import Foundation
import Testing
@testable import SwiftAutoGUIBrowser

@Suite("Browser security policy")
struct BrowserSecurityPolicyTests {
    @Test("loopback endpoints are allowed by default")
    func loopbackEndpoint() throws {
        let policy = BrowserSecurityPolicy()
        try policy.validateEndpoint(#require(URL(string: "http://127.0.0.1:9222")))
        try policy.validateWebSocket(#require(URL(string: "ws://localhost:9222/devtools/browser/1")))
    }

    @Test("remote debugging endpoints are rejected by default")
    func remoteEndpoint() throws {
        let policy = BrowserSecurityPolicy()
        #expect(throws: BrowserError.self) {
            try policy.validateEndpoint(#require(URL(string: "http://example.com:9222")))
        }
    }

    @Test("domain wildcards do not include the parent domain")
    func wildcardDomain() throws {
        let policy = BrowserSecurityPolicy(allowedDomains: ["example.com", "*.example.org"])
        let exact = try #require(URL(string: "https://example.com/path"))
        let subdomain = try #require(URL(string: "https://a.example.org/path"))
        let parent = try #require(URL(string: "https://example.org/path"))
        let suffixOnly = try #require(URL(string: "https://badexample.com/path"))
        #expect(policy.allowsNavigation(to: exact))
        #expect(policy.allowsNavigation(to: subdomain))
        #expect(!policy.allowsNavigation(to: parent))
        #expect(!policy.allowsNavigation(to: suffixOnly))
    }
}
