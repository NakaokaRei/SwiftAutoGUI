import AppKit
import Foundation

/// Native macOS application-control helpers.
///
/// These operations use Launch Services and `NSRunningApplication` instead of
/// AppleScript, so structured AI parameters are never interpolated into code.
extension SwiftAutoGUI {

    /// Opens a URL in its default application.
    @MainActor
    @discardableResult
    public static func openURL(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    /// Launches an application if needed and brings all of its windows forward.
    @MainActor
    @discardableResult
    public static func activateApp(named name: String) async -> Bool {
        if let application = runningApplication(named: name) {
            return application.activate(options: [.activateAllWindows])
        }

        guard let applicationURL = applicationURL(named: name) else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(
                at: applicationURL,
                configuration: configuration
            ) { application, _ in
                guard let application else {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(
                    returning: application.activate(options: [.activateAllWindows])
                )
            }
        }
    }

    /// Gracefully terminates a running application.
    @MainActor
    @discardableResult
    public static func quitApp(named name: String) -> Bool {
        runningApplication(named: name)?.terminate() ?? false
    }

    /// Returns the localized name of the frontmost application.
    @MainActor
    public static func frontmostAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    @MainActor
    private static func runningApplication(named name: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { application in
            application.localizedName?.caseInsensitiveCompare(name) == .orderedSame ||
                application.bundleIdentifier?.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    @MainActor
    private static func applicationURL(named name: String) -> URL? {
        if name.contains("."),
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name) {
            return url
        }

        let applicationName = name.hasSuffix(".app") ? name : "\(name).app"
        let searchDirectories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
        ]

        for directory in searchDirectories {
            let candidate = directory.appendingPathComponent(
                applicationName,
                isDirectory: true
            )
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
