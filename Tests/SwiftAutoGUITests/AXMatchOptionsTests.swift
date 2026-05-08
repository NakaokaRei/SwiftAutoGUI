import Testing
@testable import SwiftAutoGUI

@Suite("AX Matching")
struct AXMatchOptionsTests {

    // MARK: - AXStringMatch.exact

    @Test("Exact match requires equality")
    func exactRequiresEquality() {
        let match: AXStringMatch = .exact("Save")
        #expect(match.matches("Save"))
        #expect(!match.matches("save"))
        #expect(!match.matches("Save…"))
        #expect(!match.matches("Save (⌘S)"))
        #expect(!match.matches(nil))
    }

    // MARK: - AXStringMatch.containsCaseInsensitive

    @Test("Contains is case-insensitive and tolerates real-world labels")
    func containsHandlesRealLabels() {
        let match: AXStringMatch = .containsCaseInsensitive("save")
        #expect(match.matches("Save"))
        #expect(match.matches("Save…"))
        #expect(match.matches("Save (⌘S)"))
        #expect(match.matches("Autosave Document"))
        #expect(!match.matches("Open"))
        #expect(!match.matches(nil))
    }

    @Test("Contains with empty query matches every non-nil string")
    func containsEmptyQueryMatchesAll() {
        let match: AXStringMatch = .containsCaseInsensitive("")
        #expect(match.matches(""))
        #expect(match.matches("anything"))
        #expect(!match.matches(nil))
    }

    // MARK: - AXStringMatch.regex

    @Test("Regex anchors and patterns work")
    func regexPatterns() {
        let saveOnly: AXStringMatch = .regex("^Save")
        #expect(saveOnly.matches("Save"))
        #expect(saveOnly.matches("Save…"))
        #expect(!saveOnly.matches("Autosave"))

        let digits: AXStringMatch = .regex("^[0-9]+$")
        #expect(digits.matches("42"))
        #expect(!digits.matches("4 + 2"))
    }

    @Test("Regex is case-insensitive")
    func regexIsCaseInsensitive() {
        let match: AXStringMatch = .regex("save")
        #expect(match.matches("SAVE"))
        #expect(match.matches("Saved Document"))
    }

    @Test("Malformed regex never matches")
    func malformedRegexDoesNotMatch() {
        let match: AXStringMatch = .regex("(unclosed")
        #expect(!match.matches("anything"))
        #expect(!match.matches("(unclosed"))
    }

    @Test("Regex against nil never matches")
    func regexAgainstNil() {
        let match: AXStringMatch = .regex(".*")
        #expect(!match.matches(nil))
    }

    // MARK: - AXMatchOptions.label convenience

    @Test("AXMatchOptions.label defaults to contains, exact: true upgrades to exact")
    func labelConvenience() {
        let lenient = AXMatchOptions.label("Save")
        guard case .containsCaseInsensitive(let q1) = lenient.labelMatch else {
            Issue.record("expected containsCaseInsensitive, got \(String(describing: lenient.labelMatch))")
            return
        }
        #expect(q1 == "Save")
        #expect(lenient.requireEnabled == true)

        let strict = AXMatchOptions.label("Save", exact: true)
        guard case .exact(let q2) = strict.labelMatch else {
            Issue.record("expected exact, got \(String(describing: strict.labelMatch))")
            return
        }
        #expect(q2 == "Save")
    }
}
