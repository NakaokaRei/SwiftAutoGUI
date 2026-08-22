import Testing
@testable import sagui

@Suite("sagui Command Tests")
struct SaguiCommandTests {
    @Test("Key aliases resolve to Mac keyboard keys")
    func keyAliases() {
        #expect(KeyNameResolver.resolve("return") == .returnKey)
        #expect(KeyNameResolver.resolve("backspace") == .delete)
        #expect(KeyNameResolver.resolve("enter") == .enter)
        #expect(KeyNameResolver.resolve("delete") == .delete)
    }

    @Test("Key list includes cases and aliases in sorted order")
    func keyList() {
        #expect(KeyNameResolver.names == KeyNameResolver.names.sorted())
        #expect(KeyNameResolver.names.contains("return"))
        #expect(KeyNameResolver.names.contains("backspace"))
        #expect(KeyNameResolver.names.contains("returnKey"))
        #expect(KeyNameResolver.names.contains("rightArrow"))
    }

    @Test("Mouse click accepts a complete coordinate pair")
    func clickCoordinates() throws {
        let click = try MouseCommand.Click.parse([
            "--x", "100", "--y", "200", "--right", "--double",
        ])
        #expect(click.x == 100)
        #expect(click.y == 200)
        #expect(click.right)
        #expect(click.double)
    }

