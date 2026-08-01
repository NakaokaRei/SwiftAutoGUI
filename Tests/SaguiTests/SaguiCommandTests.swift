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
        #expect(SaguiVersion.current == "0.25.0")
    }
}
