import Foundation

/// AppleScript execution functionality for SwiftAutoGUI.
///
/// This extension provides methods to execute AppleScript code, enabling control of macOS applications
/// and system features through Apple Events.
///
/// ## Important Configuration Requirements
///
/// To use AppleScript functionality in your macOS application, you must configure the following:
///
/// ### 1. Disable App Sandbox
/// In your app's `.entitlements` file:
/// ```xml
/// <key>com.apple.security.app-sandbox</key>
/// <false/>
/// ```
///
/// ### 2. Enable Automation Permission
/// In your app's `.entitlements` file:
/// ```xml
/// <key>com.apple.security.automation.apple-events</key>
/// <true/>
/// ```
///
/// ### 3. Add Usage Description
/// In your app's `Info.plist`:
/// ```xml
/// <key>NSAppleEventsUsageDescription</key>
/// <string>This app needs permission to control other applications.</string>
/// ```
///
/// ## Security Considerations
///
/// - Disabling the sandbox reduces your app's security isolation
/// - Users will be prompted to grant permission when your app first attempts to control another application
/// - The permission dialog will show the usage description from your Info.plist
///
/// ## Example Usage
///
/// ```swift
/// // Control Safari
/// let script = """
/// tell application "Safari"
///     activate
///     make new document
///     set URL of current tab of front window to "https://example.com"
/// end tell
/// """
/// try SwiftAutoGUI.executeAppleScript(script)
///
/// // Get system information
/// let systemVersion = """
/// tell application "System Events"
///     return system version of (system info)
/// end tell
/// """
/// if let version = try SwiftAutoGUI.executeAppleScript(systemVersion) {
///     print("macOS version: \(version)")
/// }
/// ```
extension SwiftAutoGUI {
    
    /// Executes an AppleScript string and returns the result.
    ///
    /// This method executes the provided AppleScript code synchronously and returns
    /// the script's output as a string. Useful for automating macOS applications
    /// and system features that expose AppleScript interfaces.
    ///
    /// - Parameter script: The AppleScript code to execute
    /// - Returns: The script's output as a string, or nil if the script produces no output
    /// - Throws: An error if the script fails to compile or execute
    ///
    /// ## Example
    /// ```swift
    /// // Get current Safari URL
    /// let script = """
    ///     tell application "Safari"
    ///         return URL of current tab of front window
    ///     end tell
    /// """
    /// if let url = try SwiftAutoGUI.executeAppleScript(script) {
    ///     print("Current URL: \(url)")
    /// }
    ///
    /// // Control system volume
    /// try SwiftAutoGUI.executeAppleScript("set volume output volume 50")
    /// ```
    public static func executeAppleScript(_ script: String) throws -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            throw AppleScriptError.compilationFailed("Failed to create NSAppleScript instance")
        }
        
        var compileErrorInfo: NSDictionary?
        if !appleScript.compileAndReturnError(&compileErrorInfo) {
            if let error = compileErrorInfo {
                throw AppleScriptError.compilationFailed(parseAppleScriptError(error))
            }
            throw AppleScriptError.compilationFailed("Unknown compilation error")
        }
        
        var executeErrorInfo: NSDictionary?
        let eventDescriptor = appleScript.executeAndReturnError(&executeErrorInfo)
        
        if let error = executeErrorInfo {
            throw AppleScriptError.executionFailed(parseAppleScriptError(error))
        }
        
        // Return nil if the script returns nothing
        if eventDescriptor.descriptorType == typeNull {
            return nil
        }
        
        // Handle list results
        if eventDescriptor.descriptorType == typeAEList {
            var items: [String] = []
            for i in 1...eventDescriptor.numberOfItems {
                if let item = eventDescriptor.atIndex(i) {
                    if let stringValue = item.stringValue {
                        items.append(stringValue)
                    }
                }
            }
            return items.joined(separator: ", ")
        }
        
        return eventDescriptor.stringValue
    }
    
    /// Executes an AppleScript from a file.
    ///
    /// This method loads and executes an AppleScript from the specified file path.
    /// Useful for organizing complex scripts in separate files.
    ///
    /// - Parameter filePath: The absolute path to the AppleScript file (.scpt or .applescript)
    /// - Returns: The script's output as a string, or nil if the script produces no output
    /// - Throws: An error if the file cannot be read or the script fails to execute
    ///
    /// ## Example
    /// ```swift
    /// // Execute a script file
    /// let scriptPath = "/Users/username/Scripts/backup.applescript"
    /// try SwiftAutoGUI.executeAppleScriptFile(scriptPath)
    /// ```
    public static func executeAppleScriptFile(_ filePath: String) throws -> String? {
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw AppleScriptError.fileNotFound(filePath)
        }
        
        let scriptContent = try String(contentsOf: fileURL, encoding: .utf8)
        return try executeAppleScript(scriptContent)
    }
    
    /// Represents errors that can occur during AppleScript execution.
    public enum AppleScriptError: LocalizedError {
        case compilationFailed(String)
        case executionFailed(String)
        case fileNotFound(String)
        
        public var errorDescription: String? {
            switch self {
            case .compilationFailed(let details):
                return "AppleScript compilation failed: \(details)"
            case .executionFailed(let details):
                return "AppleScript execution failed: \(details)"
            case .fileNotFound(let path):
                return "AppleScript file not found: \(path)"
            }
        }
    }
    
    /// Parses AppleScript error dictionary into a readable error message
    private static func parseAppleScriptError(_ errorInfo: NSDictionary) -> String {
        var errorMessage = ""
        
        if let errorNumber = errorInfo[NSAppleScript.errorNumber] as? Int {
            errorMessage += "Error \(errorNumber): "
        }
        
        if let errorString = errorInfo[NSAppleScript.errorMessage] as? String {
            errorMessage += errorString
        }
        
        if let errorRange = errorInfo[NSAppleScript.errorRange] as? NSRange {
            errorMessage += " at position \(errorRange.location)"
        }
        
        return errorMessage.isEmpty ? "Unknown AppleScript error" : errorMessage
    }
}