    @Test("Mouse click rejects partial coordinates")
    func partialClickCoordinates() {
        #expect(throws: (any Error).self) {
            try MouseCommand.Click.parse(["--x", "100"])
        }
        #expect(throws: (any Error).self) {
            try MouseCommand.Click.parse(["--y", "200"])
        }
    }

    @Test("Root command exposes the current version")
    func version() {
        #expect(SaguiCLI.configuration.version == SaguiVersion.current)
        let components = SaguiVersion.current.split(separator: ".")
        #expect(components.count == 3)
        #expect(components.allSatisfy { Int($0) != nil })
    }

    @Test("Agent defaults to the current flagship model")
    func agentDefaultModel() throws {
        let command = try AgentCommand.parse(["Inspect the frontmost app"])
        #expect(command.model == "gpt-5.6-sol")
        #expect(command.reasoningEffort == nil)
        #expect(command.effectiveReasoningEffort == "low")
    }

    @Test("Agent accepts an explicit model override")
    func agentModelOverride() throws {
        let command = try AgentCommand.parse([
            "Inspect the frontmost app",
            "--model", "gpt-5.6-terra",
        ])
        #expect(command.model == "gpt-5.6-terra")
    }

    @Test(
        "Agent accepts every GPT-5.6 reasoning effort",
        arguments: AgentCommand.ReasoningEffort.allCases
    )
    func agentReasoningEffort(effort: AgentCommand.ReasoningEffort) throws {
        let command = try AgentCommand.parse([
            "Inspect the frontmost app",
            "--reasoning-effort", effort.rawValue,
        ])
        #expect(command.reasoningEffort == effort)
        #expect(command.effectiveReasoningEffort == effort.rawValue)
    }

    @Test("Agent rejects an unknown reasoning effort")
    func agentRejectsUnknownReasoningEffort() {
        #expect(throws: (any Error).self) {
            try AgentCommand.parse([
                "Inspect the frontmost app",
                "--reasoning-effort", "extreme",
            ])
        }
    }

    @Test(
        "Agent accepts every vision mode",
        arguments: AgentCommand.VisionMode.allCases
    )
    func agentVisionMode(mode: AgentCommand.VisionMode) throws {
        let command = try AgentCommand.parse([
            "Inspect the frontmost app",
            "--vision-mode", mode.rawValue,
        ])
        #expect(command.visionMode == mode)
    }

    @Test("Agent rejects an unknown vision mode")
    func agentRejectsUnknownVisionMode() {
        #expect(throws: (any Error).self) {
            try AgentCommand.parse([
                "Inspect the frontmost app",
                "--vision-mode", "sometimes",
            ])
        }
    }

    @Test("Browser Agent requires no implicit domains at parse time")
    func browserAgentDefaults() throws {
        let command = try BrowserAgentCommand.parse(["Open the Issues page"])
        #expect(command.endpoint == "http://127.0.0.1:9222")
        #expect(command.domains.isEmpty)
        #expect(command.visionMode == .automatic)
        #expect(!command.allowCrossOrigin)
    }

    @Test("Browser Agent accepts repeated domain entries and a tab ID")
    func browserAgentOptions() throws {
        let command = try BrowserAgentCommand.parse([
            "Open issue 118",
            "--domain", "github.com",
            "--domain", "*.github.com",
            "--tab-id", "target-123",
            "--allow-cross-origin",
        ])
        #expect(command.domains == ["github.com", "*.github.com"])
        #expect(command.tabID == "target-123")
        #expect(command.allowCrossOrigin)
    }

    @Test("Browser tabs defaults to the loopback endpoint")
    func browserTabsDefaults() throws {
        let command = try BrowserTabsCommand.parse([])
        #expect(command.endpoint == "http://127.0.0.1:9222")
    }

    @Test("Browser observe requires and accepts a tab ID")
    func browserObserveOptions() throws {
        let command = try BrowserObserveCommand.parse([
            "--tab-id", "target-123",
            "--screenshot", "/tmp/page.jpg",
        ])
        #expect(command.target.tabID == "target-123")
        #expect(command.target.connection.endpoint == "http://127.0.0.1:9222")
        #expect(command.screenshot == "/tmp/page.jpg")
    }

    @Test("Browser open accepts a narrow navigation policy")
    func browserOpenOptions() throws {
        let command = try BrowserOpenCommand.parse([
            "https://github.com/NakaokaRei/SwiftAutoGUI",
            "--tab-id", "target-123",
            "--domain", "github.com",
            "--domain", "*.github.com",
            "--allow-cross-origin",
        ])
        #expect(command.target.tabID == "target-123")
        #expect(command.target.connection.domains == ["github.com", "*.github.com"])
        #expect(command.target.connection.allowCrossOrigin)
    }

    @Test("Browser click accepts semantic selectors with optional disambiguation")
    func browserClickOptions() throws {
        let semantic = try BrowserClickCommand.parse([
            "--tab-id", "target-123",
            "--role", "button",
            "--name", "Save",
        ])
        #expect(semantic.selector.elementID == nil)
        #expect(semantic.selector.role == "button")
        #expect(semantic.selector.name == "Save")

        let disambiguated = try BrowserClickCommand.parse([
            "--tab-id", "target-123",
            "--role", "button",
            "--name", "Save",
            "--element-id", "4",
        ])
        #expect(disambiguated.selector.elementID == 4)
    }

    @Test("Browser click rejects incomplete and invalid selectors")
    func browserClickRejectsInvalidSelector() {
        #expect(throws: (any Error).self) {
            try BrowserClickCommand.parse([
                "--tab-id", "target-123",
                "--role", "button",
            ])
        }
        #expect(throws: (any Error).self) {
            try BrowserClickCommand.parse([
                "--tab-id", "target-123",
                "--role", "button",
                "--name", "Save",
                "--element-id", "0",
            ])
        }
    }

    @Test("Browser key and scroll commands parse deterministic actions")
    func browserInputOptions() throws {
        let key = try BrowserKeyCommand.parse([
            "command", "a",
            "--tab-id", "target-123",
        ])
        #expect(key.keys == ["command", "a"])

        let scroll = try BrowserScrollCommand.parse([
            "--vertical", "-5",
            "--horizontal", "2",
            "--tab-id", "target-123",
        ])
        #expect(scroll.vertical == -5)
        #expect(scroll.horizontal == 2)
    }

    @Test("Browser scroll rejects an empty movement")
    func browserScrollRejectsEmptyMovement() {
        #expect(throws: (any Error).self) {
            try BrowserScrollCommand.parse(["--tab-id", "target-123"])
        }
    }
}
