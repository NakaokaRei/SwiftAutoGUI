import Testing
import Foundation
@testable import SwiftAutoGUI

@Suite("AppleScript Tests")
struct AppleScriptTests {
    
    @Test("Execute invalid AppleScript throws error")
    func testInvalidAppleScript() {
        // Invalid script
        let script = "this is not valid AppleScript"
        
        #expect(throws: SwiftAutoGUI.AppleScriptError.self) {
            _ = try SwiftAutoGUI.executeAppleScript(script)
        }
    }
    
    @Test("Execute AppleScript from non-existent file throws error")
    func testExecuteAppleScriptFileNotFound() {
        let nonExistentPath = "/tmp/non_existent_script.applescript"
        
        #expect(throws: SwiftAutoGUI.AppleScriptError.self) {
            _ = try SwiftAutoGUI.executeAppleScriptFile(nonExistentPath)
        }
    }
    
    @Test("AppleScriptError descriptions")
    func testAppleScriptErrorDescriptions() {
        let compilationError = SwiftAutoGUI.AppleScriptError.compilationFailed("Syntax error")
        #expect(compilationError.errorDescription == "AppleScript compilation failed: Syntax error")
        
        let executionError = SwiftAutoGUI.AppleScriptError.executionFailed("Runtime error")
        #expect(executionError.errorDescription == "AppleScript execution failed: Runtime error")
        
        let fileNotFoundError = SwiftAutoGUI.AppleScriptError.fileNotFound("/path/to/script")
        #expect(fileNotFoundError.errorDescription == "AppleScript file not found: /path/to/script")
    }
}
