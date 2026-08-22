import Foundation
import Testing
@testable import SwiftAutoGUIBrowser

@Suite("Browser integration", .serialized)
struct BrowserIntegrationTests {
    @Test("drives a local page through a real Chromium endpoint")
    func localPageWorkflow() async throws {
        guard ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_CDP_TESTS"] == "1" else { return }
        let endpointValue = ProcessInfo.processInfo.environment["SWIFTAUTOGUI_CDP_ENDPOINT"]
            ?? "http://127.0.0.1:9222"
        let pageValue = ProcessInfo.processInfo.environment["SWIFTAUTOGUI_CDP_PAGE_URL"]
            ?? "http://127.0.0.1:8765/index.html"
        let endpoint = try #require(URL(string: endpointValue))
        let pageURL = try #require(URL(string: pageValue))
        let domain = try #require(pageURL.host)
        let browser = try await BrowserSession.connect(
            endpoint: endpoint,
            securityPolicy: BrowserSecurityPolicy(allowedDomains: [domain])
        )

        do {
            let initial = try await browser.observe()
            #expect(initial.tab.url == pageURL.absoluteString)
            let originalTabID = initial.tab.id

            let textbox = try #require(initial.elements.first {
                $0.role.lowercased() == "textbox" && $0.name == "Name"
            })
            let typed = await browser.execute(
                .replaceText(elementID: textbox.elementID, value: "SwiftAutoGUI CI"),
                against: initial
            )
            #expect(typed.succeeded)
            #expect(typed.observation.elements.contains {
                $0.role.lowercased() == "textbox" && $0.value == "SwiftAutoGUI CI"
            })

            let submit = try #require(typed.observation.elements.first { $0.name == "Submit" })
            let clicked = await browser.execute(.click(elementID: submit.elementID), against: typed.observation)
            #expect(clicked.succeeded)
            #expect(clicked.observation.stateFingerprint != typed.observation.stateFingerprint)
            #expect(clicked.observation.elements.contains { $0.name == "Submitted" })

            let screenshot = try await browser.observe(includeScreenshot: true)
            #expect((screenshot.screenshotJPEGData?.count ?? 0) > 100)

            let tabLink = try #require(screenshot.elements.first { $0.name == "Open second tab" })
            let opened = await browser.execute(.click(elementID: tabLink.elementID), against: screenshot)
            #expect(opened.succeeded)
            let secondTab = try await waitForTab(otherThan: originalTabID, in: browser)
            try await browser.activateTab(secondTab.id)
            let secondTabObservation = try await browser.observe()
            #expect(secondTabObservation.tab.id == secondTab.id)
            #expect(secondTabObservation.tab.url.hasSuffix("/second.html"))

            try await browser.activateTab(originalTabID)
            let beforeNavigation = try await browser.observe()
            let allowedURL = try #require(URL(string: "/next.html", relativeTo: pageURL)?.absoluteURL)
            let allowed = await browser.execute(.navigate(allowedURL), against: beforeNavigation)
            #expect(allowed.succeeded)
            #expect(allowed.observation.tab.url == allowedURL.absoluteString)

            let blockedURL = try #require(URL(string: "https://blocked.invalid/"))
            let blocked = await browser.execute(.navigate(blockedURL), against: allowed.observation)
            #expect(!blocked.succeeded)
            #expect(blocked.failure == .navigationNotAllowed(blockedURL.absoluteString))

            await browser.close()
        } catch {
            await browser.close()
            throw error
        }
    }

    private func waitForTab(
        otherThan tabID: String,
        in browser: BrowserSession
    ) async throws -> BrowserTab {
        for _ in 0..<30 {
            if let tab = try await browser.listTabs().first(where: { $0.id != tabID }) {
                return tab
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw BrowserError.noPageTabs
    }
}
