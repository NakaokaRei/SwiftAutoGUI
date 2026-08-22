import Foundation
import Testing
@testable import SwiftAutoGUIBrowser

@Suite("Browser integration")
struct BrowserIntegrationTests {
    @Test("connects to an explicitly enabled Chromium endpoint")
    func optInConnection() async throws {
        guard ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_CDP_TESTS"] == "1" else { return }
        let endpointValue = ProcessInfo.processInfo.environment["SWIFTAUTOGUI_CDP_ENDPOINT"]
            ?? "http://127.0.0.1:9222"
        let domain = ProcessInfo.processInfo.environment["SWIFTAUTOGUI_CDP_DOMAIN"] ?? "example.com"
        let endpoint = try #require(URL(string: endpointValue))
        let browser = try await BrowserSession.connect(
            endpoint: endpoint,
            securityPolicy: BrowserSecurityPolicy(allowedDomains: [domain])
        )
        let tabs = try await browser.listTabs()
        #expect(!tabs.isEmpty)
        let observation = try await browser.observe()
        #expect(!observation.tab.id.isEmpty)
        await browser.close()
    }
}
